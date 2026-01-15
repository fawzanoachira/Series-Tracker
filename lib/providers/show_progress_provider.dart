import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/api/tracker.dart' as tracker;
import 'episode_progress_provider.dart';

class ShowProgress {
  final int watchedCount;
  final int totalCount;

  const ShowProgress({
    required this.watchedCount,
    required this.totalCount,
  });

  double get percentage => totalCount == 0 ? 0.0 : watchedCount / totalCount;
  bool get isComplete => totalCount > 0 && watchedCount == totalCount;
}

/// Provider that calculates the overall show progress by fetching all episodes from API
final showProgressProvider =
    FutureProvider.family<ShowProgress, int>((ref, showId) async {
  try {
    // Get watched episodes
    final watchedEpisodes =
        await ref.watch(episodeProgressProvider(showId).future);

    // Fetch all seasons and episodes from API
    final seasons = await tracker.getSeasons(showId);
    int totalEpisodes = 0;

    for (final season in seasons) {
      if (season.id != null) {
        final episodes = await tracker.getEpisodes(season.id!);
        totalEpisodes += episodes.length;
      }
    }

    return ShowProgress(
      watchedCount: watchedEpisodes.length,
      totalCount: totalEpisodes,
    );
  } catch (e) {
    // Return empty progress on error
    return const ShowProgress(watchedCount: 0, totalCount: 0);
  }
});
