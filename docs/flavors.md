# Development and production builds

An **app** is a separate product. An **environment** is the backend that an app build connects to. Twilight currently uses two environments: development and production.

`APP_ENV` and `API_BASE_URL` are compile-time settings passed with `--dart-define`. See [networking.md](networking.md) for local phone and production commands. The template reads them through `ApiConfig.fromBuildEnvironment()`; it no longer requires editing a source constant to change environments. Missing settings fail at startup, and a production URL must use HTTPS.

The current choice is **one installed build per product**. Development and production use the same Android application ID and iOS bundle ID, so installing one build replaces the other. Native product flavors and extra Xcode schemes are unnecessary for this setup. The template scopes stored JWTs by environment and API host so replacing a development build with a production build does not reuse its login tokens.

If a product later needs both builds installed side by side, give them distinct native IDs using [Flutter's Android flavor guide](https://docs.flutter.dev/deployment/flavors) and [iOS flavor guide](https://docs.flutter.dev/deployment/flavors-ios).
