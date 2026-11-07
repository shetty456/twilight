import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:ui/ui.dart';

import 'config/providers.dart';
import 'features/auth/phone_sign_in_page.dart';
import 'features/listener/listener_shell.dart';

abstract final class VelaColors {
  static const ink = Color(0xFFF7EAF0);
  static const plum = Color(0xFFBDAEB8);
  static const blush = Color(0xFF302530);
  static const cream = Color(0xFF100D13);
  static const surface = Color(0xFF211A23);
  static const raised = Color(0xFF302530);
  static const apricot = Color(0xFFF0BD9D);
  static const action = Color(0xFFD62B4C);
  static const onAction = Colors.white;
}

abstract final class VelaSystemUi {
  static const style = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: VelaColors.cream,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );

  static const navigationStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: VelaColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );
}

class VelaFmApp extends ConsumerWidget {
  const VelaFmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(productNameProvider);
    final base = AppTheme.dark(primaryColor: VelaColors.action);
    final theme = base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: VelaColors.action,
        onPrimary: VelaColors.onAction,
        primaryContainer: VelaColors.raised,
        onPrimaryContainer: VelaColors.ink,
        secondary: VelaColors.apricot,
        onSecondary: VelaColors.cream,
        secondaryContainer: VelaColors.raised,
        onSecondaryContainer: VelaColors.ink,
        surface: VelaColors.cream,
        onSurface: VelaColors.ink,
        surfaceDim: VelaColors.cream,
        surfaceBright: VelaColors.raised,
        surfaceContainerLowest: VelaColors.cream,
        surfaceContainerLow: VelaColors.surface,
        surfaceContainer: VelaColors.surface,
        surfaceContainerHigh: VelaColors.raised,
        surfaceContainerHighest: VelaColors.raised,
        onSurfaceVariant: VelaColors.plum,
        outline: const Color(0xFF6A5363),
        outlineVariant: const Color(0xFF483846),
        inverseSurface: VelaColors.ink,
        onInverseSurface: VelaColors.cream,
        surfaceTint: Colors.transparent,
      ),
      scaffoldBackgroundColor: VelaColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: VelaColors.cream,
        foregroundColor: VelaColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: VelaSystemUi.style,
        centerTitle: false,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: VelaColors.surface),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: VelaColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(color: VelaColors.surface),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: VelaColors.raised,
        contentTextStyle: TextStyle(color: VelaColors.ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VelaColors.surface,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VelaColors.surface,
        labelStyle: const TextStyle(color: VelaColors.plum),
        floatingLabelStyle: const TextStyle(color: VelaColors.ink),
        hintStyle: const TextStyle(color: VelaColors.plum),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8A6C7E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8A6C7E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VelaColors.ink, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: VelaColors.ink,
        selectionColor: VelaColors.blush,
        selectionHandleColor: VelaColors.apricot,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VelaColors.action,
          foregroundColor: VelaColors.onAction,
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VelaColors.apricot,
          side: const BorderSide(color: Color(0xFF6A4C5A)),
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
    return MaterialApp(
      title: title,
      theme: theme,
      builder: (context, child) => SkeletonizerConfig(
        data: const SkeletonizerConfigData(brightness: Brightness.dark),
        child: child!,
      ),
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
          loading: () => const ListenerShellLoading(),
          error: (_, __) => Scaffold(
            body: SafeArea(
              child: AppErrorState(
                title: 'Could not restore your session',
                description: 'Please try again.',
                onRetry: () => ref.read(sessionProvider.notifier).restore(),
              ),
            ),
          ),
        );
  }
}
