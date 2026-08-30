sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {this.statusCode});
  final int? statusCode;
}

final class AuthException extends AppException {
  const AuthException(super.message);
}

final class StorageException extends AppException {
  const StorageException(super.message);
}

final class UnexpectedException extends AppException {
  const UnexpectedException(super.message, {this.cause});
  final Object? cause;
}
