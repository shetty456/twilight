import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_button.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _AppStateContent(
        title: title,
        description: description,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
      );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    this.description,
    this.actionLabel = 'Try again',
    this.onRetry,
  });

  final String title;
  final String? description;
  final String actionLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _AppStateContent(
        title: title,
        description: description,
        icon: Icons.error_outline,
        actionLabel: onRetry == null ? null : actionLabel,
        onAction: onRetry,
      );
}

class _AppStateContent extends StatelessWidget {
  const _AppStateContent({
    required this.title,
    required this.description,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String? description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(title,
                textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(description!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
