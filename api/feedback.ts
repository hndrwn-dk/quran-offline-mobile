import type { VercelRequest, VercelResponse } from '@vercel/node';
import { isBrowserOrigin, neutralizeGithubMentions } from '../server/feedback_guard.js';
import {
  decodePlayIntegrityToken,
  evaluatePlayIntegrityVerdict,
} from '../server/play_integrity.js';

type FeedbackType = 'bug' | 'feature';

interface FeedbackMetadata {
  appVersion?: string;
  dataVersion?: string;
  language?: string;
  surahId?: number;
  ayahNo?: number;
  arabicSnippet?: string;
}

interface FeedbackBody {
  type?: FeedbackType;
  title?: string;
  description?: string;
  metadata?: FeedbackMetadata;
  integrityToken?: string;
  nonce?: string;
}

interface RateLimitEntry {
  count: number;
  resetAt: number;
}

const RATE_LIMIT_WINDOW_SEC = 60 * 60;
const RATE_LIMIT_MAX = 5;
const rateLimitStore = new Map<string, RateLimitEntry>();

const usedNonces = new Set<string>();

async function consumeNonce(nonce: string): Promise<boolean> {
  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) {
    if (usedNonces.has(nonce)) return false;
    usedNonces.add(nonce);
    return true;
  }

  try {
    const response = await fetch(`${url}/pipeline`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify([['SET', `feedback:nonce:${nonce}`, '1', 'NX', 'EX', '300']]),
    });
    if (!response.ok) return false;
    const json: unknown = await response.json();
    return pipelineSetNxStored(json);
  } catch {
    return false;
  }
}

function clientIp(req: VercelRequest): string {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded.split(',')[0]?.trim() ?? 'unknown';
  }
  if (Array.isArray(forwarded) && forwarded.length > 0) {
    return forwarded[0]?.split(',')[0]?.trim() ?? 'unknown';
  }
  return req.socket.remoteAddress ?? 'unknown';
}

function isRateLimitedMemory(ip: string): boolean {
  const now = Date.now();
  const windowMs = RATE_LIMIT_WINDOW_SEC * 1000;
  const entry = rateLimitStore.get(ip);
  if (!entry || now >= entry.resetAt) {
    rateLimitStore.set(ip, { count: 1, resetAt: now + windowMs });
    return false;
  }
  if (entry.count >= RATE_LIMIT_MAX) {
    return true;
  }
  entry.count += 1;
  return false;
}

async function isRateLimited(ip: string): Promise<boolean> {
  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) {
    return isRateLimitedMemory(ip);
  }

  const key = `feedback:${ip}`;
  try {
    const response = await fetch(`${url}/pipeline`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify([
        ['INCR', key],
        ['EXPIRE', key, RATE_LIMIT_WINDOW_SEC, 'NX'],
      ]),
    });
    if (!response.ok) {
      return true;
    }
    const json: unknown = await response.json();
    const count = pipelineFirstCount(json);
    if (typeof count !== 'number') {
      return true;
    }
    return count > RATE_LIMIT_MAX;
  } catch {
    return true;
  }
}

function firstPipelineResult(json: unknown): unknown {
  if (Array.isArray(json)) {
    const first = json[0];
    if (first != null && typeof first === 'object' && 'result' in first) {
      return (first as { result: unknown }).result;
    }
    return first;
  }
  if (json != null && typeof json === 'object' && 'result' in json) {
    const result = (json as { result: unknown }).result;
    if (Array.isArray(result)) {
      const inner = result[0];
      if (inner != null && typeof inner === 'object' && 'result' in inner) {
        return (inner as { result: unknown }).result;
      }
      return inner;
    }
    return result;
  }
  return null;
}

function pipelineFirstCount(json: unknown): number | null {
  const first = firstPipelineResult(json);
  return typeof first === 'number' ? first : null;
}

function pipelineSetNxStored(json: unknown): boolean {
  const first = firstPipelineResult(json);
  return first === 'OK' || first === 1 || first === true;
}

function trimText(value: unknown, maxLen: number): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (trimmed.length === 0 || trimmed.length > maxLen) return null;
  return trimmed;
}

function parseMetadata(raw: unknown): FeedbackMetadata | null {
  if (raw == null || typeof raw !== 'object') return {};
  const m = raw as Record<string, unknown>;
  const metadata: FeedbackMetadata = {};

  const appVersion = trimText(m.appVersion, 64);
  if (appVersion) metadata.appVersion = appVersion;

  const dataVersion = trimText(m.dataVersion, 64);
  if (dataVersion) metadata.dataVersion = dataVersion;

  const language = trimText(m.language, 8);
  if (language) metadata.language = language;

  if (typeof m.surahId === 'number' && Number.isInteger(m.surahId) && m.surahId > 0) {
    metadata.surahId = m.surahId;
  }
  if (typeof m.ayahNo === 'number' && Number.isInteger(m.ayahNo) && m.ayahNo > 0) {
    metadata.ayahNo = m.ayahNo;
  }

  const arabicSnippet = trimText(m.arabicSnippet, 2000);
  if (arabicSnippet) metadata.arabicSnippet = arabicSnippet;

  return metadata;
}

function labelForType(type: FeedbackType): string {
  return type === 'feature' ? 'new feature' : 'bug';
}

function quranComUrl(surahId: number, ayahNo: number): string {
  return `https://quran.com/${surahId}/${ayahNo}`;
}

function buildIssueBody(
  description: string,
  metadata: FeedbackMetadata,
): string {
  const lines: string[] = [description, '', '---', '**Submitted via Quran Offline app**', ''];

  if (metadata.appVersion) {
    lines.push(`- App: ${metadata.appVersion}`);
  }
  if (metadata.dataVersion) {
    lines.push(`- Data: ${metadata.dataVersion}`);
  }
  if (metadata.language) {
    lines.push(`- Language: ${metadata.language}`);
  }
  if (metadata.surahId != null && metadata.ayahNo != null) {
    lines.push(`- Verse: QS ${metadata.surahId}:${metadata.ayahNo}`);
    lines.push(`- quran.com: ${quranComUrl(metadata.surahId, metadata.ayahNo)}`);
  }
  if (metadata.arabicSnippet) {
    lines.push(
      '',
      '**Arabic text (in app):**',
      '```',
      neutralizeGithubMentions(metadata.arabicSnippet),
      '```',
    );
  }

  return lines.join('\n');
}

function parseBody(req: VercelRequest): FeedbackBody | null {
  if (req.body == null) return null;
  if (typeof req.body === 'string') {
    try {
      return JSON.parse(req.body) as FeedbackBody;
    } catch {
      return null;
    }
  }
  if (typeof req.body === 'object') {
    return req.body as FeedbackBody;
  }
  return null;
}

export default async function handler(
  req: VercelRequest,
  res: VercelResponse,
): Promise<void> {
  if (req.method === 'OPTIONS') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  if (isBrowserOrigin(req.headers.origin)) {
    res.status(403).json({ error: 'Forbidden' });
    return;
  }

  const body = parseBody(req);
  if (!body) {
    res.status(400).json({ error: 'Invalid JSON body' });
    return;
  }

  const integrityToken = trimText(body.integrityToken, 65536);
  const nonce = trimText(body.nonce, 512);
  if (!integrityToken || !nonce) {
    res.status(401).json({ error: 'Play Integrity required' });
    return;
  }

  if (!process.env.PLAY_INTEGRITY_SERVICE_ACCOUNT_JSON) {
    res.status(503).json({ error: 'Play Integrity not configured' });
    return;
  }

  const token = process.env.GITHUB_TOKEN;
  const repo = process.env.GITHUB_REPO ?? 'hndrwn-dk/quran-offline-mobile';

  if (!token) {
    res.status(500).json({ error: 'Server misconfigured' });
    return;
  }

  const ip = clientIp(req);
  if (await isRateLimited(ip)) {
    res.status(429).json({ error: 'Too many requests. Try again later.' });
    return;
  }

  const payload = await decodePlayIntegrityToken(integrityToken);
  if (payload == null) {
    res.status(401).json({ error: 'Invalid Play Integrity token' });
    return;
  }

  const verdict = evaluatePlayIntegrityVerdict({
    payload,
    expectedNonce: nonce,
    nowMs: Date.now(),
  });
  if (verdict !== 'ok') {
    res.status(403).json({ error: 'Play Integrity rejected', reason: verdict });
    return;
  }

  if (!(await consumeNonce(nonce))) {
    res.status(401).json({ error: 'Replay rejected' });
    return;
  }

  const type = body.type;
  if (type !== 'bug' && type !== 'feature') {
    res.status(400).json({ error: 'type must be bug or feature' });
    return;
  }

  const title = neutralizeGithubMentions(trimText(body.title, 120) ?? '');
  const description = neutralizeGithubMentions(
    trimText(body.description, 8000) ?? '',
  );
  if (!title) {
    res.status(400).json({ error: 'title is required (max 120 chars)' });
    return;
  }
  if (!description) {
    res.status(400).json({ error: 'description is required (max 8000 chars)' });
    return;
  }

  const metadata = parseMetadata(body.metadata) ?? {};
  const issueBody = buildIssueBody(description, metadata);
  const label = labelForType(type);

  const ghResponse = await fetch(`https://api.github.com/repos/${repo}/issues`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'Content-Type': 'application/json',
      'User-Agent': 'quran-offline-feedback-api',
      'X-GitHub-Api-Version': '2022-11-28',
    },
    body: JSON.stringify({
      title,
      body: issueBody,
      labels: [label],
    }),
  });

  if (!ghResponse.ok) {
    const detail = await ghResponse.text();
    console.error('GitHub API error', ghResponse.status, detail);
    res.status(502).json({ error: 'Failed to create issue' });
    return;
  }

  const issue = (await ghResponse.json()) as {
    html_url?: string;
    number?: number;
  };

  res.status(201).json({
    issueUrl: issue.html_url,
    issueNumber: issue.number,
  });
}
