# Architecture

## The one rule

```
apps/ → packages/
```

- Apps import packages. Packages never import apps. Apps never import each other.
- Shared infrastructure belongs in `packages/`. Product-specific behavior belongs in `apps/`.

## Structure

```
twilight/
├── apps/          # Each product is an independently buildable Flutter app
└── packages/      # Shared platform infrastructure
```

## Shared packages

| Package | Purpose |
|---------|---------|
| `core` | Config, errors, logging, `Result<T>` |
| `auth` | AuthRepository, session, Riverpod providers |
| `network` | Dio client, interceptors, error mapping |
| `ui` | Theme, colors, spacing, shared widgets |
| `analytics` | Analytics interface + no-op default |
| `storage` | Key-value storage abstraction |

## Products (apps)

Each app in `apps/` is:
- Its own Flutter project with its own bundle ID
- Independently buildable and publishable
- Responsible for its own features, routes, models, and services
- Allowed to import any package from `packages/`

## State: global vs feature-local

**Global state** (lives in packages, available everywhere):
- Auth session and current user
- Network configuration
- Analytics client

**Feature-local state** (lives inside the feature that owns it):
- Quiz state, cart state, chat state, onboarding state, etc.

Do not promote feature state to global unless it genuinely needs to be shared across multiple features.

## Feature structure

Start simple. Grow only when the feature earns it.

Simple feature:
```
features/onboarding/
├── onboarding_page.dart
└── onboarding_provider.dart
```

Complex feature:
```
features/quiz/
├── models/
├── services/
├── providers/
└── presentation/
```

> Structure should follow complexity.

## Product API services

API services for a product belong in the product app, near the feature that owns them:

```
apps/quiz/lib/features/quiz/services/quiz_service.dart   ✅
packages/network/lib/quiz_service.dart                   ❌
```
