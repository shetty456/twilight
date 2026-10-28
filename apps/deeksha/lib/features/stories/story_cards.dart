import 'package:flutter/material.dart';

import '../../app.dart';
import '../listener/listener_library.dart';
import '../../stories/models/story_models.dart';
import 'story_artwork.dart';

class StoryPosterCard extends StatelessWidget {
  const StoryPosterCard({super.key, required this.series, required this.onTap});

  final StorySeries series;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 190,
                width: 150,
                child: StoryArtwork(
                    thumbnail: series.thumbnailUrl ?? series.thumbnail,
                    borderRadius: 16),
              ),
              const SizedBox(height: 8),
              Text(
                series.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: VelaColors.ink,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
}

class RecentListenCard extends StatelessWidget {
  const RecentListenCard({
    super.key,
    required this.listen,
    required this.onTap,
    this.width,
  });

  final RecentListen listen;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final progress = listen.durationSeconds > 0
        ? (listen.positionSeconds / listen.durationSeconds).clamp(0.0, 1.0)
        : 0.0;
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 94,
                  child: StoryArtwork(
                    thumbnail:
                        listen.series.thumbnailUrl ?? listen.series.thumbnail,
                    borderRadius: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        listen.series.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: VelaColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Episode ${listen.episode.episodeNumber} · ${listen.episode.title}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: VelaColors.plum,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: VelaColors.blush,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.play_circle_fill_rounded,
                  color: VelaColors.plum,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
