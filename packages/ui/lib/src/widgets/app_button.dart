import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, ghost }

enum AppButtonSize { regular, compact }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.size = AppButtonSize.regular,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final AppButtonSize size;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final height = size == AppButtonSize.regular ? 56.0 : 44.0;
    final scheme = Theme.of(context).colorScheme;
    final child =
        isLoading
            ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color:
                    variant == AppButtonVariant.primary
                        ? scheme.onPrimary
                        : scheme.primary,
              ),
            )
            : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(label),
              ],
            );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    };
    return SizedBox(
      height: height,
      width: expanded ? double.infinity : null,
      child: button,
    );
  }
}
