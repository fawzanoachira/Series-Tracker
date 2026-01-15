import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/api/tracker.dart' as tracker;
import 'package:series_tracker/models/tracking/tracked_episode.dart';
import 'package:series_tracker/models/tracking/tracked_show.dart';
import 'package:series_tracker/models/tvmaze/image_tvmaze.dart';
import 'package:series_tracker/models/tvmaze/show.dart';
import 'package:series_tracker/providers/episode_progress_provider.dart';
import 'package:series_tracker/providers/next_episode_provider.dart';
import 'package:series_tracker/providers/show_progress_provider.dart';
import 'package:series_tracker/providers/tracking_actions_provider.dart';
import 'package:series_tracker/screens/show_detail_screen/show_detail_screen.dart';
import 'package:series_tracker/screens/show_episodes_screen/widgets/episode_carousel_sheet.dart';
import 'package:series_tracker/widgets/animations/drawn_checkmark.dart';

/// --------------------------------------------
/// Optimistic UI state for swipe → watched
/// --------------------------------------------
final _markingWatchedProvider =
    StateProvider.family<bool, int>((ref, showId) => false);

class TrackedShowListTile extends ConsumerWidget {
  final TrackedShow show;

  const TrackedShowListTile({
    super.key,
    required this.show,
  });

  // ------------------------------------------------
  // Navigation
  // ------------------------------------------------

  void _navigateToShowDetail(BuildContext context) {
    final showModel = Show(
      id: show.showId,
      name: show.name,
      image:
          show.posterUrl != null ? ImageTvmaze(medium: show.posterUrl!) : null,
      summary: '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShowDetailScreen(show: showModel),
      ),
    );
  }

  // ------------------------------------------------
  // Episode Sheet
  // ------------------------------------------------

  Future<void> _showNextEpisodeSheet(
    BuildContext context,
    int showId,
    int season,
    int episode,
  ) async {
    try {
      final showImages = await tracker.fetchShowImages(showId);
      final seasons = await tracker.getSeasons(showId);

      final targetSeason = seasons.firstWhere(
        (s) => s.number == season,
        orElse: () => seasons.first,
      );

      final episodes = await tracker.getEpisodes(targetSeason.id!);
      final episodeIndex = episodes.indexWhere((e) => e.number == episode);

      if (episodeIndex == -1 || !context.mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => EpisodeCarouselSheet(
          showId: showId,
          episodes: episodes,
          initialIndex: episodeIndex,
          showImages: showImages,
        ),
      );
    } catch (_) {}
  }

  // ------------------------------------------------
  // Mark watched
  // ------------------------------------------------

  Future<void> _markNextEpisodeWatched(
    WidgetRef ref,
    int showId,
    int season,
    int episode,
  ) async {
    await ref.read(trackingActionsProvider.notifier).markEpisodeWatched(
          showId: showId,
          season: season,
          episode: episode,
        );
  }

  // ------------------------------------------------
  // Build
  // ------------------------------------------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = ref.watch(
      episodeProgressProvider(show.showId).select((a) => a.valueOrNull),
    );

    final next = ref.watch(
      nextEpisodeProvider(show.showId).select((a) => a.valueOrNull),
    );

    final progress = ref.watch(
      showProgressProvider(show.showId).select((a) => a.valueOrNull),
    );

    final isMarkingWatched = ref.watch(_markingWatchedProvider(show.showId));

    /// Reset optimistic UI **only when new data arrives**
    ref.listen<ShowProgress?>(
      showProgressProvider(show.showId).select((a) => a.valueOrNull),
      (prev, curr) {
        if (prev != null &&
            curr != null &&
            curr.watchedCount != prev.watchedCount) {
          ref.read(_markingWatchedProvider(show.showId).notifier).state = false;
        }
      },
    );

    /// Show full green optimistic card
    if (isMarkingWatched) {
      return _markedWatchedTile();
    }

    return Dismissible(
      key: ValueKey('${show.showId}-${next?.season}-${next?.episode}'),
      direction:
          next != null ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: (_) async {
        if (next == null) return false;

        /// 1️⃣ Immediate UI feedback
        ref.read(_markingWatchedProvider(show.showId).notifier).state = true;

        /// 🔔 Haptic feedback
        HapticFeedback.mediumImpact();

        /// 2️⃣ Trigger update
        await _markNextEpisodeWatched(
          ref,
          show.showId,
          next.season,
          next.episode,
        );

        return false;
      },
      background: _swipeWatchedBackground(),
      child: _buildTileContent(
        context,
        watched,
        next,
        progress,
      ),
    );
  }

  // ------------------------------------------------
  // Tile Content
  // ------------------------------------------------

  Widget _buildTileContent(
    BuildContext context,
    List<TrackedEpisode>? watched,
    NextEpisode? next,
    ShowProgress? progress,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _navigateToShowDetail(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 90,
                height: 135,
                child: Image.network(
                  show.posterUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderPoster(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(context),
                const SizedBox(height: 6),
                _lastWatched(watched),
                const SizedBox(height: 10),
                _progressBar(progress, next),
                const SizedBox(height: 10),
                _nextAction(context, next),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------
  // Sub widgets
  // ------------------------------------------------

  Widget _title(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToShowDetail(context),
      child: Text(
        show.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _lastWatched(List<TrackedEpisode>? watched) {
    if (watched == null || watched.isEmpty) {
      return const Text(
        'Not started yet',
        style: TextStyle(fontSize: 13, color: Colors.white60),
      );
    }

    final last = watched.last;
    return Text(
      'S${last.season.toString().padLeft(2, '0')}'
      'E${last.episode.toString().padLeft(2, '0')}',
      style: const TextStyle(fontSize: 13, color: Colors.white60),
    );
  }

  Widget _progressBar(ShowProgress? progress, NextEpisode? next) {
    if (progress == null) return const SizedBox(height: 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: progress.percentage,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation(
                Color(0xFF8B5CF6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.watchedCount}/${progress.totalCount}',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
            if (next != null)
              Text(
                '${progress.totalCount - progress.watchedCount} left',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
          ],
        ),
      ],
    );
  }

  Widget _nextAction(BuildContext context, NextEpisode? next) {
    if (next == null) return _completedBadge();

    return InkWell(
      onTap: () => _showNextEpisodeSheet(
        context,
        show.showId,
        next.season,
        next.episode,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'View Next',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------
  // UI helpers
  // ------------------------------------------------

  Widget _markedWatchedTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      height: 151,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Keeps exact tile size
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 90, height: 135),
              SizedBox(width: 12),
              Expanded(child: SizedBox()),
            ],
          ),

          // ✔ Tick pop
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1.0),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: const DrawnCheckmark(
              size: 80,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _completedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 4),
          Text(
            'Completed',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _swipeWatchedBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.green.withValues(alpha: 0.3),
            Colors.green.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 32,
      ),
    );
  }

  Widget _placeholderPoster() {
    return Container(
      color: Colors.grey[850],
      child: const Icon(Icons.tv_rounded, color: Colors.white24, size: 40),
    );
  }
}
