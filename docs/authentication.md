# Authentication

## Overview

`packages/auth` provides the auth skeleton. The app provides the real implementation.

## What's in the package

- `AuthRepository` — abstract interface your app implements
- `AuthState` — sealed class: `AuthUnauthenticated`, `AuthAuthenticating`, `AuthAuthenticated`, `AuthError`
- `AuthNotifier` — wires repository to Riverpod state
- `authProvider` — `StateNotifierProvider<AuthNotifier, AuthState>`
- `authRepositoryProvider` — must be overridden in the app

## Providing a real implementation

Create a concrete `AuthRepository` in your app:

```dart
// apps/your-product/lib/features/auth/your_auth_repository.dart
class YourAuthRepository implements AuthRepository {
  YourAuthRepository(this._dio);
  final Dio _dio;

  @override
  Future<Result<User>> login(Map<String, dynamic> credentials) async {
    try {
      final response = await _dio.post('/auth/login', data: credentials);
      return Success(User(id: response.data['id'], email: response.data['email']));
    } on DioException catch (e) {
      return Failure(mapDioException(e));
    }
  }

  // implement logout, getCurrentUser, refreshSession...
}
```

Override the provider in `main.dart`:

```dart
ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWith(
      (ref) => YourAuthRepository(ref.watch(dioClientProvider).dio),
    ),
  ],
  child: const App(),
)
```

## Reading auth state

```dart
final authState = ref.watch(authProvider);

return switch (authState) {
  AuthAuthenticated(:final user) => HomeScreen(user: user),
  AuthUnauthenticated() => LoginScreen(),
  AuthAuthenticating() => LoadingWidget(),
  AuthError(:final message) => ErrorScreen(message: message),
};
```

## OTP login (example)

Pass your credentials map to `ref.read(authProvider.notifier).login(...)`:

```dart
await ref.read(authProvider.notifier).login({
  'phone': phoneNumber,
  'otp': otpCode,
});
```

Your `AuthRepository` implementation handles the actual HTTP call.
