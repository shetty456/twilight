# Twilight

Flutter monorepo for the studio's product portfolio. Shared infrastructure lives in `packages/`; each product lives in `apps/`. Starting a new product means creating a thin app shell and connecting it — not rebuilding the platform.

---

## Prerequisites

| Tool | Install |
|------|---------|
| FVM | `brew tap leoafarias/fvm && brew install fvm` |
| Melos | `dart pub global activate melos` (then add `~/.pub-cache/bin` to your PATH) |

> All Flutter commands in this repo run through **FVM**. Do not use a globally installed `flutter` directly.

---

## Initial Setup

```bash
# 1. Clone the repo
git clone https://github.com/shetty456/twilight.git
cd twilight

# 2. Install the pinned Flutter version
fvm install

# 3. Resolve all workspace dependencies
fvm flutter pub get

# 4. Verify everything is in order
fvm flutter analyze
```

---

## Running an App on Your Phone

Connect your device via USB (enable USB debugging on Android / trust the Mac on iOS).

```bash
# List connected devices
fvm flutter devices

# Run the template app on a specific device
cd apps/template
fvm flutter run -d <device-id>

# Or let Flutter pick the only connected device
cd apps/template
fvm flutter run
```

> For iOS you need Xcode installed and a valid Apple developer account configured.

---

## Making Changes

1. Edit code in `apps/<your-app>/` for product-specific features.
2. Edit code in `packages/<package>/` for shared infrastructure.
3. Re-run the app — hot reload (`r`) and hot restart (`R`) work as normal in the running session.

After changing any `pubspec.yaml`:

```bash
fvm flutter pub get
```

---

## Building for Distribution

### Android APK (sideload / testing)

```bash
cd apps/template

# Debug APK
fvm flutter build apk --debug

# Release APK (requires signing config — see docs/flavors.md)
fvm flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Google Play)

```bash
cd apps/template
fvm flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS Archive (App Store / TestFlight)

```bash
cd apps/template
fvm flutter build ipa --release
```

> Requires Xcode, a provisioning profile, and an Apple distribution certificate.

---

## Common Workspace Commands

All of these run from the **repo root**.

```bash
# Static analysis
fvm flutter analyze

# Format code in-place
fvm dart format .

# Run all tests
fvm flutter test

# Clean all build artifacts
fvm flutter clean
```

With Melos on PATH (`~/.pub-cache/bin`):

```bash
melos run analyze
melos run format:fix
melos run test
melos run clean
```

---

## Creating a New App

See **[docs/creating-an-app.md](docs/creating-an-app.md)** for the full step-by-step guide.

The short version:

1. Copy `apps/template` → `apps/<your-product>`
2. Update the `name`, bundle ID, and `ProductConfig` in the new app
3. Add the new path to the `workspace:` list in the root `pubspec.yaml`
4. Add the new path to `packages:` in `melos.yaml`
5. Run `fvm flutter pub get` from the root
6. Start building features

---

## Repository Structure

```
twilight/
├── apps/
│   └── template/          # Reference app — copy this to start a new product
├── packages/
│   ├── core/              # Config, errors, logging, result type
│   ├── auth/              # Auth abstractions and Riverpod providers
│   ├── network/           # Dio client, interceptors, error mapping
│   ├── ui/                # Theme, shared widgets, design primitives
│   ├── analytics/         # Analytics interface (no-op default)
│   └── storage/           # Key-value storage abstraction
├── docs/                  # Architecture and workflow documentation
├── .fvmrc                 # Pinned Flutter version
├── pubspec.yaml           # Dart pub workspace root
└── melos.yaml             # Melos script runner
```

---

## Documentation

| Doc | What it covers |
|-----|---------------|
| [Architecture](docs/architecture.md) | Dependency rules, package boundaries |
| [Getting Started](docs/getting-started.md) | Full environment setup walkthrough |
| [Creating an App](docs/creating-an-app.md) | Step-by-step guide for a new product |
| [State Management](docs/state-management.md) | When to use widget state vs Riverpod |
| [Authentication](docs/authentication.md) | AuthRepository pattern |
| [Networking](docs/networking.md) | DioClient, product API services |
| [Analytics](docs/analytics.md) | Shared mechanism, product-owned events |
| [Flavors](docs/flavors.md) | App vs flavor, environment setup |

---

## Flutter Version

Pinned to **Flutter 3.35.6** (Dart 3.9.2) via FVM. See `.fvmrc`.
