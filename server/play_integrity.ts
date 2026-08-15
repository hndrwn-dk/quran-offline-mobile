import { createSign } from 'node:crypto';

export const FEEDBACK_ANDROID_PACKAGE = 'com.tursinalabs.quranoffline';
export const PLAY_INTEGRITY_MAX_AGE_MS = 5 * 60 * 1000;

export type PlayIntegrityVerdict =
  | 'ok'
  | 'notPlayRecognized'
  | 'nonceMismatch'
  | 'stale'
  | 'wrongPackage'
  | 'weakDevice'
  | 'malformed';

export function evaluatePlayIntegrityVerdict(args: {
  payload: unknown;
  expectedNonce: string;
  nowMs: number;
}): PlayIntegrityVerdict {
  if (args.payload == null || typeof args.payload !== 'object') {
    return 'malformed';
  }
  const root = args.payload as Record<string, unknown>;
  const request = root.requestDetails;
  const app = root.appIntegrity;
  const device = root.deviceIntegrity;
  if (
    request == null ||
    typeof request !== 'object' ||
    app == null ||
    typeof app !== 'object' ||
    device == null ||
    typeof device !== 'object'
  ) {
    return 'malformed';
  }

  const req = request as Record<string, unknown>;
  const appRec = app as Record<string, unknown>;
  const deviceRec = device as Record<string, unknown>;

  if (req.requestPackageName !== FEEDBACK_ANDROID_PACKAGE) {
    return 'wrongPackage';
  }
  if (req.nonce !== args.expectedNonce) {
    return 'nonceMismatch';
  }

  const tsRaw = req.timestampMillis;
  const timestampMs =
    typeof tsRaw === 'number'
      ? tsRaw
      : typeof tsRaw === 'string'
        ? Number(tsRaw)
        : NaN;
  if (!Number.isFinite(timestampMs)) {
    return 'malformed';
  }
  if (Math.abs(args.nowMs - timestampMs) > PLAY_INTEGRITY_MAX_AGE_MS) {
    return 'stale';
  }

  if (appRec.appRecognitionVerdict !== 'PLAY_RECOGNIZED') {
    return 'notPlayRecognized';
  }

  const verdicts = deviceRec.deviceRecognitionVerdict;
  if (
    !Array.isArray(verdicts) ||
    !(
      verdicts.includes('MEETS_DEVICE_INTEGRITY') ||
      verdicts.includes('MEETS_BASIC_INTEGRITY')
    )
  ) {
    return 'weakDevice';
  }

  return 'ok';
}

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

async function googleAccessToken(account: ServiceAccount): Promise<string | null> {
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
  if (!response.ok) return null;
  const json = (await response.json()) as { access_token?: string };
  return json.access_token ?? null;
}

export async function decodePlayIntegrityToken(
  integrityToken: string,
): Promise<unknown | null> {
  const account = parseServiceAccount();
  if (!account) return null;
  const accessToken = await googleAccessToken(account);
  if (!accessToken) return null;

  const url =
    `https://playintegrity.googleapis.com/v1/${FEEDBACK_ANDROID_PACKAGE}` +
    ':decodeIntegrityToken';
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ integrityToken }),
  });
  if (!response.ok) return null;
  const json = (await response.json()) as { tokenPayloadExternal?: unknown };
  return json.tokenPayloadExternal ?? null;
}
