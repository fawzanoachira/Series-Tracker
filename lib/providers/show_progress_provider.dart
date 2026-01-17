import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/api/tracker.dart' as tracker;
import 'package:lahv/models/tvmaze/episode.dart';
import 'package:lahv/providers/core_providers.dart';
import 'package:lahv/providers/episode_tracking_revision_provider.dart';

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

class ShowProgress {
  final int watchedCount;
  final int totalCount; // Only aired episodes
  final double percentage;

  ShowProgress({
    required this.watchedCount,
    required this.totalCount,
    required this.percentage,
  });
}

/// Provider that calculates show progress based on ONLY aired episodes
final showProgressProvider =
    FutureProvider.family<ShowProgress, int>((ref, showId) async {
  // Watch the revision to rebuild when episodes are marked
  ref.watch(episodeTrackingRevisionProvider(showId));

  final repo = ref.read(trackingRepositoryProvider);

  try {
    // Get all episodes from API
    final seasons = await tracker.getSeasons(showId);
    final List<Episode> allEpisodes = [];

    for (final season in seasons) {
      if (season.id != null) {
        final seasonEpisodes = await tracker.getEpisodes(season.id!);
        allEpisodes.addAll(seasonEpisodes);
      }
    }

    if (allEpisodes.isEmpty) {
      return ShowProgress(
        watchedCount: 0,
        totalCount: 0,
        percentage: 0.0,
      );
    }

    // Filter to only aired episodes
    final airedEpisodes = allEpisodes.where((ep) {
      return _hasEpisodeAired(ep.airdate, ep.airtime);
    }).toList();

    // If no aired episodes yet
    if (airedEpisodes.isEmpty) {
      return ShowProgress(
        watchedCount: 0,
        totalCount: 0,
        percentage: 0.0,
      );
    }

    // Get watched episodes from database
    final watchedEpisodes = await repo.getEpisodesForShow(showId);

    // Create set of watched episode keys
    final watchedSet =
        watchedEpisodes.map((e) => '${e.season}-${e.episode}').toSet();

    // Count how many aired episodes are watched
    int watchedAiredCount = 0;
    for (final ep in airedEpisodes) {
      final key = '${ep.season ?? 0}-${ep.number ?? 0}';
      if (watchedSet.contains(key)) {
        watchedAiredCount++;
      }
    }

    final percentage = watchedAiredCount / airedEpisodes.length;

    return ShowProgress(
      watchedCount: watchedAiredCount,
      totalCount: airedEpisodes.length,
      percentage: percentage,
    );
  } catch (e) {
    return ShowProgress(
      watchedCount: 0,
      totalCount: 0,
      percentage: 0.0,
    );
  }
});
