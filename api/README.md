# Feedback API (Vercel)

Serverless endpoint used by the Quran Offline app to create GitHub Issues.

## Deploy

1. Import this repo (or subdirectory) in [Vercel](https://vercel.com).
2. Set environment variables:

| Variable | Description |
|----------|-------------|
| `GITHUB_TOKEN` | Fine-grained PAT with **Issues: Read and write** on `hndrwn-dk/quran-offline-mobile` only |
| `GITHUB_REPO` | Optional. Default: `hndrwn-dk/quran-offline-mobile` |
| `PLAY_INTEGRITY_SERVICE_ACCOUNT_JSON` | GCP service account JSON (Play Integrity API). Required; API fails closed without it |
| `UPSTASH_REDIS_REST_URL` | Upstash Redis REST URL. Durable 5/hour rate limit + nonce replay |
| `UPSTASH_REDIS_REST_TOKEN` | Upstash Redis REST token |

3. Deploy. Note the production URL (e.g. `https://your-project.vercel.app`).
4. Update `lib/core/constants/feedback_api.dart` in the Flutter app with  
   `https://your-project.vercel.app/api/feedback`.

## Endpoint

`POST /api/feedback`

```json
{
  "type": "bug",
  "title": "Short summary",
  "description": "Detailed description",
  "metadata": {
    "appVersion": "1.0.5 (39)",
    "dataVersion": "…",
    "language": "id",
    "surahId": 56,
    "ayahNo": 91,
    "arabicSnippet": "optional"
  },
  "integrityToken": "Play Integrity token from the Android app",
  "nonce": "URL-safe Base64 nonce bound inside that token"
}
```

- Accepts only Play Store installs (`PLAY_RECOGNIZED`) for package `com.tursinalabs.quranoffline`
- Sideload / adb / missing Play services: API rejects; the app opens email fallback
- `type`: `bug` → label `bug`; `feature` → label `new feature`
- Rate limit: 5 requests per IP per hour (Upstash when configured)
- Each nonce can be used once (5 minute TTL)

## Local typecheck

```bash
npm install
npm run typecheck
```
