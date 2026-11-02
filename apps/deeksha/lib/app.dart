import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';

import 'config/providers.dart';
import 'features/auth/phone_sign_in_page.dart';
import 'features/listener/listener_shell.dart';

abstract final class VelaColors {
  static const ink = Color(0xFFF7EAF0);
  static const plum = Color(0xFFBDAEB8);
  static const blush = Color(0xFF302530);
  static const cream = Color(0xFF19121D);
  static const surface = Color(0xFF281E2A);
  static const apricot = Color(0xFFF0BD9D);
  static const onApricot = Color(0xFF3B2729);
}

class VelaFmApp extends ConsumerWidget {
  const VelaFmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(productNameProvider);
    final base = AppTheme.dark(primaryColor: VelaColors.apricot);
    final theme = base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: VelaColors.apricot,
        onPrimary: VelaColors.onApricot,
        surface: VelaColors.cream,
        onSurface: VelaColors.ink,
        surfaceContainerHighest: VelaColors.surface,
        onSurfaceVariant: VelaColors.plum,
        outline: const Color(0xFF594654),
      ),
      scaffoldBackgroundColor: VelaColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: VelaColors.cream,
        foregroundColor: VelaColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VelaColors.cream,
        indicatorColor: VelaColors.blush,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            color: VelaColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: VelaColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VelaColors.surface,
        hintStyle: const TextStyle(color: VelaColors.plum),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VelaColors.apricot,
          foregroundColor: VelaColors.onApricot,
          minimumSize: const Size(0, 56),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VelaColors.apricot,
          side: const BorderSide(color: Color(0xFF6A4C5A)),
          minimumSize: const Size(0, 56),
          shape: const StadiumBorder(),
        ),
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
    return ref
        .watch(sessionProvider)
        .when(
          data: (signedIn) =>
              signedIn ? const ListenerShell() : const PhoneSignInPage(),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => PhoneSignInPage(startupError: error.toString()),
        );
  }
}
