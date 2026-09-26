# Shared storage

`StorageService` provides string key-value storage. `TypedPreferences` adds booleans, integers, JSON, and a namespace so keys from different apps or features do not collide.

```dart
final prefs = TypedPreferences(storageService, namespace: 'my_app.settings');
await prefs.writeBool('notifications_enabled', true);
final enabled = await prefs.readBool('notifications_enabled');
```

Use this for preferences and small non-sensitive state. The auth token store uses secure storage separately; do not put credentials in `TypedPreferences`.
