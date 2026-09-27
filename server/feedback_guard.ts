import { createHash } from 'node:crypto';

export const POW_PREFIX = 'quran-offline';
export const POW_ZERO_NIBBLES = 4;
export const POW_MAX_AGE_MS = 5 * 60 * 1000;

export function neutralizeGithubMentions(text: string): string {
  return text.replace(
    /(^|[^A-Za-z0-9_])@([A-Za-z0-9-]{1,39})\b/g,
    '$1@\u200b$2',
  );
}

function hasLeadingZeroNibbles(hex: string, nibbles: number): boolean {
  return hex.startsWith('0'.repeat(nibbles));
}

export function verifyFeedbackProofOfWork(
  timestampMs: number,
  nonce: number,
  nowMs: number = Date.now(),
): boolean {
  if (!Number.isInteger(timestampMs) || !Number.isInteger(nonce) || nonce < 0) {
    return false;
  }
  if (Math.abs(nowMs - timestampMs) > POW_MAX_AGE_MS) {
    return false;
  }
  const hex = createHash('sha256')
    .update(`${POW_PREFIX}:${timestampMs}:${nonce}`)
    .digest('hex');
  return hasLeadingZeroNibbles(hex, POW_ZERO_NIBBLES);
}

export function isBrowserOrigin(origin: unknown): boolean {
  return typeof origin === 'string' && origin.length > 0;
}

function headerValue(value: string | string[] | undefined): string | null {
  if (typeof value === 'string' && value.trim().length > 0) {
    return value.trim();
  }
  if (Array.isArray(value) && typeof value[0] === 'string' && value[0].trim()) {
    return value[0].trim();
  }
  return null;
}

/**
 * Client IP for rate limiting. Prefer platform-set headers only.
 * Do not trust client-supplied `x-forwarded-for` (leftmost hop is spoofable).
 */
export function trustedClientIp(
  headers: Record<string, string | string[] | undefined>,
  socketRemoteAddress?: string | null,
): string {
  const realIp = headerValue(headers['x-real-ip']);
  if (realIp) return realIp;

  const vercelForwarded = headerValue(headers['x-vercel-forwarded-for']);
  if (vercelForwarded) {
    return vercelForwarded.split(',')[0]?.trim() || 'unknown';
  }

  if (typeof socketRemoteAddress === 'string' && socketRemoteAddress.trim()) {
    return socketRemoteAddress.trim();
  }
  return 'unknown';
}
