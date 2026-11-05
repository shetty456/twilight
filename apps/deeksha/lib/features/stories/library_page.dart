import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';

import '../../app.dart';
import '../../config/providers.dart';
import '../../stories/models/story_models.dart';
import '../listener/listener_library.dart';
import 'episode_page.dart';
import 'series_page.dart';
import 'story_artwork.dart';
import 'story_cards.dart';
import 'story_loading.dart';
import 'story_request_error.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _openSeries(BuildContext context, StorySeries series) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => SeriesPage(series: series)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(seriesProvider);
    final libraryState = ref.watch(listenerLibraryProvider);
    final library = libraryState.valueOrNull;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(seriesProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (libraryState.hasError)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    children: [
                      const AppMessageBox(
                        message:
                            'Your library is unavailable. Saving is paused.',
                        kind: AppMessageKind.warning,
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(listenerLibraryProvider),
                        child: const Text('Retry library'),
                      ),
                    ],
                  ),
                ),
              ...stories.when(
                data: (series) {
                  if (series.isEmpty) {
                    return [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.6,
                        child: const AppEmptyState(
                          title: 'No stories yet',
                          description:
                              'Stories will appear here as soon as they are published.',
                          icon: Icons.auto_stories_outlined,
                        ),
                      ),
                    ];
                  }
                  final recent = library?.recent ?? const <RecentListen>[];
                  final featured = _selectFeaturedStory(
                    series,
                    recent.map((item) => item.series.id).toSet(),
                  );
                  final otherStories = series
                      .where((item) => item.id != featured.id)
                      .toList();
                  final firstEpisode = ref
                      .watch(episodesProvider(featured.id))
                      .valueOrNull
                      ?.firstOrNull;
                  return [
                    if (recent.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const _SectionTitle('Continue listening'),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 114,
                          child: RecentListenCard(
                            listen: recent.first,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => EpisodePage(
                                  series: recent.first.series,
                                  episode: recent.first.episode,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _FeaturedStory(
                        series: featured,
                        saved: library?.isSaved(featured.id) ?? false,
                        onOpen: () => _openSeries(context, featured),
                        onStart: () {
                          if (firstEpisode == null) {
                            _openSeries(context, featured);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => EpisodePage(
                                  series: featured,
                                  episode: firstEpisode,
                                ),
                              ),
                            );
                          }
                        },
                        onSave: libraryState.hasError
                            ? null
                            : () => ref
                                  .read(listenerLibraryProvider.notifier)
                                  .toggleSaved(featured),
                      ),
                    ),
                    if (otherStories.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const _SectionTitle('More stories'),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth =
                              (constraints.maxWidth - 20 - 14 * 2) * 3 / 7;
                          return SizedBox(
                            height: cardWidth * 5 / 4 + 48,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: otherStories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) => StoryPosterCard(
                                width: cardWidth,
                                series: otherStories[index],
                                onTap: () =>
                                    _openSeries(context, otherStories[index]),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                  ];
                },
                loading: () => const [StoryHomeSkeleton()],
                error: (error, _) => [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: StoryRequestError(
                      error: error,
                      subject: 'stories',
                      onRetry: () => ref.invalidate(seriesProvider),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

StorySeries _selectFeaturedStory(
  List<StorySeries> series,
  Set<String> recentlyPlayedIds,
) {
  int score(StorySeries story) {
    final artwork = story.thumbnailUrl ?? story.thumbnail;
    final uri = Uri.tryParse(artwork ?? '');
    final hasArtwork =
        uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
    return (story.isFeatured ? 100 : 0) +
        (hasArtwork ? 10 : 0) +
        (story.description?.trim().isNotEmpty == true ? 2 : 0) +
        (recentlyPlayedIds.contains(story.id) ? 0 : 1);
  }

  var featured = series.first;
  var bestScore = score(featured);
  for (final story in series.skip(1)) {
    final candidateScore = score(story);
    if (candidateScore > bestScore) {
      featured = story;
      bestScore = candidateScore;
    }
  }
  return featured;
}

class _FeaturedStory extends StatelessWidget {
  const _FeaturedStory({
    required this.series,
    required this.saved,
    required this.onOpen,
    required this.onStart,
    required this.onSave,
  });

  final StorySeries series;
  final bool saved;
  final VoidCallback onOpen;
  final VoidCallback onStart;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: AspectRatio(
        aspectRatio: 5 / 6,
        child: ClipRRect(
          key: const ValueKey('featured-story'),
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              StoryArtwork(
                thumbnail: series.thumbnailUrl ?? series.thumbnail,
                borderRadius: 0,
              ),
              ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0x99000000),
                    Colors.black,
                  ],
                  stops: [0.0, 0.34, 0.78, 1.0],
                ).createShader(bounds),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                  child: StoryArtwork(
                    thumbnail: series.thumbnailUrl ?? series.thumbnail,
                    borderRadius: 0,
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x14000000),
                      Color(0x660F0B14),
                      Color(0xF719121D),
                    ],
                    stops: [0.22, 0.58, 1.0],
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(onTap: onOpen),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xB319121D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      'Featured',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (series.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        series.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFF7EDE9)),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        FilledButton.icon(
                          key: const ValueKey('featured-listen'),
                          onPressed: onStart,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text('Listen'),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(
                            tooltip: saved
                                ? 'Remove from My Library'
                                : 'Save to My Library',
                            onPressed: onSave,
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0x9919121D),
                              side: const BorderSide(color: Color(0x99FFFFFF)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: Icon(
                              saved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_add_outlined,
                            ),
                          ),
                        ),
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
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: VelaColors.ink,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
