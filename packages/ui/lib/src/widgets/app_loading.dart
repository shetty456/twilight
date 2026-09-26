import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Runs one async action at a time and shows progress until it finishes.
class AsyncAppButton extends StatefulWidget {
  const AsyncAppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final Future<void> Function()? onPressed;
  final IconData? icon;

  @override
  State<AsyncAppButton> createState() => _AsyncAppButtonState();
}

class _AsyncAppButtonState extends State<AsyncAppButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy || widget.onPressed == null) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: _busy || widget.onPressed == null ? null : _run,
        icon: _busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(widget.icon ?? Icons.arrow_forward),
        label: Text(widget.label),
      );
}

class AppProgress extends StatelessWidget {
  const AppProgress({super.key, this.value, this.label});

  final double? value;
  final String? label;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: value),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      );
}

/// Blocks interaction while a screen-level operation is running.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.loading,
    required this.child,
    this.message,
  });

  final bool loading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          if (loading) ...[
            const ModalBarrier(dismissible: false, color: Colors.black38),
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(message!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      );
}
