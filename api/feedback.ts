import type { VercelRequest, VercelResponse } from '@vercel/node';

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
}

interface RateLimitEntry {
  count: number;
  resetAt: number;
}

const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000;
const RATE_LIMIT_MAX = 5;
const rateLimitStore = new Map<string, RateLimitEntry>();

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

function isRateLimited(ip: string): boolean {
  const now = Date.now();
  const entry = rateLimitStore.get(ip);
  if (!entry || now >= entry.resetAt) {
    rateLimitStore.set(ip, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS });
    return false;
  }
  if (entry.count >= RATE_LIMIT_MAX) {
    return true;
  }
  entry.count += 1;
  return false;
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
    lines.push('', '**Arabic text (in app):**', '```', metadata.arabicSnippet, '```');
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
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const token = process.env.GITHUB_TOKEN;
  const repo = process.env.GITHUB_REPO ?? 'hndrwn-dk/quran-offline-mobile';

  if (!token) {
    res.status(500).json({ error: 'Server misconfigured' });
    return;
  }

  const ip = clientIp(req);
  if (isRateLimited(ip)) {
    res.status(429).json({ error: 'Too many requests. Try again later.' });
    return;
  }

  const body = parseBody(req);
  if (!body) {
    res.status(400).json({ error: 'Invalid JSON body' });
    return;
  }

  const type = body.type;
  if (type !== 'bug' && type !== 'feature') {
    res.status(400).json({ error: 'type must be bug or feature' });
    return;
  }

  const title = trimText(body.title, 120);
  const description = trimText(body.description, 8000);
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
