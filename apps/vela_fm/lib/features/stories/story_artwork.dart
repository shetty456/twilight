import 'package:flutter/material.dart';

import '../../app.dart';

class StoryArtwork extends StatelessWidget {
  const StoryArtwork({super.key, this.thumbnail, this.borderRadius = 18});

  final String? thumbnail;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(thumbnail ?? '');
    final image = uri != null && (uri.scheme == 'https' || uri.scheme == 'http')
        ? Image.network(
            uri.toString(),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _ArtworkFallback(),
          )
        : const _ArtworkFallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox.expand(child: image),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [VelaColors.plum, Color(0xFFB77F89), VelaColors.apricot],
      ),
    ),
    child: Center(
      child: Icon(Icons.graphic_eq_rounded, size: 54, color: Color(0xCCFFF3EA)),
    ),
  );
}
