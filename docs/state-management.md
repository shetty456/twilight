# State Management

We use Riverpod. The rule for where state lives:

> State belongs to the feature that owns the state. Global state belongs to the platform.

## Decision tree

| State type | Where it lives |
|-----------|---------------|
| A single widget's open/closed, focused, hovered | `StatefulWidget` or `useState` |
| A feature's data, loading, error | Feature-local provider |
| Auth session, current user | `packages/auth` |
| Network config, analytics client | `packages/network` / `packages/analytics` |

## Feature-local providers

Create providers next to the feature, not in a global folder.

```
features/quiz/
├── quiz_provider.dart   ← lives here
├── quiz_page.dart
└── quiz_service.dart
```

Not:
```
lib/providers/quiz_provider.dart  ❌
```

## When to use a Notifier vs a simple Provider

- `Provider<T>` — for derived/computed values, dependency injection
- `StateNotifierProvider<N, S>` — for state with events/mutations
- `FutureProvider` — for async data you fetch once
- `StreamProvider` — for reactive streams (e.g. auth state changes)

## Global providers live in packages

Auth and network providers are defined in their respective packages and overridden in the app's `ProviderScope`:

```dart
ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWith((_) => MyAuthRepository()),
    apiConfigProvider.overrideWithValue(ApiConfig(...)),
  ],
  child: const App(),
)
```

## Ephemeral UI state

Not everything needs Riverpod. A text field's focus, an animation's progress, a bottom sheet's open state — keep these local to the widget unless there's a clear reason to share them.
