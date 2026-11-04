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

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _openSeries(BuildContext context, StorySeries series) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => SeriesPage(series: series)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(seriesProvider);
    final library = ref.watch(listenerLibraryProvider).valueOrNull;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(seriesProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ...stories.when(
                data: (series) {
                  if (series.isEmpty) {
                    return const [
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: _HomeNotice(
                          'Stories will appear here as soon as they are published.',
                        ),
                      ),
                    ];
                  }
                  final featured = series.first;
                  final firstEpisode = ref
                      .watch(episodesProvider(featured.id))
                      .valueOrNull
                      ?.firstOrNull;
                  final recent = library?.recent ?? const [];
                  return [
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
                        onSave: () => ref
                            .read(listenerLibraryProvider.notifier)
                            .toggleSaved(featured),
                      ),
                    ),
                    if (recent.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const _SectionTitle('Continue listening'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 114,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: recent.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) => RecentListenCard(
                            width: 280,
                            listen: recent[index],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => EpisodePage(
                                  series: recent[index].series,
                                  episode: recent[index].episode,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    const _SectionTitle('Stories for you'),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth =
                            (constraints.maxWidth - 40 - 14 * 2) / 3;
                        return SizedBox(
                          height: cardWidth * 16 / 9 + 48,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: series.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                            itemBuilder: (context, index) => StoryPosterCard(
                              width: cardWidth,
                              series: series[index],
                              onTap: () => _openSeries(context, series[index]),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ];
                },
                loading: () => const [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
                error: (_, __) => [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const _HomeNotice(
                          'Could not load stories. Check your connection.',
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Try again',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => ref.invalidate(seriesProvider),
                        ),
                      ],
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
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 350,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          StoryArtwork(
            thumbnail: series.thumbnailUrl ?? series.thumbnail,
            borderRadius: 0,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000000),
                  Color(0x33000000),
                  Color(0xE522172A),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(onTap: onOpen),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FEATURED STORY',
                  style: TextStyle(
                    color: Color(0xFFFFD9C2),
                    letterSpacing: 1.8,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  series.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  series.description?.isNotEmpty == true
                      ? series.description!
                      : 'A story waiting for you.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF7EDE9),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Start story',
                        icon: Icons.play_arrow_rounded,
                        expanded: true,
                        onPressed: onStart,
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
                        onPressed: onSave,
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

class _HomeNotice extends StatelessWidget {
  const _HomeNotice(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: VelaColors.blush,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(message, style: const TextStyle(color: VelaColors.ink)),
  );
}
