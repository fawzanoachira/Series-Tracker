import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:series_tracker/models/tvmaze/episode.dart';
import 'package:series_tracker/models/tvmaze/show_image.dart';

class EpisodeDetailSheet extends StatefulWidget {
  final Episode episode;
  final List<ShowImage>? showImages; // banner images for fallback

  const EpisodeDetailSheet({
    super.key,
    required this.episode,
    this.showImages,
  });

  @override
  State<EpisodeDetailSheet> createState() => _EpisodeDetailSheetState();
}

class _EpisodeDetailSheetState extends State<EpisodeDetailSheet> {
  bool showFullSummary = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dragHandle(),
          const SizedBox(height: 12),
          _episodeImage(),
          const SizedBox(height: 12),
          _episodeTitle(context),
          const SizedBox(height: 6),
          _episodeMeta(context),
          const SizedBox(height: 12),
          _episodeSummary(context),
        ],
      ),
    );
  }

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade600,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _episodeImage() {
    final imageUrl = widget.episode.image?.medium;

    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 160, // less dominant
        ),
      );
    }

    // fallback: blurred banner
    if (widget.showImages != null && widget.showImages!.isNotEmpty) {
      final bannerUrl = widget.showImages!.first.url;
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.network(
              bannerUrl,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.tv,
                color: Colors.white54,
                size: 48,
              ),
            ),
          ],
        ),
      );
        }

    // fallback empty container
    return SizedBox(
      height: 160,
      child: Center(
        child: Icon(
          Icons.tv,
          size: 48,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _episodeTitle(BuildContext context) {
    return Text(
      widget.episode.name ?? 'Episode',
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: TextAlign.center,
    );
  }

  Widget _episodeMeta(BuildContext context) {
    return Text(
      'Season ${widget.episode.season} · Episode ${widget.episode.number} · ${widget.episode.runtime ?? "-"} min',
      style: Theme.of(context).textTheme.bodySmall,
      textAlign: TextAlign.center,
    );
  }

  Widget _episodeSummary(BuildContext context) {
    final summary = widget.episode.summary?.replaceAll(RegExp(r'<[^>]*>'), '');

    if (summary == null || summary.isEmpty) return const SizedBox();

    const previewLength = 120;

    if (summary.length <= previewLength) {
      return Text(summary, style: Theme.of(context).textTheme.bodyMedium);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            '${summary.substring(0, previewLength)}...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          secondChild: Text(
            summary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          crossFadeState: showFullSummary
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            setState(() {
              showFullSummary = !showFullSummary;
            });
          },
          child: Text(
            showFullSummary ? 'Show less' : 'Read more',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
