import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';

import '../../app.dart';
import '../../config/providers.dart';
import '../../stories/models/story_models.dart';
import '../listener/listener_library.dart';
import 'episode_page.dart';
import 'story_artwork.dart';
import 'story_loading.dart';
import 'story_request_error.dart';

class SeriesPage extends ConsumerWidget {
  const SeriesPage({super.key, required this.series});
  final StorySeries series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodes = ref.watch(episodesProvider(series.id));
    final libraryState = ref.watch(listenerLibraryProvider);
    final saved = libraryState.valueOrNull?.isSaved(series.id) ?? false;
    return Scaffold(
      appBar: AppBar(toolbarHeight: 48, leading: const BackButton()),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          56 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          _StoryOverview(
            title: series.title,
            description: series.description?.trim().isNotEmpty == true
                ? series.description!.trim()
                : 'A story to enjoy one episode at a time.',
            thumbnail: series.thumbnailUrl ?? series.thumbnail,
          ),
          const SizedBox(height: 24),
          if (libraryState.hasError) ...[
            const AppMessageBox(
              message: 'Your library is unavailable. Saving is paused.',
              kind: AppMessageKind.warning,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => ref.invalidate(listenerLibraryProvider),
                child: const Text('Retry library'),
              ),
            ),
            const SizedBox(height: 16),
          ],
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
                    onPressed: libraryState.hasError
                        ? null
                        : () => ref
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
              onPressed: libraryState.hasError
                  ? null
                  : () => ref
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
                ? [
                    const AppEmptyState(
                      title: 'No episodes yet',
                      description: 'Episodes will appear here when published.',
                      icon: Icons.headphones_outlined,
                    ),
                  ]
                : [
                    for (final episode in items) ...[
                      Material(
                        color: VelaColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
            loading: () => [const EpisodeListSkeleton()],
            error: (error, _) => [
              StoryRequestError(
                error: error,
                subject: 'episodes',
                onRetry: () => ref.invalidate(episodesProvider(series.id)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoryOverview extends StatefulWidget {
  const _StoryOverview({
    required this.title,
    required this.description,
    required this.thumbnail,
  });

  final String title;
  final String description;
  final String? thumbnail;

  @override
  State<_StoryOverview> createState() => _StoryOverviewState();
}

class _StoryOverviewState extends State<_StoryOverview> {
  bool _expanded = false;

  static const _descriptionStyle = TextStyle(
    fontSize: 14,
    height: 1.4,
    color: VelaColors.plum,
  );

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 80,
        height: 100,
        child: StoryArtwork(thumbnail: widget.thumbnail, borderRadius: 10),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: VelaColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final painter = TextPainter(
                  text: TextSpan(
                    text: widget.description,
                    style: _descriptionStyle,
                  ),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  maxLines: 3,
                )..layout(maxWidth: constraints.maxWidth);
                final hasOverflow = painter.didExceedMaxLines;
                painter.dispose();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.description,
                      maxLines: _expanded ? null : 3,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                      style: _descriptionStyle,
                    ),
                    if (hasOverflow)
                      TextButton(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          alignment: Alignment.centerLeft,
                        ),
                        child: Text(_expanded ? 'Read less' : 'Read more'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ],
  );
}
