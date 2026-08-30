import 'package:core/core.dart';

import 'user.dart';

abstract class AuthRepository {
  Future<Result<User>> login(Map<String, dynamic> credentials);
  Future<Result<void>> logout();
  Future<Result<User?>> getCurrentUser();
  Future<Result<User>> refreshSession();
}
