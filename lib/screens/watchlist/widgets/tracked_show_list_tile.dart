import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/api/tracker.dart' as tracker;
import 'package:series_tracker/models/tracking/tracked_show.dart';
import 'package:series_tracker/models/tvmaze/image_tvmaze.dart';
import 'package:series_tracker/models/tvmaze/show.dart';
import 'package:series_tracker/providers/episode_progress_provider.dart';
import 'package:series_tracker/providers/next_episode_provider.dart';
import 'package:series_tracker/providers/show_progress_provider.dart';
import 'package:series_tracker/providers/tracking_actions_provider.dart';
import 'package:series_tracker/screens/show_detail_screen/show_detail_screen.dart';
import 'package:series_tracker/screens/show_episodes_screen/widgets/episode_detail_sheet.dart';

class TrackedShowListTile extends ConsumerWidget {
  final TrackedShow show;

  const TrackedShowListTile({
    super.key,
    required this.show,
  });

  Future<void> _showNextEpisodeSheet(
    BuildContext context,
    WidgetRef ref,
    int showId,
    int season,
    int episode,
  ) async {
    try {
      // Fetch all seasons to find the right one
      final seasons = await tracker.getSeasons(showId);
      final targetSeason = seasons.firstWhere(
        (s) => s.number == season,
        orElse: () => seasons.first,
      );

      // Fetch episodes for that season
      final episodes = await tracker.getEpisodes(targetSeason.id!);

      // Find the target episode index
      final episodeIndex = episodes.indexWhere(
        (e) => e.number == episode,
      );

      if (episodeIndex == -1) return;

      // Show the episode detail sheet
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => EpisodeDetailSheet(
            showId: showId,
            episode: episodes[episodeIndex],
          ),
        );
      }
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }

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

  Future<void> _markNextEpisodeWatched(
    WidgetRef ref,
    int showId,
    int season,
    int episode,
  ) async {
    final actions = ref.read(trackingActionsProvider.notifier);
    await actions.markEpisodeWatched(
      showId: showId,
      season: season,
      episode: episode,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchedAsync = ref.watch(episodeProgressProvider(show.showId));
    final nextAsync = ref.watch(nextEpisodeProvider(show.showId));
    final progressAsync = ref.watch(showProgressProvider(show.showId));

    return nextAsync.when(
      data: (next) {
        // Only make dismissible if there's a next episode
        if (next == null) {
          return _buildTileContent(
            context,
            ref,
            watchedAsync,
            nextAsync,
            progressAsync,
          );
        }

        return Dismissible(
          key: Key('${show.showId}-${next.season}-${next.episode}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            // Mark as watched
            await _markNextEpisodeWatched(
              ref,
              show.showId,
              next.season,
              next.episode,
            );

            // Don't actually dismiss the tile
            return false;
          },
          background: Container(
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
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
                SizedBox(height: 4),
                Text(
                  'Watched',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          child: _buildTileContent(
            context,
            ref,
            watchedAsync,
            nextAsync,
            progressAsync,
          ),
        );
      },
      loading: () => _buildTileContent(
        context,
        ref,
        watchedAsync,
        nextAsync,
        progressAsync,
      ),
      error: (_, __) => _buildTileContent(
        context,
        ref,
        watchedAsync,
        nextAsync,
        progressAsync,
      ),
    );
  }

  Widget _buildTileContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue watchedAsync,
    AsyncValue nextAsync,
    AsyncValue progressAsync,
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
          // Smaller Poster - tappable to navigate
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

          // Content on the right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show Title - tappable to navigate
                GestureDetector(
                  onTap: () => _navigateToShowDetail(context),
                  child: Text(
                    show.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 6),

                // Last watched episode info
                watchedAsync.when(
                  data: (watchedEpisodes) {
                    if (watchedEpisodes.isEmpty) {
                      return const Text(
                        'Not started yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      );
                    }

                    final lastWatched = watchedEpisodes.last;
                    return Text(
                      'S${lastWatched.season.toString().padLeft(2, '0')}'
                      'E${lastWatched.episode.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 10),

                // Progress bar
                progressAsync.when(
                  data: (progress) {
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
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF8B5CF6), // Purple color
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
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                            nextAsync.when(
                              data: (next) {
                                if (next == null) {
                                  return const SizedBox.shrink();
                                }
                                final remaining =
                                    progress.totalCount - progress.watchedCount;
                                return Text(
                                  '$remaining left',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54,
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.grey[800],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 10),

                // View Next Button
                nextAsync.when(
                  data: (next) {
                    if (next == null) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
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

                    return InkWell(
                      onTap: () => _showNextEpisodeSheet(
                        context,
                        ref,
                        show.showId,
                        next.season,
                        next.episode,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Next',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
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
