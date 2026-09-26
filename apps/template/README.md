# Twilight template app

Start Origin from `~/Desktop/origin` with `make up`, then run this app on a phone on the same Wi-Fi:

```bash
fvm flutter run \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://<computer-lan-ip>:8000/api/v1/
```

Replace `<computer-lan-ip>` with the computer's LAN IP address. The template needs both build settings; production needs an HTTPS URL. See [networking](../../docs/networking.md) and [creating an app](../../docs/creating-an-app.md) for the shared backend, token flow, and product setup.
