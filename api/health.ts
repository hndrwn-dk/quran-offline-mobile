import type { VercelRequest, VercelResponse } from '@vercel/node';
import { timingSafeEqual } from 'node:crypto';

function headerValue(value: string | string[] | undefined): string | null {
  if (typeof value === 'string' && value.trim().length > 0) {
    return value.trim();
  }
  if (Array.isArray(value) && typeof value[0] === 'string' && value[0].trim()) {
    return value[0].trim();
  }
  return null;
}

function extractBearer(authorization: string | null): string | null {
  if (!authorization) return null;
  const match = /^Bearer\s+(.+)$/i.exec(authorization);
  return match?.[1]?.trim() || null;
}

function secretsEqual(provided: string, expected: string): boolean {
  const a = Buffer.from(provided);
  const b = Buffer.from(expected);
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

function isAuthorizedDeepCheck(req: VercelRequest): boolean {
  const expected = process.env.HEALTH_CHECK_SECRET;
  if (!expected) return false;

  const bearer = extractBearer(headerValue(req.headers.authorization));
  if (bearer && secretsEqual(bearer, expected)) return true;

  const headerSecret = headerValue(req.headers['x-health-secret']);
  return Boolean(headerSecret && secretsEqual(headerSecret, expected));
}

/**
 * Public liveness only. Deep config booleans require HEALTH_CHECK_SECRET.
 * Never mints OAuth tokens, never calls GitHub/Play Integrity/Redis, and never
 * returns secret material, token lengths, emails, or stored rejection diagnostics.
 */
export default async function handler(
  req: VercelRequest,
  res: VercelResponse,
): Promise<void> {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  if (!isAuthorizedDeepCheck(req)) {
    res.status(200).json({ ok: true });
    return;
  }

  res.status(200).json({
    ok: true,
    playIntegrityConfigured: Boolean(
      process.env.PLAY_INTEGRITY_SERVICE_ACCOUNT_JSON,
    ),
    githubConfigured: Boolean(process.env.GITHUB_TOKEN),
    upstashConfigured: Boolean(
      process.env.UPSTASH_REDIS_REST_URL &&
        process.env.UPSTASH_REDIS_REST_TOKEN,
    ),
  });
}
