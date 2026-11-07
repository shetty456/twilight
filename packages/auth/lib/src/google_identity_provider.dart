import 'package:google_sign_in/google_sign_in.dart';

/// Google identity proof to exchange for an application session on the server.
class GoogleIdentity {
  const GoogleIdentity({
    required this.idToken,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String idToken;
  final String email;
  final String? displayName;
  final String? photoUrl;
}

/// Keeps the platform sign-in SDK separate from an app's backend exchange.
abstract class GoogleIdentityProvider {
  Future<GoogleIdentity?> authenticate();
  Future<void> signOut();
}

class GoogleSignInIdentityProvider implements GoogleIdentityProvider {
  GoogleSignInIdentityProvider({
    required this.serverClientId,
    this.clientId,
  });

  final String serverClientId;
  final String? clientId;
  Future<void>? _initializing;

  Future<void> _initialize() =>
      _initializing ??= GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );

  @override
  Future<GoogleIdentity?> authenticate() async {
    if (serverClientId.isEmpty) {
      throw StateError('Google server client ID is not configured.');
    }
    await _initialize();
    final signIn = GoogleSignIn.instance;
    if (!signIn.supportsAuthenticate()) {
      throw UnsupportedError('Google sign-in needs a platform sign-in button.');
    }
    try {
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const FormatException('Google did not return an ID token.');
      }
      return GoogleIdentity(
        idToken: idToken,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    if (serverClientId.isEmpty) return;
    await _initialize();
    await GoogleSignIn.instance.signOut();
  }
}
