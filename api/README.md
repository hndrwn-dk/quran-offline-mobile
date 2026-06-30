# Feedback API (Vercel)

Serverless endpoint used by the Quran Offline app to create GitHub Issues.

## Deploy

1. Import this repo (or subdirectory) in [Vercel](https://vercel.com).
2. Set environment variables:

| Variable | Description |
|----------|-------------|
| `GITHUB_TOKEN` | Fine-grained PAT with **Issues: Read and write** on `hndrwn-dk/quran-offline-mobile` only |
| `GITHUB_REPO` | Optional. Default: `hndrwn-dk/quran-offline-mobile` |

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
    "appVersion": "1.0.5 (34)",
    "dataVersion": "…",
    "language": "id",
    "surahId": 56,
    "ayahNo": 91,
    "arabicSnippet": "optional"
  }
}
```

- `type`: `bug` → label `bug`; `feature` → label `new feature`
- Rate limit: 5 requests per IP per hour

## Local typecheck

```bash
npm install
npm run typecheck
```
