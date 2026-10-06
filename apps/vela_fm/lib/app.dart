import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';

import 'config/providers.dart';
import 'features/auth/phone_sign_in_page.dart';
import 'features/stories/library_page.dart';

abstract final class VelaColors {
  static const ink = Color(0xFF322536);
  static const plum = Color(0xFF75516E);
  static const blush = Color(0xFFF8EDEB);
  static const cream = Color(0xFFFFFAF6);
  static const apricot = Color(0xFFE7B593);
}

class VelaFmApp extends ConsumerWidget {
  const VelaFmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(productNameProvider);
    final theme = AppTheme.light(primaryColor: VelaColors.plum).copyWith(
      scaffoldBackgroundColor: VelaColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: VelaColors.cream,
        foregroundColor: VelaColors.ink,
        elevation: 0,
      ),
    );
    return MaterialApp(
      title: title,
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(sessionProvider).when(
      data: (signedIn) =>
          signedIn ? const LibraryPage() : const PhoneSignInPage(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => PhoneSignInPage(startupError: error.toString()),
    );
  }
}
