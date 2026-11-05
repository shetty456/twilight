import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// A recoverable request failure, with copy chosen from the actual error.
class StoryRequestError extends StatelessWidget {
  const StoryRequestError({
    super.key,
    required this.error,
    required this.subject,
    required this.onRetry,
  });

  final Object error;
  final String subject;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error is NetworkException &&
        (error as NetworkException).message == 'No internet connection') {
      return AppEmptyState(
        title: 'No internet connection',
        description: 'Check your connection, then try again.',
        icon: Icons.wifi_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      );
    }

    final timedOut =
        error is NetworkException &&
        (error as NetworkException).message == 'Request timed out';
    return AppErrorState(
      title: timedOut ? 'Connection timed out' : 'Could not load $subject',
      description: timedOut
          ? 'The request took too long. Please try again.'
          : 'Something went wrong. Please try again.',
      onRetry: onRetry,
    );
  }
}
