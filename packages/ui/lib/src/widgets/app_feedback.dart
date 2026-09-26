import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_bottom_sheet.dart';

enum AppMessageKind { info, success, warning, error }

Color _messageColor(ColorScheme scheme, AppMessageKind kind) => switch (kind) {
      AppMessageKind.info => scheme.primary,
      AppMessageKind.success => const Color(0xFF16803C),
      AppMessageKind.warning => const Color(0xFF9A6700),
      AppMessageKind.error => scheme.error,
    };

IconData _messageIcon(AppMessageKind kind) => switch (kind) {
      AppMessageKind.info => Icons.info_outline,
      AppMessageKind.success => Icons.check_circle_outline,
      AppMessageKind.warning => Icons.warning_amber_outlined,
      AppMessageKind.error => Icons.error_outline,
    };

/// Persistent feedback placed near the content it describes.
class AppMessageBox extends StatelessWidget {
  const AppMessageBox({
    super.key,
    required this.message,
    this.kind = AppMessageKind.info,
  });

  final String message;
  final AppMessageKind kind;

  @override
  Widget build(BuildContext context) {
    final color = _messageColor(Theme.of(context).colorScheme, kind);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(_messageIcon(kind), color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

abstract final class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    AppMessageKind kind = AppMessageKind.info,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final color = _messageColor(Theme.of(context).colorScheme, kind);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Row(children: [
        Icon(_messageIcon(kind), color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message)),
      ]),
    ));
  }
}

abstract final class AppConfirmationSheet {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool destructive = false,
    IconData? icon,
    String? warningMessage,
    Widget? additionalContent,
    bool isDismissible = true,
  }) async {
    return await AppBottomSheet.show<bool>(
          context,
          isDismissible: isDismissible,
          enableDrag: isDismissible,
          builder: (sheetContext) {
            final scheme = Theme.of(sheetContext).colorScheme;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 48,
                      color: destructive ? scheme.error : scheme.primary),
                  const SizedBox(height: AppSpacing.md),
                ],
                Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(message),
                if (warningMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppMessageBox(
                      message: warningMessage, kind: AppMessageKind.warning),
                ],
                if (additionalContent != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  additionalContent,
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  style: destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError)
                      : null,
                  onPressed: () => Navigator.pop(sheetContext, true),
                  child: Text(confirmLabel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  child: Text(cancelLabel),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
