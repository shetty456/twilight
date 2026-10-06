import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../config/providers.dart';
import '../../stories/models/story_models.dart';
import 'episode_page.dart';

class SeriesPage extends ConsumerWidget {
  const SeriesPage({super.key, required this.series});
  final StorySeries series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodes = ref.watch(episodesProvider(series.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Series')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(colors: [
                Color(0xFFBA869C), Color(0xFFE9B9A3),
              ]),
            ),
            child: const Icon(Icons.auto_stories_rounded,
              size: 86, color: Color(0xFFFFF3EB)),
          ),
          const SizedBox(height: 24),
          Text(series.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: VelaColors.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(series.description?.isNotEmpty == true
                ? series.description! : 'A story to enjoy one episode at a time.',
            style: const TextStyle(fontSize: 16, height: 1.5,
              color: VelaColors.plum)),
          const SizedBox(height: 30),
          const Text('Episodes', style: TextStyle(fontSize: 21,
            fontWeight: FontWeight.w700, color: VelaColors.ink)),
          const SizedBox(height: 14),
          ...episodes.when(
            data: (items) => items.isEmpty
                ? [const Text('No episodes are published yet.')]
                : [for (final episode in items) ...[
                    Card(child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                      leading: CircleAvatar(
                        backgroundColor: VelaColors.blush,
                        foregroundColor: VelaColors.plum,
                        child: Text('${episode.episodeNumber}'),
                      ),
                      title: Text(episode.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(episode.episodeSummary?.isNotEmpty == true
                          ? episode.episodeSummary! : 'Open this episode',
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Icon(episode.audioKey == null
                          ? Icons.menu_book_rounded : Icons.play_circle_rounded,
                        color: VelaColors.plum),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => EpisodePage(episode: episode, seriesTitle: series.title),
                      )),
                    )),
                    const SizedBox(height: 9),
                  ]],
            loading: () => [const Center(child: Padding(
              padding: EdgeInsets.all(28), child: CircularProgressIndicator()))],
            error: (error, _) => [
              const Text('Could not load episodes.'),
              TextButton(
                onPressed: () => ref.invalidate(episodesProvider(series.id)),
                child: const Text('Try again'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
