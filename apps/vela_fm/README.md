# Vela FM MVP

Vela FM is the working name for the pregnancy-focused story app. The name shown
inside Flutter is configurable with `VELA_FM_APP_NAME`; the app package name is
independent of the visible brand.

## Run against Origin

The Origin backend must be reachable from the device. Its API base URL ends in
`/api/v1/`.

```sh
fvm flutter run -d <device-id> \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://<your-computer-LAN-IP>:8000/api/v1/ \
  --dart-define='VELA_FM_APP_NAME=Vela FM'
```

For an Android emulator, the default URL is
`http://10.0.2.2:8000/api/v1/`. On a physical phone, replace it with the
computer's LAN IP and run Origin bound to `0.0.0.0:8000`. Production uses
`APP_ENV=production` and requires an HTTPS API URL.

## Backend contract

- `POST auth/otp/phone/request/` with `{"phone":"+919876543210"}`
- `POST auth/otp/phone/verify/` with `{"phone":"+919876543210","otp":"3821"}`
- `GET stories/series/`
- `GET stories/series/{series_id}/episodes/`
- `GET stories/episodes/{episode_id}/media/` returns
  `{"episode_id":"...","audio_url":"https://...","expires_in":3600}`;
  `audio_url` and `expires_in` are `null` when audio is not ready.
- `POST stories/playback-progress/` with `episode_id` and `progress_seconds`

All story requests require the JWT from OTP verification. The app stores the
token pair in platform secure storage and refreshes it through
`auth/jwt/refresh/`.

Origin's development sample stories contain text but no playable audio. The
app presents those as reading episodes. Real audio playback requires a real
episode with an `audio_key` and a reachable object-storage URL.

Origin's current phone OTP handler creates a code but has no SMS delivery
integration. A local tester needs access to the code until delivery is added.
