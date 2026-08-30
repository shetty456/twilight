# Creating a New App

## 1. Scaffold the app

```bash
fvm flutter create apps/<your-product> \
  --org com.<yourbundle> \
  --project-name <your-product> \
  --platforms android,ios
```

## 2. Add workspace resolution

In `apps/<your-product>/pubspec.yaml`, replace the generated content with:

```yaml
name: <your-product>
description: <description>
publish_to: none
version: 1.0.0+1

resolution: workspace

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  go_router: ^14.0.0
  cupertino_icons: ^1.0.8
  core:
    path: ../../packages/core
  auth:
    path: ../../packages/auth
  network:
    path: ../../packages/network
  ui:
    path: ../../packages/ui
  analytics:
    path: ../../packages/analytics
  storage:
    path: ../../packages/storage

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
```

## 3. Register in the workspace

In the root `pubspec.yaml`, add your app:

```yaml
workspace:
  - apps/<your-product>   # add this
  - apps/template
  - packages/core
  # ...
```

In `melos.yaml`, the glob `apps/**` already picks it up automatically.

## 4. Resolve dependencies

```bash
fvm flutter pub get
```

## 5. Set up the app structure

Copy `apps/template/lib/` as a starting point, then:

1. Update `config/env_config.dart` with your real API base URLs
2. Update `config/product_config.dart` with your app name and bundle ID
3. Remove the template `features/home/` and add your own features
4. Update `main.dart` if you need additional provider overrides

## 6. Update Android bundle ID

In `apps/<your-product>/android/app/build.gradle`:

```groovy
android {
    defaultConfig {
        applicationId "com.yourcompany.yourproduct"
        // ...
    }
}
```

## 7. Update iOS bundle ID

Open `apps/<your-product>/ios/Runner.xcodeproj` in Xcode and set the bundle identifier.

## 8. Run

```bash
cd apps/<your-product>
fvm flutter run
```

## Feature conventions

See [architecture.md](architecture.md) for how to structure features inside your app.
