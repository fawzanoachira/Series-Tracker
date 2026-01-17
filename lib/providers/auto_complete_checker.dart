import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/api/tracker.dart' as tracker;
import 'package:lahv/models/tracking/tracked_show.dart';
import 'package:lahv/models/tvmaze/episode.dart';
import 'package:lahv/providers/core_providers.dart';
import 'package:lahv/providers/episode_progress_provider.dart';
import 'package:lahv/providers/tracked_shows_provider.dart';

/// Checks if a show should be marked as completed and updates it automatically
Future<void> checkAndUpdateShowStatus(WidgetRef ref, int showId) async {
  try {
    // Get the tracked show
    final showDao = ref.read(showDaoProvider);
    final trackedShow = await showDao.getShow(showId);

    if (trackedShow == null ||
        trackedShow.status == TrackedShowStatus.completed) {
      return; // Show not tracked or already completed
    }

    // Get all episodes for the show
    final seasons = await tracker.getSeasons(showId);
    final List<Episode> allEpisodes = [];

    for (final season in seasons) {
      if (season.id != null) {
        final seasonEpisodes = await tracker.getEpisodes(season.id!);
        allEpisodes.addAll(seasonEpisodes);
      }
    }

    if (allEpisodes.isEmpty) return;

    // Get watched episodes
    final watchedEpisodes =
        await ref.read(episodeProgressProvider(showId).future);

    // Create set of watched episode keys
    final watchedSet =
        watchedEpisodes.map((e) => '${e.season}-${e.episode}').toSet();

    // Check if all episodes are watched
    final allWatched = allEpisodes.every((ep) {
      final key = '${ep.season ?? 0}-${ep.number ?? 0}';
      return watchedSet.contains(key);
    });

    // Update status if all watched
    if (allWatched && trackedShow.status != TrackedShowStatus.completed) {
      await showDao.updateStatus(showId, TrackedShowStatus.completed);
      ref.invalidate(trackedShowsProvider);
    }
  } catch (e) {
    // Silently fail - this is a background check
  }
}
