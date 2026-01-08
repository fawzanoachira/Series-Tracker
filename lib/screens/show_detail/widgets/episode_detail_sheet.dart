import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/episode.dart';
import 'package:series_tracker/models/tvmaze/show_image.dart';

class EpisodeDetailSheet extends StatefulWidget {
  final Episode episode;
  final List<ShowImage>? showImages;

  const EpisodeDetailSheet({
    super.key,
    required this.episode,
    this.showImages,
  });

  @override
  State<EpisodeDetailSheet> createState() => _EpisodeDetailSheetState();
}

class _EpisodeDetailSheetState extends State<EpisodeDetailSheet> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dragHandle(),
          const SizedBox(height: 12),
          _imageSection(),
          const SizedBox(height: 12),
          _title(context),
          const SizedBox(height: 4),
          _meta(context),
          const SizedBox(height: 12),
          _summary(context),
        ],
      ),
    );
  }

  Widget _dragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _imageSection() {
    final episodeImage = widget.episode.image?.medium;

    // 1️⃣ Episode image (preferred)
    if (episodeImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          episodeImage,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    // 2️⃣ Blurred show banner fallback
    final fallback =
        widget.showImages?.isNotEmpty == true ? widget.showImages!.first : null;

    if (fallback != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.network(
              fallback.url, // ✅ FIXED
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                ),
              ),
            ),
            const Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.tv,
                  size: 48,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3️⃣ Absolute fallback
    return SizedBox(
      height: 150,
      child: Center(
        child: Icon(
          Icons.tv,
          size: 40,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _title(BuildContext context) {
    return Text(
      widget.episode.name ?? 'Episode',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _meta(BuildContext context) {
    return Text(
      'Season ${widget.episode.season} · Episode ${widget.episode.number} · ${widget.episode.runtime ?? '-'} min',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  Widget _summary(BuildContext context) {
    final raw = widget.episode.summary;
    if (raw == null || raw.isEmpty) return const SizedBox();

    final text = raw.replaceAll(RegExp(r'<[^>]*>'), '');
    const limit = 140;

    final visibleText = _expanded || text.length <= limit
        ? text
        : '${text.substring(0, limit)}…';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(visibleText),
        if (text.length > limit)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
