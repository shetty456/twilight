import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';

import '../../app.dart';
import '../../config/providers.dart';
import '../../stories/models/story_models.dart';
import 'series_page.dart';
import 'story_artwork.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  String _query = '';

  void _open(StorySeries series) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => SeriesPage(series: series)));

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(seriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ref.watch(productNameProvider),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: [
            Text(
              'Find your next listen',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: VelaColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Stories for the moments that are yours.',
              style: TextStyle(color: VelaColors.plum),
            ),
            const SizedBox(height: 22),
            AppTextField(
              hint: 'Search stories',
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: (value) => setState(() => _query = value.trim()),
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: 28),
            ...stories.when(
              data: (series) {
                final matches = series.where((item) {
                  final query = _query.toLowerCase();
                  return item.title.toLowerCase().contains(query) ||
                      (item.description ?? '').toLowerCase().contains(query);
                }).toList();
                if (series.isEmpty) {
                  return [
                    const _Notice(
                      'Stories will appear here as soon as they are published.',
                    ),
                  ];
                }
                if (matches.isEmpty) {
                  return [
                    const _Notice(
                      'No stories match your search. Try another title or word.',
                    ),
                  ];
                }
                return [
                  if (_query.isEmpty) ...[
                    _FeaturedStory(
                      series: matches.first,
                      onTap: () => _open(matches.first),
                    ),
                    const SizedBox(height: 30),
                  ],
                  Text(
                    _query.isEmpty ? 'Explore stories' : 'Search results',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: VelaColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final story in matches) ...[
                    _SeriesCard(series: story, onTap: () => _open(story)),
                    const SizedBox(height: 12),
                  ],
                ];
              },
              loading: () => [
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
              error: (error, _) => [
                const _Notice(
                  'Could not load stories. Check your connection and try again.',
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Try again',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => ref.invalidate(seriesProvider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedStory extends StatelessWidget {
  const _FeaturedStory({required this.series, required this.onTap});
  final StorySeries series;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: VelaColors.blush,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FEATURED STORY',
          style: TextStyle(
            color: VelaColors.plum,
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 166,
          width: double.infinity,
          child: StoryArtwork(thumbnail: series.thumbnail),
        ),
        const SizedBox(height: 16),
        Text(
          series.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: VelaColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          series.description?.isNotEmpty == true
              ? series.description!
              : 'A story waiting for you.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: VelaColors.plum),
        ),
        const SizedBox(height: 18),
        AppButton(
          label: 'Explore story',
          icon: Icons.arrow_forward_rounded,
          onPressed: onTap,
          expanded: true,
        ),
      ],
    ),
  );
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({required this.series, required this.onTap});
  final StorySeries series;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 82,
              height: 92,
              child: StoryArtwork(
                thumbnail: series.thumbnail,
                borderRadius: 12,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: VelaColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    series.description?.isNotEmpty == true
                        ? series.description!
                        : 'A story waiting for you.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: VelaColors.plum, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: VelaColors.plum),
          ],
        ),
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
    decoration: BoxDecoration(
      color: VelaColors.blush,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(message, style: const TextStyle(color: VelaColors.ink)),
  );
}
