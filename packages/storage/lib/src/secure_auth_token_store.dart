import 'dart:convert';

import 'package:auth/auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores a token pair as one encrypted value in Keychain/Android Keystore.
class SecureAuthTokenStore implements AuthTokenStore {
  const SecureAuthTokenStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
    this.key = 'twilight.auth.tokens',
  }) : _storage = storage;

  final FlutterSecureStorage _storage;
  final String key;

  @override
  Future<AuthTokens?> read() async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      return AuthTokens(
        access: value['access'] as String,
        refresh: value['refresh'] as String,
        phone: value['phone'] as String?,
        email: value['email'] as String?,
        displayName: value['displayName'] as String?,
        photoUrl: value['photoUrl'] as String?,
      );
    } on FormatException {
      await clear();
      return null;
    } on TypeError {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthTokens tokens) => _storage.write(
        key: key,
        value: jsonEncode({
          'access': tokens.access,
          'refresh': tokens.refresh,
          if (tokens.phone != null) 'phone': tokens.phone,
          if (tokens.email != null) 'email': tokens.email,
          if (tokens.displayName != null) 'displayName': tokens.displayName,
          if (tokens.photoUrl != null) 'photoUrl': tokens.photoUrl,
        }),
      );

  @override
  Future<void> clear() => _storage.delete(key: key);
}
