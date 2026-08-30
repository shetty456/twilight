import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';

import 'home_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(homeMessageProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: AppSpacing.md),
            Text(
              switch (authState) {
                AuthAuthenticated(:final user) =>
                  'Logged in as ${user.displayName ?? user.email ?? user.id}',
                AuthAuthenticating() => 'Authenticating…',
                AuthUnauthenticated() => 'Not logged in',
                AuthError(:final message) => 'Auth error: $message',
              },
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
