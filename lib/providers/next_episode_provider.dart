import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/api/tracker.dart' as tracker;
import 'package:lahv/models/tvmaze/episode.dart';
import 'episode_progress_provider.dart';

class NextEpisode {
  final int season;
  final int episode;

  const NextEpisode({
    required this.season,
    required this.episode,
  });
}

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

final nextEpisodeProvider =
    FutureProvider.family<NextEpisode?, int>((ref, showId) async {
  final episodesAsync = ref.watch(episodeProgressProvider(showId));

  return episodesAsync.when(
    data: (watchedEpisodes) async {
      // Fetch all episodes for this show from the API
      List<Episode> allEpisodes = [];

      try {
        // First get all seasons for the show
        final seasons = await tracker.getSeasons(showId);

        // Then fetch episodes for each season
        for (final season in seasons) {
          if (season.id != null) {
            final seasonEpisodes = await tracker.getEpisodes(season.id!);
            allEpisodes.addAll(seasonEpisodes);
          }
        }
      } catch (e) {
        // If API call fails, return null
        return null;
      }

      // ✅ FIX 1: Filter out special episodes (season 0 or episode 0)
      // ✅ FIX 2: Filter to only AIRED episodes
      final validEpisodes = allEpisodes.where((ep) {
        final seasonNum = ep.season ?? 0;
        final episodeNum = ep.number ?? 0;

        // Must be a regular episode (not special)
        if (seasonNum == 0 || episodeNum == 0) return false;

        // Must have aired
        return _hasEpisodeAired(ep.airdate, ep.airtime);
      }).toList();

      // Sort episodes
      validEpisodes.sort((a, b) {
        final aSeason = a.season ?? 0;
        final bSeason = b.season ?? 0;
        final aNumber = a.number ?? 0;
        final bNumber = b.number ?? 0;

        if (aSeason != bSeason) return aSeason.compareTo(bSeason);
        return aNumber.compareTo(bNumber);
      });

      // If no valid episodes exist yet
      if (validEpisodes.isEmpty) {
        return null; // Show is not ready (no aired episodes)
      }

      // If no episodes watched, return the first valid episode
      if (watchedEpisodes.isEmpty) {
        final firstEpisode = validEpisodes.first;
        return NextEpisode(
          season: firstEpisode.season!,
          episode: firstEpisode.number!,
        );
      }

      // Create a set of watched episodes for quick lookup
      final watchedSet =
          watchedEpisodes.map((e) => '${e.season}-${e.episode}').toSet();

      // Find the first unwatched, valid, aired episode
      for (final episode in validEpisodes) {
        final seasonNum = episode.season!;
        final episodeNum = episode.number!;
        final key = '$seasonNum-$episodeNum';

        if (!watchedSet.contains(key)) {
          return NextEpisode(
            season: seasonNum,
            episode: episodeNum,
          );
        }
      }

      // ✅ FIX 3: All AIRED episodes are watched = truly caught up!
      return null;
    },
    loading: () => null, // Show loading state, not fake episode
    error: (_, __) => null, // On error, show nothing
  );
});
