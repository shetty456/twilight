import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'auth_state.dart';
import 'user.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthUnauthenticated()) {
    _init();
  }

  final AuthRepository _repository;

  Future<void> _init() async {
    final result = await _repository.getCurrentUser();
    result.when(
      success: (user) {
        if (user != null) {
          state = AuthAuthenticated(user);
        }
      },
      failure: (_) {
        state = const AuthUnauthenticated();
      },
    );
  }

  Future<void> login(Map<String, dynamic> credentials) async {
    state = const AuthAuthenticating();
    final result = await _repository.login(credentials);
    state = result.when(
      success: AuthAuthenticated.new,
      failure: (e) => AuthError(e.toString()),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  User? get currentUser =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => throw UnimplementedError('Override authRepositoryProvider in your app'),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
