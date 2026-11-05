import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class StoryHomeSkeleton extends StatelessWidget {
  const StoryHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: const AspectRatio(
              aspectRatio: 5 / 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppSkeletonBox(
                    width: double.infinity,
                    height: double.infinity,
                    radius: 14,
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: AppSkeletonBox(width: 78, height: 28, radius: 8),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeletonLines(width: 190, lines: 2),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            AppSkeletonBox(width: 100, height: 48, radius: 10),
                            SizedBox(width: 8),
                            AppSkeletonBox(width: 48, height: 48, radius: 10),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 28),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AppSkeletonLines(width: 148),
        ),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 20 - 14 * 2) * 3 / 7;
          return SizedBox(
            height: cardWidth * 5 / 4 + 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => StoryPosterSkeleton(width: cardWidth),
            ),
          );
        },
      ),
    ],
  );
}

class StoryPosterSkeleton extends StatelessWidget {
  const StoryPosterSkeleton({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AspectRatio(
          aspectRatio: 4 / 5,
          child: AppSkeletonBox(
            width: double.infinity,
            height: double.infinity,
            radius: 10,
          ),
        ),
        const SizedBox(height: 8),
        AppSkeletonLines(width: width * 0.82),
        const SizedBox(height: 5),
        AppSkeletonLines(width: width * 0.56),
      ],
    ),
  );
}

class StoryGridSkeleton extends StatelessWidget {
  const StoryGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 500 ? 2 : 3;
      final tileWidth =
          (constraints.maxWidth - 40 - 14 * (columns - 1)) / columns;
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        itemCount: 6,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: tileWidth * 5 / 4 + 48,
        ),
        itemBuilder: (_, __) => StoryPosterSkeleton(width: tileWidth),
      );
    },
  );
}

class EpisodeListSkeleton extends StatelessWidget {
  const EpisodeListSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < 3; index++) ...[
        const Row(
          children: [
            AppSkeletonBox(width: 58, height: 58, radius: 10),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeletonLines(width: 180),
                  SizedBox(height: 8),
                  AppSkeletonLines(width: 70),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    ],
  );
}

class AudioPlayerSkeleton extends StatelessWidget {
  const AudioPlayerSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      AppSkeletonLines(width: 110),
      SizedBox(height: 24),
      AppSkeletonBox(width: double.infinity, height: 5, radius: 3),
      SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [AppSkeletonLines(width: 38), AppSkeletonLines(width: 38)],
      ),
      SizedBox(height: 18),
      AppSkeletonBox(width: 72, height: 72, radius: 36),
    ],
  );
}
