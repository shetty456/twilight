class AuthTokens {
  const AuthTokens({required this.access, required this.refresh, this.phone});

  final String access;
  final String refresh;
  final String? phone;
}

abstract class AuthTokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}
