import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';

import '../../app.dart';
import '../../config/providers.dart';
import 'series_page.dart';
import 'story_artwork.dart';
import 'story_loading.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(seriesProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: AppTextField(
                hint: 'Search stories',
                prefixIcon: const Icon(Icons.search_rounded),
                autofocus: false,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ),
            Expanded(
              child: stories.when(
                data: (series) {
                  final query = _query.toLowerCase();
                  final results = series
                      .where(
                        (item) =>
                            item.title.toLowerCase().contains(query) ||
                            (item.description ?? '').toLowerCase().contains(
                              query,
                            ),
                      )
                      .toList();
                  if (results.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _query.isEmpty
                              ? 'No stories available yet.'
                              : 'No stories match your search.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: VelaColors.plum),
                        ),
                      ),
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth < 500 ? 2 : 3;
                      final tileWidth =
                          (constraints.maxWidth - 40 - 14 * (columns - 1)) /
                          columns;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: tileWidth * 5 / 4 + 48,
                        ),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SeriesPage(series: item),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 4 / 5,
                                  child: StoryArtwork(
                                    thumbnail:
                                        item.thumbnailUrl ?? item.thumbnail,
                                    borderRadius: 10,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.title,
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
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const StoryGridSkeleton(),
                error: (_, __) => Center(
                  child: AppButton(
                    label: 'Try again',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => ref.invalidate(seriesProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
