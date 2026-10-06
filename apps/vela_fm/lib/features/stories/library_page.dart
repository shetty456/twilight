import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../config/providers.dart';
import '../../stories/models/story_models.dart';
import 'series_page.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(productNameProvider);
    final stories = ref.watch(seriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(seriesProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const _WelcomeCard(),
            const SizedBox(height: 30),
            Text('Stories to settle into',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: VelaColors.ink, fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text('Choose a story and listen at your own pace.',
              style: TextStyle(color: VelaColors.plum)),
            const SizedBox(height: 20),
            ...stories.when(
              data: (series) => series.isEmpty
                  ? [const _Notice('Stories will appear here as soon as they are published.')]
                  : [for (final story in series) ...[
                      _SeriesCard(series: story),
                      const SizedBox(height: 14),
                    ]],
              loading: () => [const Center(child: Padding(
                padding: EdgeInsets.all(32), child: CircularProgressIndicator()))],
              error: (error, _) => [
                const _Notice('Could not load stories. Check your connection and try again.'),
                TextButton(
                  onPressed: () => ref.invalidate(seriesProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) => Container(
    height: 178,
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF74516E), Color(0xFFB77F89), Color(0xFFE5AE94)],
      ),
    ),
    child: Stack(children: [
      const Positioned(right: -6, top: -14,
        child: Icon(Icons.nights_stay_rounded, size: 120, color: Color(0x44FFF4E8))),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text('A MOMENT FOR YOU', style: TextStyle(
            color: Color(0xFFFFE3CF), letterSpacing: 2.2,
            fontSize: 11, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 9),
          Text('Let the world slow down.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white, fontWeight: FontWeight.w600,
            )),
          const SizedBox(height: 4),
          const Text('Press play. Make this time yours.',
            style: TextStyle(color: Color(0xFFFFF1E7))),
        ],
      ),
    ]),
  );
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({required this.series});
  final StorySeries series;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => SeriesPage(series: series),
      )),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(children: [
          Container(
            width: 82, height: 92,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [
                Color(0xFFE8C8BE), Color(0xFFAF8FAA),
              ]),
            ),
            child: const Icon(Icons.auto_stories_rounded,
              size: 38, color: Color(0xFFFDF7F0)),
          ),
          const SizedBox(width: 17),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(series.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: VelaColors.ink)),
              const SizedBox(height: 7),
              Text(series.description?.isNotEmpty == true
                    ? series.description! : 'A story waiting for you.',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: VelaColors.plum, height: 1.35)),
            ],
          )),
          const Icon(Icons.chevron_right_rounded, color: VelaColors.plum),
        ]),
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: VelaColors.blush,
      borderRadius: BorderRadius.circular(18)),
    child: Text(message, style: const TextStyle(color: VelaColors.ink)),
  );
}
