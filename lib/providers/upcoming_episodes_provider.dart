import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/api/tracker.dart' as tracker;
import 'package:lahv/models/tracking/upcoming_episode.dart';
import 'package:lahv/models/tvmaze/episode.dart';
import 'package:lahv/providers/tracked_shows_provider.dart';

/// Cache for episodes by show ID to avoid repeated API calls
final _episodesCache = <int, List<Episode>>{};

/// Helper to check if episode has aired (considers airtime if available)
bool _hasEpisodeAired(String? airdate, [String? airtime]) {
  if (airdate == null || airdate.isEmpty) {
    return true; // No airdate = consider it aired (skip it)
  }

  try {
    DateTime episodeDateTime;

    if (airtime != null && airtime.isNotEmpty) {
      // Combine airdate and airtime
      final dateParts = airdate.split('-');
      final timeParts = airtime.split(':');

      if (dateParts.length != 3 || timeParts.isEmpty) {
        return true; // Invalid format = skip it
      }

      episodeDateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        timeParts.length > 1 ? int.parse(timeParts[1]) : 0,
      );
    } else {
      // Only airdate available, set to end of day
      episodeDateTime =
          DateTime.parse(airdate).add(const Duration(hours: 23, minutes: 59));
    }

    final now = DateTime.now();
    return episodeDateTime.isBefore(now);
  } catch (e) {
    return true; // Parsing error = skip it
  }
}

/// Provider that fetches upcoming episodes (unaired episodes only)
/// This shows the NEXT UNAIRED episode for each tracked show,
/// completely independent of watch status
final upcomingEpisodesProvider =
    FutureProvider<List<UpcomingEpisode>>((ref) async {
  final trackedShowsAsync = ref.watch(trackedShowsProvider);

  return trackedShowsAsync.when(
    data: (trackedShows) async {
      if (trackedShows.isEmpty) return [];

      final List<UpcomingEpisode> upcomingEpisodes = [];

      // Process shows in parallel for faster loading
      await Future.wait(
        trackedShows.map((trackedShow) async {
          try {
            // Check cache first
            List<Episode> allEpisodes;
            if (_episodesCache.containsKey(trackedShow.showId)) {
              allEpisodes = _episodesCache[trackedShow.showId]!;
            } else {
              // Fetch from API and cache
              final seasons = await tracker.getSeasons(trackedShow.showId);
              allEpisodes = [];

              for (final season in seasons) {
                if (season.id != null) {
                  final seasonEpisodes = await tracker.getEpisodes(season.id!);
                  allEpisodes.addAll(seasonEpisodes);
                }
              }

              // Cache the result
              _episodesCache[trackedShow.showId] = allEpisodes;
            }

            if (allEpisodes.isEmpty) return;

            // Sort episodes by season and number
            allEpisodes.sort((a, b) {
              final aSeason = a.season ?? 0;
              final bSeason = b.season ?? 0;
              if (aSeason != bSeason) return aSeason.compareTo(bSeason);
              return (a.number ?? 0).compareTo(b.number ?? 0);
            });

            // Filter to ONLY unaired episodes
            // This completely ignores watch status
            final unairedEpisodes = allEpisodes.where((episode) {
              // Only include episodes that have NOT aired yet
              return !_hasEpisodeAired(episode.airdate, episode.airtime);
            }).toList();

            // If no unaired episodes, skip this show
            if (unairedEpisodes.isEmpty) return;

            // Get the FIRST unaired episode (the next one to air)
            final nextUnairedEpisode = unairedEpisodes.first;

            // Parse the air date
            DateTime? airDate;
            if (nextUnairedEpisode.airdate != null) {
              try {
                airDate = DateTime.parse(nextUnairedEpisode.airdate!);
              } catch (_) {
                return; // Invalid date format, skip this show
              }
            }

            // Only include if has valid air date
            if (airDate == null) return;

            // Add to upcoming episodes list
            upcomingEpisodes.add(
              UpcomingEpisode(
                showId: trackedShow.showId,
                showName: trackedShow.name,
                posterUrl: trackedShow.posterUrl,
                episode: nextUnairedEpisode,
                airDate: airDate,
                airTime: nextUnairedEpisode.airtime,
              ),
            );
          } catch (e) {
            // Skip this show if there's an error
            return;
          }
        }),
      );

      // Sort by air date (soonest first)
      upcomingEpisodes.sort((a, b) {
        if (a.airDate == null && b.airDate == null) return 0;
        if (a.airDate == null) return 1;
        if (b.airDate == null) return -1;
        return a.airDate!.compareTo(b.airDate!);
      });

      return upcomingEpisodes;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Clear the episodes cache (call when you want fresh data)
void clearEpisodesCache() {
  _episodesCache.clear();
}

/// Provider for upcoming episodes within the next 7 days
final upcomingThisWeekProvider = Provider<List<UpcomingEpisode>>((ref) {
  final upcomingAsync = ref.watch(upcomingEpisodesProvider);

  return upcomingAsync.when(
    data: (episodes) {
      final now = DateTime.now();
      final weekFromNow = now.add(const Duration(days: 7));

      return episodes.where((ep) {
        if (ep.airDate == null) return false;
        return ep.airDate!.isAfter(now) && ep.airDate!.isBefore(weekFromNow);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for episodes airing today
final upcomingTodayProvider = Provider<List<UpcomingEpisode>>((ref) {
  final upcomingAsync = ref.watch(upcomingEpisodesProvider);

  return upcomingAsync.when(
    data: (episodes) => episodes.where((ep) => ep.isToday).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
