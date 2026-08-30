# Networking

## Shared client

`packages/network` provides `DioClient` — a pre-configured Dio instance with:
- Base URL from `ApiConfig`
- Connect / receive timeouts
- Auth interceptor (adds `Bearer <token>` header)
- Request logging in development

## Using the client

```dart
final dio = ref.read(dioClientProvider).dio;
final response = await dio.get('/users/me');
```

## Product API services

API services belong in the product app, near the feature that uses them.

```
apps/quiz/lib/features/quiz/services/quiz_service.dart   ✅
packages/network/lib/quiz_service.dart                   ❌
```

Example service:

```dart
class QuizService {
  QuizService(this._dio);
  final Dio _dio;

  Future<Result<List<Quiz>>> getQuizzes() async {
    try {
      final response = await _dio.get('/quizzes');
      final quizzes = (response.data as List).map(Quiz.fromJson).toList();
      return Success(quizzes);
    } on DioException catch (e) {
      return Failure(mapDioException(e));
    }
  }
}
```

## Wiring the auth interceptor

Provide a token getter when creating `DioClient`:

```dart
DioClient(config, getToken: () async => ref.read(tokenStorageProvider).read('access_token'))
```

## Error handling

Use `mapDioException(e)` from `packages/network` to convert `DioException` to `NetworkException`:

```dart
} on DioException catch (e) {
  return Failure(mapDioException(e));
}
```

## Environment-specific base URLs

Configure in `apps/<product>/lib/config/env_config.dart` — each config class provides its own `apiBaseUrl`.
