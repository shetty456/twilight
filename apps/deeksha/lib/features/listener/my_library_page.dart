import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';

import '../../app.dart';
import '../stories/episode_page.dart';
import '../stories/series_page.dart';
import '../stories/story_artwork.dart';
import '../stories/story_cards.dart';
import 'listener_library.dart';

class MyLibraryPage extends ConsumerWidget {
  const MyLibraryPage({super.key, required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(listenerLibraryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Library')),
      body: library.when(
        data: (value) {
          if (value.saved.isEmpty && value.recent.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bookmarks_outlined,
                      size: 62,
                      color: VelaColors.plum,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Your stories live here',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: VelaColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Save a series or start listening to find it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: VelaColors.plum),
                    ),
                    const SizedBox(height: 22),
                    AppButton(label: 'Explore stories', onPressed: onExplore),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              if (value.recent.isNotEmpty) ...[
                Text(
                  'Continue listening',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: VelaColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                for (final listen in value.recent) ...[
                  RecentListenCard(
                    listen: listen,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EpisodePage(
                          series: listen.series,
                          episode: listen.episode,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 20),
              ],
              Text(
                'Saved series',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: VelaColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              if (value.saved.isEmpty)
                const Text(
                  'Tap the bookmark on a series to save it here.',
                  style: TextStyle(color: VelaColors.plum),
                ),
              for (final series in value.saved) ...[
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: SizedBox(
                      width: 64,
                      height: 64,
                      child: StoryArtwork(
                        thumbnail: series.thumbnailUrl ?? series.thumbnail,
                        borderRadius: 10,
                      ),
                    ),
                    title: Text(
                      series.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: VelaColors.ink,
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove ${series.title} from My Library',
                      onPressed: () => ref
                          .read(listenerLibraryProvider.notifier)
                          .toggleSaved(series),
                      icon: const Icon(
                        Icons.bookmark_rounded,
                        color: VelaColors.plum,
                      ),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SeriesPage(series: series),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Could not open My Library.')),
      ),
    );
  }
}
