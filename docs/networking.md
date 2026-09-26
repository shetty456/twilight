# Networking with Origin

Twilight apps use the single Django REST Framework backend in `~/Desktop/origin/backend`. Origin owns shared models and product APIs; each mobile app owns its screens and product-specific API services. Origin mounts API routes under `/api/v1/`, with JWT refresh at `/api/v1/auth/token/refresh/`.

## Development and production

Every app supplies two build settings: `APP_ENV` (`development` or `production`) and `API_BASE_URL` (the full `/api/v1/` URL). The shared `ApiConfig.fromBuildEnvironment()` reads them. A missing setting fails at startup; production requires HTTPS. The URL is normalized to a trailing slash.

For a physical phone on the same Wi-Fi as the computer, start Origin from its own repository:

```bash
cd ~/Desktop/origin
make up
```

Origin's Docker Compose configuration publishes port 8000 and binds Django to `0.0.0.0:8000`. Find the computer's Wi-Fi LAN address (on macOS, often `ipconfig getifaddr en0`). Then run the template from Twilight:

```bash
cd ~/Desktop/twilight/apps/template
fvm flutter run -d <phone-id> \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://<computer-lan-ip>:8000/api/v1/
```

Replace `<computer-lan-ip>` with the computer's actual address, for example `192.168.1.20`. `localhost` on the phone means the phone, not the computer. The phone and computer must be able to reach each other on the LAN; some guest Wi-Fi networks isolate clients. The template permits local HTTP in Android debug builds and local networking on iOS. Its release Android manifest includes internet permission. If a new app is scaffolded independently, copy those platform settings from the template. [Flutter's network policy guidance](https://docs.flutter.dev/release/breaking-changes/network-policy-ios-android) explains the platform restrictions.

If Django itself is running on the **same phone** as the app, use `http://127.0.0.1:8000/api/v1/` instead. Origin's current Docker Compose setup runs on a computer; running Django on a phone requires a separate Python/server setup for that device.

When the production server has a hostname, build with its HTTPS URL:

```bash
fvm flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://<production-host>/api/v1/
```

The production URL is still pending hosting; no placeholder hostname is baked into the app. Development and production each need their own backend data and deployment configuration when both are hosted. A build setting changes the destination; it does not create a second server or database.

## Shared client

`packages/network` owns the Dio client, timeouts, JSON headers, error mapping, and JWT refresh. Product API services belong near their features:

```dart
final dio = ref.read(dioClientProvider).dio;
final response = await dio.get<Map<String, dynamic>>('products/example/items/');
```

Paths passed to the client are **relative**, without a leading `/`, because the base URL already contains `/api/v1/`. `dio.get('/items/')` would address the host root instead of the versioned API. Development logs omit headers and bodies so OTPs and tokens are not printed.

## Origin JWT tokens

Origin's email and phone OTP verify endpoints return `{ "access": "...", "refresh": "..." }`. Save the pair in the shared secure store after verification:

```dart
final store = ref.read(authTokenStoreProvider)!;
await store.write(AuthTokens(
  access: data['access'] as String,
  refresh: data['refresh'] as String,
));
```

The template overrides `authTokenStoreProvider` with `SecureAuthTokenStore`, which stores the pair together in Android Keystore/iOS Keychain. Its storage key includes the environment and API host/port; that keeps development tokens separate from production tokens when one build replaces the other on a phone. Product apps should copy that override when they adopt Origin authentication. Clear it on logout with `await store.clear()`. Do not use `SharedPreferencesStorage` for JWTs.

The template also disables Android backup for encrypted token data and configures iOS Keychain Sharing. New product apps should carry over those native settings or choose an equivalent Android backup exclusion; see the [secure storage plugin setup](https://pub.dev/packages/flutter_secure_storage/versions/10.3.4).

For a public login or OTP request, skip attaching any existing access token:

```dart
await dio.post<Map<String, dynamic>>(
  'auth/otp/email/request/',
  data: {'email': email},
  options: Options(extra: {JwtRefreshInterceptor.skipAuthKey: true}),
);
```

On a protected request's 401, the client sends the refresh token to `auth/token/refresh/`, persists the **rotated access and refresh pair**, and retries the original request once. Concurrent 401s share one refresh operation. Invalid refresh tokens clear the stored pair; transient refresh failures leave it available for a later retry. The app should return to its login flow when a protected request still fails with 401. Origin currently uses 60-minute access tokens and seven-day refresh tokens; the client relies on 401 responses rather than hardcoding those durations.

## Error handling and new product APIs

Use `mapDioException(e)` to convert Dio errors into the shared `NetworkException`. Define product response models and API services in `apps/<product>/lib/features/<feature>/`. As Origin adds a product route, add the matching app service using the same relative-path convention. The shared client does not need a new implementation for each model.

Origin source references: `config/urls.py`, `config/api_urls.py`, `core/identity/urls.py`, and `config/settings/base.py` in `~/Desktop/origin/backend`.
