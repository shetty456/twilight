# Deeksha

Deeksha is the display name for the pregnancy-focused story app. The name shown
inside Flutter is configurable with `DEEKSHA_APP_NAME`. The Android package name
and iOS bundle ID are `com.twilight.deeksha`.

## Run the app

The app uses the shared testing backend at
`https://origin-production-5ab8.up.railway.app/api/v1/` by default.
The backend must be reachable from the device.

```sh
fvm flutter run -d <device-id>
```

To use another backend, pass `--dart-define=API_BASE_URL=https://<host>/api/v1/`.
For a local Android emulator, use `http://10.0.2.2:8000/api/v1/`; for a
physical phone, use your computer's LAN IP and run Origin bound to
`0.0.0.0:8000`. Pass `APP_ENV=production` for production builds; those builds
require an HTTPS API URL.

Google sign-in is the default logged-out screen. The app obtains a Google ID
token and exchanges it for an Origin JWT session. The default Google web/server
client ID is configured in `lib/config/product_config.dart`; when using a
different backend, pass its client ID with
`--dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>`. Android OAuth setup
also needs an OAuth client for `com.twilight.deeksha` and the signing
certificate SHA-1 for the build being tested. See
[Google sign-in integration](docs/google-sign-in.md) for the full Android, iOS,
and backend setup.

The phone and OTP screens remain in the code for future use. To show them for
testing, run with `--dart-define=DEEKSHA_GOOGLE_AUTH_ENABLED=false`.

## Backend contract

- `POST auth/google/token/` with `{"id_token":"<Google ID token>"}` returns
  `{"access":"<JWT>","refresh":"<JWT>"}`. Origin verifies the Google token
  against its configured web/server client ID.
- `POST auth/jwt/refresh/` refreshes the Origin access token.
- `GET stories/series/`
- Series include a `thumbnail` storage key and may include a signed HTTP(S)
  `thumbnail_url`. They may also set `is_featured` to choose the Home spotlight.
  Without that flag, Home favors a story with artwork and a description, and
  avoids recently played stories when possible. The spotlight is omitted from
  the "More stories" row. A gradient appears when artwork is unavailable.
- `GET stories/series/{series_id}/episodes/`
- `GET stories/episodes/{episode_id}/media/` returns
  `{"episode_id":"...","audio_url":"https://...","expires_in":3600}`;
  `audio_url` and `expires_in` are `null` when audio is not ready.
  Deeksha requests a fresh media URL each time playback starts, including
  after a pause, because these URLs expire.
- `POST stories/playback-progress/` with `episode_id` and `progress_seconds`

Home shows the latest recent listen first. Saved stories and recent listening
history are also in Profile and kept on the device. Opening a recent episode
resumes from its local position. Sign-out clears this local library because
the backend does not yet expose account-scoped saved stories or a progress-read
endpoint.

Story requests use the Origin JWT obtained from Google sign-in. The app stores
the Origin token pair and Google profile details in platform secure storage.
The phone and OTP fallback uses `auth/otp/phone/request/` and
`auth/otp/phone/verify/` to obtain the same kind of Origin session.

Episodes without an `audio_key` open as reading episodes. Audio playback
requires an `audio_key` and a reachable media URL from Origin.

## Android release signing

Google Play needs a release AAB signed with a private upload key. Put the
keystore at `android/upload-keystore.jks`, copy
`android/key.properties.example` to `android/key.properties`, and replace the
placeholder passwords with the keystore's values. Both private files are
ignored by Git. Back up the keystore and passwords securely; future updates
must use the same upload key unless it is reset in Play Console.

From the repository root, run `make build-aab APP=deeksha` after configuring
the key. The bundle is written to
`apps/deeksha/build/app/outputs/bundle/release/app-release.aab`. Google Play
re-signs installs with its app signing certificate, so register that
certificate's SHA-1 for `com.twilight.deeksha` in the Android Google OAuth
client before testing Google sign-in through Play.
