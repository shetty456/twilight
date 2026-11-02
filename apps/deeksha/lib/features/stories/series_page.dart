import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';

import '../../app.dart';
import '../../config/providers.dart';
import '../../stories/models/story_models.dart';
import '../listener/listener_library.dart';
import 'episode_page.dart';
import 'story_artwork.dart';

class SeriesPage extends ConsumerWidget {
  const SeriesPage({super.key, required this.series});
  final StorySeries series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodes = ref.watch(episodesProvider(series.id));
    final saved =
        ref.watch(listenerLibraryProvider).valueOrNull?.isSaved(series.id) ??
        false;
    return Scaffold(
      appBar: AppBar(title: const Text('Story details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          SizedBox(
            height: 280,
            child: StoryArtwork(
              thumbnail: series.thumbnailUrl ?? series.thumbnail,
              borderRadius: 24,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            series.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: VelaColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            series.description?.isNotEmpty == true
                ? series.description!
                : 'A story to enjoy one episode at a time.',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: VelaColors.plum,
            ),
          ),
          const SizedBox(height: 24),
          if (episodes.valueOrNull?.isNotEmpty == true) ...[
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Start story',
                    icon: Icons.play_arrow_rounded,
                    expanded: true,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EpisodePage(
                          episode: episodes.valueOrNull!.first,
                          series: series,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: IconButton.filledTonal(
                    tooltip: saved
                        ? 'Remove from My Library'
                        : 'Save to My Library',
                    onPressed: () => ref
                        .read(listenerLibraryProvider.notifier)
                        .toggleSaved(series),
                    icon: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_add_outlined,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ] else ...[
            AppButton(
              label: saved ? 'Remove from My Library' : 'Save to My Library',
              icon: saved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_add_outlined,
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: () => ref
                  .read(listenerLibraryProvider.notifier)
                  .toggleSaved(series),
            ),
            const SizedBox(height: 30),
          ],
          const Text(
            'Episodes',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: VelaColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          ...episodes.when(
            data: (items) => items.isEmpty
                ? [const Text('No episodes are published yet.')]
                : [
                    for (final episode in items) ...[
                      Material(
                        color: VelaColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          leading: SizedBox(
                            width: 58,
                            height: 58,
                            child: StoryArtwork(
                              thumbnail:
                                  series.thumbnailUrl ?? series.thumbnail,
                              borderRadius: 10,
                            ),
                          ),
                          title: Text(
                            '${episode.episodeNumber}. ${episode.title}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            episode.audioDuration != null &&
                                    episode.audioDuration! > 0
                                ? '${(episode.audioDuration! / 60).ceil()} min'
                                : episode.audioKey == null
                                ? 'Read episode'
                                : 'Listen',
                          ),
                          trailing: Icon(
                            episode.audioKey == null
                                ? Icons.menu_book_rounded
                                : Icons.play_circle_rounded,
                            color: VelaColors.apricot,
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  EpisodePage(episode: episode, series: series),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                    ],
                  ],
            loading: () => [
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
            error: (error, _) => [
              const Text('Could not load episodes.'),
              AppButton(
                label: 'Try again',
                variant: AppButtonVariant.secondary,
                onPressed: () => ref.invalidate(episodesProvider(series.id)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
