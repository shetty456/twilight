import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Animates an existing layout as a loading skeleton.
///
/// For data-driven lists, pass sample items while [isLoading] is true so the
/// list has children to paint. Avoid starting real image requests in that state.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) => Skeletonizer(
        enabled: isLoading,
        child: child,
      );
}

/// A ready-to-use loading list for screens without data yet.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({
    super.key,
    this.itemCount = 5,
    this.showAvatar = true,
  });

  final int itemCount;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) => AppSkeleton(
        isLoading: true,
        child: ListView.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) => ListTile(
            leading: showAvatar
                ? const CircleAvatar(child: Icon(Icons.person))
                : null,
            title: const Text('Loading item title'),
            subtitle: const Text('Loading item details'),
          ),
        ),
      );
}
