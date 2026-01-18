import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/api/tracker.dart' as tracker;
import 'package:lahv/models/tracking/tracked_episode.dart';
import 'package:lahv/models/tracking/tracked_show.dart';
import 'package:lahv/models/tvmaze/episode.dart';
import 'package:lahv/models/tvmaze/image_tvmaze.dart';
import 'package:lahv/models/tvmaze/show.dart';
import 'package:lahv/providers/episode_progress_provider.dart';
import 'package:lahv/providers/next_episode_provider.dart';
import 'package:lahv/providers/show_progress_provider.dart';
import 'package:lahv/providers/tracking_actions_provider.dart';
import 'package:lahv/screens/show_detail_screen/show_detail_screen.dart';
import 'package:lahv/screens/show_episodes_screen/widgets/episode_carousel_sheet.dart';
import 'package:lahv/widgets/animations/drawn_checkmark.dart';
import 'package:lahv/widgets/cached_image.dart';

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
  // Episode Sheet - Shows ALL aired episodes from ALL seasons
  // ------------------------------------------------

  /// Helper to check if episode has aired
  bool _hasEpisodeAired(String? airdate, [String? airtime]) {
    if (airdate == null || airdate.isEmpty) {
      return false;
    }

    try {
      DateTime episodeDateTime;

      if (airtime != null && airtime.isNotEmpty) {
        final dateParts = airdate.split('-');
        final timeParts = airtime.split(':');

        if (dateParts.length != 3 || timeParts.isEmpty) {
          return false;
        }

        episodeDateTime = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          timeParts.length > 1 ? int.parse(timeParts[1]) : 0,
        );
      } else {
        episodeDateTime =
            DateTime.parse(airdate).add(const Duration(hours: 23, minutes: 59));
      }

      final now = DateTime.now();
      return episodeDateTime.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  Future<void> _showNextEpisodeSheet(
    BuildContext context,
    int showId,
    int season,
    int episode,
  ) async {
    try {
      final showImages = await tracker.fetchShowImages(showId);
      final seasons = await tracker.getSeasons(showId);

      // Check if seasons list is not empty
      if (seasons.isEmpty) return;

      // Fetch ALL episodes from ALL seasons
      final List<Episode> allEpisodes = [];
      for (final seasonData in seasons) {
        if (seasonData.id != null) {
          final seasonEpisodes = await tracker.getEpisodes(seasonData.id!);
          allEpisodes.addAll(seasonEpisodes);
        }
      }

      if (allEpisodes.isEmpty) return;

      // ✅ FIX: Filter out special episodes AND unaired episodes
      final validEpisodes = allEpisodes.where((ep) {
        final seasonNum = ep.season ?? 0;
        final episodeNum = ep.number ?? 0;

        // Must be a regular episode (not special)
        if (seasonNum == 0 || episodeNum == 0) return false;

        // Must have aired
        return _hasEpisodeAired(ep.airdate, ep.airtime);
      }).toList();

      if (validEpisodes.isEmpty) return;

      // Sort episodes by season and number
      validEpisodes.sort((a, b) {
        final aSeason = a.season!;
        final bSeason = b.season!;
        if (aSeason != bSeason) return aSeason.compareTo(bSeason);
        return a.number!.compareTo(b.number!);
      });

      // Find the index of the target episode (next episode to watch)
      final episodeIndex = validEpisodes.indexWhere(
        (e) => e.season == season && e.number == episode,
      );

      // If target episode not found, start from first valid episode
      final initialIndex = episodeIndex >= 0 ? episodeIndex : 0;

      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SafeArea(
          child: EpisodeCarouselSheet(
            showId: showId,
            episodes: validEpisodes,
            initialIndex: initialIndex,
            showImages: showImages,
          ),
        ),
      );
    } catch (_) {
      // Silently fail - this is a non-critical feature
    }
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
    final watchedAsync = ref.watch(episodeProgressProvider(show.showId));
    final nextAsync = ref.watch(nextEpisodeProvider(show.showId));
    final progressAsync = ref.watch(showProgressProvider(show.showId));

    final isMarkingWatched = ref.watch(_markingWatchedProvider(show.showId));

    /// Reset optimistic UI when new data arrives
    ref.listen<AsyncValue<ShowProgress>>(
      showProgressProvider(show.showId),
      (prev, curr) {
        final prevData = prev?.valueOrNull;
        final currData = curr.valueOrNull;

        if (prevData != null &&
            currData != null &&
            currData.watchedCount != prevData.watchedCount) {
          ref.read(_markingWatchedProvider(show.showId).notifier).state = false;
        }
      },
    );

    /// Show full green optimistic card
    if (isMarkingWatched) {
      return _markedWatchedTile();
    }

    // Handle loading and error states
    return watchedAsync.when(
      data: (watched) {
        return nextAsync.when(
          data: (next) {
            return progressAsync.when(
              data: (progress) {
                return _buildDismissible(
                  context,
                  ref,
                  watched,
                  next,
                  progress,
                );
              },
              loading: () => _buildLoadingTile(context),
              error: (_, __) => _buildTileContent(
                context,
                watched,
                next,
                null,
              ),
            );
          },
          loading: () => _buildLoadingTile(context),
          error: (_, __) => progressAsync.when(
            data: (progress) => _buildTileContent(
              context,
              watched,
              null,
              progress,
            ),
            loading: () => _buildLoadingTile(context),
            error: (_, __) => _buildTileContent(
              context,
              watched,
              null,
              null,
            ),
          ),
        );
      },
      loading: () => _buildLoadingTile(context),
      error: (_, __) => _buildTileContent(
        context,
        null,
        null,
        null,
      ),
    );
  }

  Widget _buildDismissible(
    BuildContext context,
    WidgetRef ref,
    List<TrackedEpisode>? watched,
    NextEpisode? next,
    ShowProgress? progress,
  ) {
    return Dismissible(
      key: ValueKey('show-${show.showId}'),
      direction:
          next != null ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: (_) async {
        if (next == null) return false;

        /// Immediate UI feedback
        ref.read(_markingWatchedProvider(show.showId).notifier).state = true;

        /// Haptic feedback
        HapticFeedback.mediumImpact();

        /// Trigger update
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

  Widget _buildLoadingTile(BuildContext context) {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 90,
              height: 135,
              child: show.posterUrl != null
                  ? CachedImage(url: show.posterUrl!)
                  : _placeholderPoster(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(context),
                const SizedBox(height: 6),
                const Text(
                  'Loading...',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                child: show.posterUrl != null
                    ? CachedImage(url: show.posterUrl!)
                    : _placeholderPoster(),
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
                _nextEpisodeInfo(next, progress),
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

  Widget _nextEpisodeInfo(NextEpisode? next, ShowProgress? progress) {
    // Case 1: No progress data yet (show just added)
    if (progress == null) {
      return const Text(
        'Loading...',
        style: TextStyle(fontSize: 13, color: Colors.grey),
      );
    }

    // Case 2: Show completed (all episodes watched)
    if (next == null) {
      return const Text(
        'All caught up!',
        style: TextStyle(fontSize: 13, color: Colors.green),
      );
    }

    // Case 3: Show next episode to watch
    return Text(
      'Next: S${next.season.toString().padLeft(2, '0')}'
      'E${next.episode.toString().padLeft(2, '0')}',
      style: const TextStyle(fontSize: 13, color: Colors.white),
    );
  }

  Widget _progressBar(ShowProgress? progress, NextEpisode? next) {
    if (progress == null) return const SizedBox(height: 6);

    final remaining = progress.totalCount - progress.watchedCount;

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
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
            Text(
              remaining > 0 ? '$remaining left' : 'Completed',
              style: TextStyle(
                fontSize: 11,
                color: remaining > 0 ? Colors.white : Colors.green,
              ),
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
          'Episode Info',
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
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 90, height: 135),
              SizedBox(width: 12),
              Expanded(child: SizedBox()),
            ],
          ),
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
