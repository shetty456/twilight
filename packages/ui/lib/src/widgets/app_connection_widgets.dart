import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A status banner; the app supplies its connection state and localized copy.
class AppOfflineBanner extends StatelessWidget {
  const AppOfflineBanner({
    super.key,
    required this.isOffline,
    this.message = 'No connection',
    this.retryLabel = 'Retry',
    this.onRetry,
  });

  final bool isOffline;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: scheme.onErrorContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: Text(message,
                    style: TextStyle(color: scheme.onErrorContainer))),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}

/// Image avatar with a fallback for absent or failed network images.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24,
    this.fallbackIcon = Icons.person,
  });

  final String? imageUrl;
  final String? name;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: name == null || name!.trim().isEmpty
          ? Icon(fallbackIcon)
          : Text(name!.trim().characters.first.toUpperCase()),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
