import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';

import '../../app.dart';
import '../../config/providers.dart';
import 'series_page.dart';
import 'story_artwork.dart';

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
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: AppTextField(
              hint: 'Titles and stories',
              prefixIcon: const Icon(Icons.search_rounded),
              autofocus: true,
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
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 18,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SeriesPage(series: item),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: StoryArtwork(
                                  thumbnail: item.thumbnail,
                                  borderRadius: 14,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: VelaColors.ink,
                                  fontWeight: FontWeight.w700,
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
              loading: () => const Center(child: CircularProgressIndicator()),
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
    );
  }
}
