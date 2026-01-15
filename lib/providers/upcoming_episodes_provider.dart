import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/api/tracker.dart' as tracker;
import 'package:series_tracker/models/tracking/upcoming_episode.dart';
import 'package:series_tracker/models/tvmaze/episode.dart';
import 'package:series_tracker/providers/core_providers.dart';
import 'package:series_tracker/providers/tracked_shows_provider.dart';

/// Cache for episodes by show ID to avoid repeated API calls
final _episodesCache = <int, List<Episode>>{};

/// Provider that fetches ONLY upcoming episodes (today + future)
final upcomingEpisodesProvider =
    FutureProvider<List<UpcomingEpisode>>((ref) async {
  final trackedShowsAsync = ref.watch(trackedShowsProvider);

  return trackedShowsAsync.when(
    data: (trackedShows) async {
      if (trackedShows.isEmpty) return [];

      final repo = ref.read(trackingRepositoryProvider);
      final List<UpcomingEpisode> upcomingEpisodes = [];
      final now = DateTime.now();

      // Process shows in parallel for faster loading
      await Future.wait(
        trackedShows.map((trackedShow) async {
          try {
            // Get watched episodes for this show
            final watchedEpisodes =
                await repo.getEpisodesForShow(trackedShow.showId);

            // Create set of watched episodes for quick lookup
            final watchedSet =
                watchedEpisodes.map((e) => '${e.season}-${e.episode}').toSet();

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

            // Sort episodes
            allEpisodes.sort((a, b) {
              final aSeason = a.season ?? 0;
              final bSeason = b.season ?? 0;
              if (aSeason != bSeason) return aSeason.compareTo(bSeason);
              return (a.number ?? 0).compareTo(b.number ?? 0);
            });

            // Find next unwatched episode
            Episode? nextEpisode;
            for (final episode in allEpisodes) {
              final key = '${episode.season ?? 0}-${episode.number ?? 0}';
              if (!watchedSet.contains(key)) {
                nextEpisode = episode;
                break;
              }
            }

            // If found, create UpcomingEpisode
            if (nextEpisode != null) {
              DateTime? airDate;
              if (nextEpisode.airdate != null) {
                try {
                  airDate = DateTime.parse(nextEpisode.airdate!);
                } catch (_) {
                  // Invalid date format
                }
              }

              // Only include if airing today or in the future
              // Skip past episodes completely
              if (airDate != null &&
                  !airDate.isBefore(now.subtract(const Duration(days: 1)))) {
                upcomingEpisodes.add(
                  UpcomingEpisode(
                    showId: trackedShow.showId,
                    showName: trackedShow.name,
                    posterUrl: trackedShow.posterUrl,
                    episode: nextEpisode,
                    airDate: airDate,
                    airTime: nextEpisode.airtime,
                  ),
                );
              }
            }
          } catch (e) {
            // Skip this show if there's an error
            return;
          }
        }),
      );

      // Sort by air date (upcoming first, then by date)
      upcomingEpisodes.sort((a, b) {
        // Put episodes with no air date at the end
        if (a.airDate == null && b.airDate == null) return 0;
        if (a.airDate == null) return 1;
        if (b.airDate == null) return -1;

        // Sort by air date
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
