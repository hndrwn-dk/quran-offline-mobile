import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createSign } from 'node:crypto';

interface ServiceAccount {
  client_email: string;
  private_key: string;
}

function base64Url(input: Buffer | string): string {
  const buf = typeof input === 'string' ? Buffer.from(input) : input;
  return buf
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/g, '');
}

function parseServiceAccount(): ServiceAccount | null {
  const raw = process.env.PLAY_INTEGRITY_SERVICE_ACCOUNT_JSON;
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as ServiceAccount;
    if (!parsed.client_email || !parsed.private_key) return null;
    return parsed;
  } catch {
    return null;
  }
}

async function googleAccessToken(account: ServiceAccount): Promise<number> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = base64Url(
    JSON.stringify({
      iss: account.client_email,
      scope: 'https://www.googleapis.com/auth/playintegrity',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  );
  const unsigned = `${header}.${claim}`;
  const signer = createSign('RSA-SHA256');
  signer.update(unsigned);
  const jwt = `${unsigned}.${base64Url(signer.sign(account.private_key))}`;

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  return response.status;
}

export default async function handler(
  req: VercelRequest,
  res: VercelResponse,
): Promise<void> {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const sa = parseServiceAccount();
  let playIntegrityOAuth: number | null = null;
  let playIntegrityDecodeFake: number | null = null;
  if (sa) {
    playIntegrityOAuth = await googleAccessToken(sa);
    if (playIntegrityOAuth === 200) {
      const now = Math.floor(Date.now() / 1000);
      const header = base64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
      const claim = base64Url(
        JSON.stringify({
          iss: sa.client_email,
          scope: 'https://www.googleapis.com/auth/playintegrity',
          aud: 'https://oauth2.googleapis.com/token',
          iat: now,
          exp: now + 3600,
        }),
      );
      const unsigned = `${header}.${claim}`;
      const signer = createSign('RSA-SHA256');
      signer.update(unsigned);
      const jwt = `${unsigned}.${base64Url(signer.sign(sa.private_key))}`;
      const tokRes = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          assertion: jwt,
        }),
      });
      if (tokRes.ok) {
        const access = ((await tokRes.json()) as { access_token?: string })
          .access_token;
        if (access) {
          const decRes = await fetch(
            'https://playintegrity.googleapis.com/v1/com.tursinalabs.quranoffline:decodeIntegrityToken',
            {
              method: 'POST',
              headers: {
                Authorization: `Bearer ${access}`,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({ integrityToken: 'fake-probe' }),
            },
          );
          playIntegrityDecodeFake = decRes.status;
        }
      }
    }
  }

  const githubToken = process.env.GITHUB_TOKEN;
  let githubRepo: number | null = null;
  if (githubToken) {
    const repo = process.env.GITHUB_REPO ?? 'hndrwn-dk/quran-offline-mobile';
    const ghRes = await fetch(`https://api.github.com/repos/${repo}`, {
      headers: {
        Authorization: `Bearer ${githubToken}`,
        Accept: 'application/vnd.github+json',
        'User-Agent': 'quran-offline-health',
      },
    });
    githubRepo = ghRes.status;
  }

  const upstashUrl = process.env.UPSTASH_REDIS_REST_URL;
  const upstashToken = process.env.UPSTASH_REDIS_REST_TOKEN;
  let upstashPipeline: number | null = null;
  let lastIntegrityRejection: unknown = null;
  if (upstashUrl && upstashToken) {
    const pipeRes = await fetch(`${upstashUrl}/pipeline`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${upstashToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify([['PING']]),
    });
    upstashPipeline = pipeRes.status;

    const lastRes = await fetch(`${upstashUrl}/get/feedback:last_integrity_rejection`, {
      headers: { Authorization: `Bearer ${upstashToken}` },
    });
    if (lastRes.ok) {
      const lastJson = (await lastRes.json()) as { result?: string };
      if (lastJson.result) {
        try {
          lastIntegrityRejection = JSON.parse(lastJson.result);
        } catch {
          lastIntegrityRejection = lastJson.result;
        }
      }
    }
  }

  res.status(200).json({
    playIntegritySaParsed: sa != null,
    playIntegritySaEmail: sa?.client_email ?? null,
    playIntegrityOAuth,
    playIntegrityDecodeFake,
    githubTokenPresent: Boolean(githubToken),
    githubTokenLen: githubToken?.length ?? 0,
    githubRepo,
    upstashConfigured: Boolean(upstashUrl && upstashToken),
    upstashPipeline,
    lastIntegrityRejection,
  });
}
