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
        colors: [Color(0xFF50344E), Color(0xFF251C38), Color(0xFF121C32)],
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 20,
          right: 28,
          child: Icon(Icons.auto_awesome, color: Color(0x88F0BD9D), size: 24),
        ),
        Positioned(
          bottom: 36,
          left: 28,
          child: Icon(Icons.star_rounded, color: Color(0x77F0BD9D), size: 16),
        ),
        Icon(Icons.nightlight_round, size: 78, color: VelaColors.apricot),
      ],
    ),
  );
}
