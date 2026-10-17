# Deeksha MVP

Deeksha is the display name for the pregnancy-focused story app. The name shown
inside Flutter is configurable with `DEEKSHA_APP_NAME` (the former
`VELA_FM_APP_NAME` override still works). The app package name and bundle IDs
remain independent of the visible brand.

## Run against Origin

The app uses the shared testing backend at
`https://origin-production-5ab8.up.railway.app/api/v1/` by default.
The backend must be reachable from the device.

```sh
fvm flutter run -d <device-id> \
  --dart-define='DEEKSHA_APP_NAME=Deeksha'
```

To use another backend, pass `--dart-define=API_BASE_URL=https://<host>/api/v1/`.
For a local Android emulator, use `http://10.0.2.2:8000/api/v1/`; for a
physical phone, use your computer's LAN IP and run Origin bound to
`0.0.0.0:8000`. Pass `APP_ENV=production` for production builds; those builds
require an HTTPS API URL.

## Backend contract

- `POST auth/otp/phone/request/` with `{"phone":"+919876543210"}`
- `POST auth/otp/phone/verify/` with `{"phone":"+919876543210","otp":"3821"}`
- `GET stories/series/`
- Series may include an absolute HTTP(S) `thumbnail` URL. The same artwork is
  shown on the featured card, story rows, saved stories, and episode screen.
  A gradient appears until artwork is available.
- `GET stories/series/{series_id}/episodes/`
- `GET stories/episodes/{episode_id}/media/` returns
  `{"episode_id":"...","audio_url":"https://...","expires_in":3600}`;
  `audio_url` and `expires_in` are `null` when audio is not ready.
- `POST stories/playback-progress/` with `episode_id` and `progress_seconds`

The Home and My Library tabs also keep saved series and recent listening
positions on the device. Opening a recent episode resumes from its local
position. Sign-out clears this local library because the backend does not yet
expose account-scoped saved stories or a progress-read endpoint.

All story requests require the JWT from OTP verification. The app stores the
token pair in platform secure storage and refreshes it through
`auth/jwt/refresh/`.

Origin's development sample stories contain text but no playable audio. The
app presents those as reading episodes. Real audio playback requires a real
episode with an `audio_key` and a reachable object-storage URL.

Origin's current phone OTP handler creates a code but has no SMS delivery
integration. A local tester needs access to the code until delivery is added.
