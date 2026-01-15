import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:series_tracker/models/tvmaze/episode.dart';
import 'package:series_tracker/models/tvmaze/show_image.dart';
import 'package:series_tracker/navigation/fade_scale_route.dart';
import 'package:series_tracker/screens/show_episodes_screen/widgets/episode_image_viewer.dart';
import 'package:series_tracker/utils/image_preoloader.dart';
import 'package:series_tracker/widgets/cached_image.dart';

import 'package:series_tracker/providers/is_episode_watched_provider.dart';
import 'package:series_tracker/providers/tracking_actions_provider.dart';

class EpisodeDetailSheet extends ConsumerStatefulWidget {
  final int showId;
  final Episode episode;
  final List<ShowImage>? showImages;

  const EpisodeDetailSheet({
    super.key,
    required this.showId,
    required this.episode,
    this.showImages,
  });

  @override
  ConsumerState<EpisodeDetailSheet> createState() => _EpisodeDetailSheetState();
}

class _EpisodeDetailSheetState extends ConsumerState<EpisodeDetailSheet> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isWatched = ref.watch(
      isEpisodeWatchedProvider((
        showId: widget.showId,
        season: widget.episode.season!,
        episode: widget.episode.number!,
      )),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dragHandle(),
          const SizedBox(height: 12),
          _imageSection(context),
          const SizedBox(height: 12),
          _title(context),
          const SizedBox(height: 4),
          _meta(context),
          const SizedBox(height: 12),
          _watchAction(isWatched),
          const SizedBox(height: 12),
          _summary(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _watchAction(bool isWatched) {
    return FilledButton.icon(
      icon: Icon(
        isWatched ? Icons.check_circle : Icons.circle_outlined,
      ),
      label: Text(
        isWatched ? 'Marked as watched' : 'Mark as watched',
      ),
      onPressed: () {
        final actions = ref.read(trackingActionsProvider.notifier);

        if (isWatched) {
          actions.markEpisodeUnwatched(
            showId: widget.showId,
            season: widget.episode.season!,
            episode: widget.episode.number!,
          );
        } else {
          actions.markEpisodeWatched(
            showId: widget.showId,
            season: widget.episode.season!,
            episode: widget.episode.number!,
          );
        }
      },
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

  Widget _imageSection(BuildContext context) {
    final image = widget.episode.image;

    if (image?.medium != null) {
      return GestureDetector(
        onTapDown: (_) {
          if (image.original != null) {
            preloadImageUrl(image.original!);
          }
        },
        onTap: () {
          if (image.original == null) return;

          Navigator.of(context).push(
            FadeScaleRoute(
              page: EpisodeImageViewer(
                imageUrl: image.original!,
              ),
            ),
          );
        },
        child: CachedImage(
          url: image!.medium!,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    final fallback =
        widget.showImages?.isNotEmpty == true ? widget.showImages!.first : null;

    if (fallback != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            CachedImage(
              url: fallback.url,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.black.withValues(alpha: (0.35 * 255)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox(height: 140);
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
      'Season ${widget.episode.season} · '
      'Episode ${widget.episode.number} · '
      '${widget.episode.runtime ?? '-'} min',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  Widget _summary(BuildContext context) {
    final raw = widget.episode.summary;
    if (raw == null || raw.isEmpty) return const SizedBox();

    final text = raw.replaceAll(RegExp(r'<[^>]*>'), '');
    final bool showToggle = text.length > 140;

    final displayText =
        _expanded || !showToggle ? text : text.substring(0, 140);

    return Text.rich(
      TextSpan(
        text: displayText,
        style: Theme.of(context).textTheme.bodyMedium,
        children: showToggle
            ? [
                TextSpan(
                  text: _expanded ? ' show less' : '... read more',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                ),
              ]
            : [],
      ),
    );
  }
}
