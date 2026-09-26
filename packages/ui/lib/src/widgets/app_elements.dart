import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A surface for content shared across product screens.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      );
}

/// Selectable filter chip.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => FilterChip(
        label: Text(label),
        avatar: icon,
        selected: selected,
        onSelected: onSelected,
      );
}

/// Short semantic status label.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.color, this.icon});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = color ?? scheme.secondaryContainer;
    final foreground = color == null
        ? scheme.onSecondaryContainer
        : ThemeData.estimateBrightnessForColor(background) == Brightness.dark
            ? Colors.white
            : Colors.black;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: foreground)),
          ],
        ),
      ),
    );
  }
}

class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.indent = 0, this.endIndent = 0});

  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        indent: indent,
        endIndent: endIndent,
        color: Theme.of(context).colorScheme.outlineVariant,
      );
}
