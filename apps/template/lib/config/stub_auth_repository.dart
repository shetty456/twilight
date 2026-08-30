import 'package:auth/auth.dart';
import 'package:core/core.dart';

/// No-op auth repository for the template app.
/// Replace this with a real implementation when wiring up authentication.
class StubAuthRepository implements AuthRepository {
  const StubAuthRepository();

  @override
  Future<Result<User>> login(Map<String, dynamic> credentials) async {
    return const Failure(AuthException('Auth not implemented yet'));
  }

  @override
  Future<Result<void>> logout() async => const Success(null);

  @override
  Future<Result<User?>> getCurrentUser() async => const Success(null);

  @override
  Future<Result<User>> refreshSession() async {
    return const Failure(AuthException('Auth not implemented yet'));
  }
}
