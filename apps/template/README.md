# Twilight template app

Run this app against the shared testing backend:

```bash
fvm flutter run
```

The default URL is `https://origin-production-5ab8.up.railway.app/api/v1/`.
Pass `--dart-define=API_BASE_URL=https://<host>/api/v1/` to change it, and
`--dart-define=APP_ENV=production` for a production build. See
[networking](../../docs/networking.md) for local backend setup and token flow.
