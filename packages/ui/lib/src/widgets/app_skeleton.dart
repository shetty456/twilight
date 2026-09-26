import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_spacing.dart';

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

/// A ready-made card placeholder for summary and detail screens.
class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({super.key, this.showImage = true});

  final bool showImage;

  @override
  Widget build(BuildContext context) => Skeletonizer.zone(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showImage) ...[
                  const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Bone.square(size: double.infinity),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const Bone.text(words: 3),
                const SizedBox(height: AppSpacing.sm),
                const Bone.multiText(lines: 2),
              ],
            ),
          ),
        ),
      );
}

/// A grid of card placeholders; no fake data is needed.
class AppSkeletonGrid extends StatelessWidget {
  const AppSkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.showImage = true,
  });

  final int itemCount;
  final int crossAxisCount;
  final bool showImage;

  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: showImage ? 0.8 : 1.5,
        ),
        itemBuilder: (_, __) => AppSkeletonCard(showImage: showImage),
      );
}
