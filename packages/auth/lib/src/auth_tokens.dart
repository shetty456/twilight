class AuthTokens {
  const AuthTokens({
    required this.access,
    required this.refresh,
    this.phone,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  final String access;
  final String refresh;
  final String? phone;
  final String? email;
  final String? displayName;
  final String? photoUrl;
}

abstract class AuthTokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}
