# Flavors

## Apps vs Flavors

**App** = a distinct product (different bundle ID, different store listing, different business).

**Flavor** = an environment/variant of the same product (dev, staging, prod).

```
apps/
├── quiz/     ← a product
├── tutor/    ← a different product
└── b2b/      ← another product

Each of those can have:
  └── development / staging / production flavors
```

## How environments work (current approach)

Each app has env configs in `lib/config/env_config.dart`:

```dart
class DevConfig extends AppConfig { ... }
class StagingConfig extends AppConfig { ... }
class ProdConfig extends AppConfig { ... }
```

Switch the active config in `lib/config/providers.dart`:

```dart
const AppConfig _activeConfig = DevConfig();  // ← change this
```

## Adding proper build flavors (when you're ready)

Flutter build flavors let you compile different configs without changing code:

```bash
fvm flutter run --flavor development -t lib/main_dev.dart
fvm flutter build apk --flavor production -t lib/main_prod.dart
```

To set this up:
1. Add `flavorDimensions` and `productFlavors` to `android/app/build.gradle`
2. Add schemes in Xcode for iOS
3. Create `main_dev.dart`, `main_staging.dart`, `main_prod.dart` entry points
4. Each entry point instantiates the right config

Document this per-product when you add it — the approach is product-specific.
