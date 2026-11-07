import 'package:auth/auth.dart';
import 'package:dio/dio.dart';
import 'package:network/network.dart';

class SignedInProfile {
  const SignedInProfile({
    this.email,
    this.phone,
    this.displayName,
    this.photoUrl,
  });

  final String? email;
  final String? phone;
  final String? displayName;
  final String? photoUrl;
}

/// Exchanges a Google ID token for Origin's own JWT session.
class OriginGoogleAuthRepository {
  const OriginGoogleAuthRepository(this._client, this._tokens, this._google);

  final DioClient _client;
  final AuthTokenStore _tokens;
  final GoogleIdentityProvider _google;

  Future<bool> signIn() async {
    final identity = await _google.authenticate();
    if (identity == null) return false;
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        'auth/google/token/',
        data: {'id_token': identity.idToken},
        options: Options(extra: {JwtRefreshInterceptor.skipAuthKey: true}),
      );
      final access = response.data?['access'];
      final refresh = response.data?['refresh'];
      if (access is! String ||
          access.isEmpty ||
          refresh is! String ||
          refresh.isEmpty) {
        throw const FormatException('The server did not return a session.');
      }
      await _tokens.write(
        AuthTokens(
          access: access,
          refresh: refresh,
          email: identity.email,
          displayName: identity.displayName,
          photoUrl: identity.photoUrl,
        ),
      );
      return true;
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<bool> hasSession() async => await _tokens.read() != null;

  Future<SignedInProfile?> signedInProfile() async {
    final tokens = await _tokens.read();
    if (tokens == null) return null;
    return SignedInProfile(
      email: tokens.email,
      phone: tokens.phone,
      displayName: tokens.displayName,
      photoUrl: tokens.photoUrl,
    );
  }

  Future<void> signOut() async {
    await _tokens.clear();
    try {
      await _google.signOut();
    } catch (_) {
      // The Origin session is already cleared; platform cleanup is best effort.
    }
  }
}
