import 'package:series_tracker/api/tracker.dart' as tracker;
import 'package:series_tracker/data/local/app_database.dart';
import 'package:series_tracker/data/local/episode_dao.dart';
import 'package:series_tracker/data/local/show_dao.dart';
import 'package:series_tracker/models/tracking/tracked_episode.dart';
import 'package:series_tracker/models/tracking/tracked_show.dart';
import 'package:series_tracker/models/tvmaze/episode.dart';
import 'package:series_tracker/models/tvmaze/show.dart';

class TrackingRepository {
  final AppDatabase _database;
  late final ShowDao _showDao;
  late final EpisodeDao _episodeDao;

  TrackingRepository(this._database) {
    _showDao = ShowDao(_database);
    _episodeDao = EpisodeDao(_database);
  }

  /// Helper method to check if an episode has aired
  /// Considers both airdate and airtime if available
  bool _hasEpisodeAired(String? airdate, [String? airtime]) {
    if (airdate == null || airdate.isEmpty) {
      return false; // If no airdate, consider it not aired
    }

    try {
      DateTime episodeDateTime;

      if (airtime != null && airtime.isNotEmpty) {
        // Combine airdate and airtime (format: "HH:MM")
        // TVMaze uses local time for the show's network
        final dateParts = airdate.split('-');
        final timeParts = airtime.split(':');

        episodeDateTime = DateTime(
          int.parse(dateParts[0]), // year
          int.parse(dateParts[1]), // month
          int.parse(dateParts[2]), // day
          int.parse(timeParts[0]), // hour
          timeParts.length > 1 ? int.parse(timeParts[1]) : 0, // minute
        );
      } else {
        // Only airdate available, assume end of day
        episodeDateTime =
            DateTime.parse(airdate).add(const Duration(hours: 23, minutes: 59));
      }

      final now = DateTime.now();

      // Episode has aired if the datetime is in the past
      return episodeDateTime.isBefore(now);
    } catch (e) {
      // If parsing fails, fall back to date-only comparison
      try {
        final episodeDate = DateTime.parse(airdate);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final epDate =
            DateTime(episodeDate.year, episodeDate.month, episodeDate.day);

        return epDate.isBefore(today);
      } catch (e) {
        return false; // If all parsing fails, consider it not aired
      }
    }
  }

  /// Helper method to get episode data from API
  Future<({String? airdate, String? airtime})?> _getEpisodeData({
    required int showId,
    required int season,
    required int episode,
  }) async {
    try {
      final seasons = await tracker.getSeasons(showId);

      for (final seasonData in seasons) {
        if (seasonData.number == season && seasonData.id != null) {
          final episodes = await tracker.getEpisodes(seasonData.id!);

          for (final ep in episodes) {
            if (ep.number == episode) {
              return (airdate: ep.airdate, airtime: ep.airtime);
            }
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // -------- Shows --------
  Future<void> addShow(Show show) async {
    final trackedShow = TrackedShow(
      showId: show.id!,
      name: show.name ?? 'Unknown Show',
      posterUrl: show.image?.medium,
      status: TrackedShowStatus.watching,
      addedAt: DateTime.now(),
    );

    await _showDao.insertShow(trackedShow);
  }

  Future<void> removeShow(int showId) async {
    await _showDao.deleteShow(showId);
    await _episodeDao.deleteEpisodesForShow(showId);
  }

  Future<List<TrackedShow>> getTrackedShows() async {
    return await _showDao.getAllShows();
  }

  Future<TrackedShow?> getShow(int showId) async {
    return await _showDao.getShow(showId);
  }

  Future<bool> isShowTracked(int showId) async {
    return await _showDao.isShowTracked(showId);
  }

  Future<void> updateShowStatus(int showId, TrackedShowStatus status) async {
    await _showDao.updateStatus(showId, status);
  }

  // -------- Episodes --------
  Future<void> markEpisodeWatched({
    required int showId,
    required int season,
    required int episode,
  }) async {
    // Check if episode has aired before allowing tracking
    final episodeData = await _getEpisodeData(
      showId: showId,
      season: season,
      episode: episode,
    );

    if (episodeData == null ||
        !_hasEpisodeAired(episodeData.airdate, episodeData.airtime)) {
      throw Exception('Cannot mark unaired episode as watched');
    }

    await _episodeDao.markWatched(
      showId: showId,
      season: season,
      episode: episode,
    );
  }

  Future<void> markEpisodeUnwatched({
    required int showId,
    required int season,
    required int episode,
  }) async {
    await _episodeDao.markUnwatched(
      showId: showId,
      season: season,
      episode: episode,
    );
  }

  /// Batch mark multiple episodes - optimized for bulk operations
  /// Only marks episodes that have already aired
  Future<void> markMultipleEpisodesWatched({
    required int showId,
    required List<({int season, int episode})> episodes,
  }) async {
    // Fetch all episodes for the show to check airdates
    final seasons = await tracker.getSeasons(showId);
    final List<Episode> allEpisodes = [];

    for (final seasonData in seasons) {
      if (seasonData.id != null) {
        final seasonEpisodes = await tracker.getEpisodes(seasonData.id!);
        allEpisodes.addAll(seasonEpisodes);
      }
    }

    // Filter episodes to only include those that have aired
    final airedEpisodes = episodes.where((ep) {
      final matchingEpisode = allEpisodes.firstWhere(
        (apiEp) => apiEp.season == ep.season && apiEp.number == ep.episode,
        orElse: () => Episode(),
      );

      return _hasEpisodeAired(matchingEpisode.airdate, matchingEpisode.airtime);
    }).toList();

    // Only mark episodes that have aired
    if (airedEpisodes.isNotEmpty) {
      await _episodeDao.markMultipleWatched(
        showId: showId,
        episodes: airedEpisodes,
      );
    }
  }

  /// Batch unmark multiple episodes - optimized for bulk operations
  Future<void> markMultipleEpisodesUnwatched({
    required int showId,
    required List<({int season, int episode})> episodes,
  }) async {
    await _episodeDao.markMultipleUnwatched(
      showId: showId,
      episodes: episodes,
    );
  }

  Future<List<TrackedEpisode>> getEpisodesForShow(int showId) async {
    return await _episodeDao.getEpisodesForShow(showId);
  }

  Future<List<TrackedEpisode>> getEpisodeProgress(int showId) async {
    return await _episodeDao.getEpisodesForShow(showId);
  }

  Future<bool> isEpisodeWatched({
    required int showId,
    required int season,
    required int episode,
  }) async {
    return await _episodeDao.isEpisodeWatched(
      showId: showId,
      season: season,
      episode: episode,
    );
  }

  // -------- Auto-completion Check --------
  Future<bool> checkAndUpdateShowCompletion(int showId) async {
    try {
      // Get the tracked show
      final trackedShow = await _showDao.getShow(showId);

      if (trackedShow == null) return false;

      // Get all episodes for the show from API
      final seasons = await tracker.getSeasons(showId);
      final List<Episode> allEpisodes = [];

      for (final season in seasons) {
        if (season.id != null) {
          final seasonEpisodes = await tracker.getEpisodes(season.id!);
          allEpisodes.addAll(seasonEpisodes);
        }
      }

      if (allEpisodes.isEmpty) return false;

      // Filter to only aired episodes
      final airedEpisodes = allEpisodes
          .where((ep) => _hasEpisodeAired(ep.airdate, ep.airtime))
          .toList();

      if (airedEpisodes.isEmpty) return false;

      // Get watched episodes from database
      final watchedEpisodes = await _episodeDao.getEpisodesForShow(showId);

      // Create set of watched episode keys
      final watchedSet =
          watchedEpisodes.map((e) => '${e.season}-${e.episode}').toSet();

      // Check if all AIRED episodes are watched
      final allWatched = airedEpisodes.every((ep) {
        final key = '${ep.season ?? 0}-${ep.number ?? 0}';
        return watchedSet.contains(key);
      });

      // Update status based on completion
      if (allWatched && trackedShow.status != TrackedShowStatus.completed) {
        await _showDao.updateStatus(showId, TrackedShowStatus.completed);
        return true; // ✅ Status changed to completed
      } else if (!allWatched &&
          trackedShow.status == TrackedShowStatus.completed) {
        // If previously completed but now has unwatched episodes, move back to watching
        await _showDao.updateStatus(showId, TrackedShowStatus.watching);
        return true; // ✅ Status changed to watching
      }

      return false; // ✅ Status unchanged
    } catch (e) {
      // Silently fail - this is a background check
      return false;
    }
  }
}
