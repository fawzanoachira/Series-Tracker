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

/// Provider that calculates show progress based on ONLY aired, valid episodes
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

    // ✅ FIX: Filter to only valid, aired episodes (exclude specials and unaired)
    final validAiredEpisodes = allEpisodes.where((ep) {
      final seasonNum = ep.season ?? 0;
      final episodeNum = ep.number ?? 0;

      // Must be a regular episode (not special - S00E00)
      if (seasonNum == 0 || episodeNum == 0) return false;

      // Must have aired
      return _hasEpisodeAired(ep.airdate, ep.airtime);
    }).toList();

    // If no valid aired episodes yet
    if (validAiredEpisodes.isEmpty) {
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

    // Count how many valid aired episodes are watched
    int watchedAiredCount = 0;
    for (final ep in validAiredEpisodes) {
      final key = '${ep.season!}-${ep.number!}';
      if (watchedSet.contains(key)) {
        watchedAiredCount++;
      }
    }

    final percentage = validAiredEpisodes.isNotEmpty
        ? watchedAiredCount / validAiredEpisodes.length
        : 0.0;

    return ShowProgress(
      watchedCount: watchedAiredCount,
      totalCount: validAiredEpisodes.length,
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
