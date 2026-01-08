import 'package:flutter/material.dart';
import 'package:series_tracker/widgets/cached_image.dart';

class EpisodeImageViewer extends StatelessWidget {
  final String imageUrl;

  const EpisodeImageViewer({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: CachedImage(
                url: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
