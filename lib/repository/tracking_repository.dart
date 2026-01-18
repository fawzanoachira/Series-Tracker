import 'package:lahv/api/tracker.dart' as tracker;
import 'package:lahv/data/local/app_database.dart';
import 'package:lahv/data/local/episode_dao.dart';
import 'package:lahv/data/local/show_dao.dart';
import 'package:lahv/models/tracking/tracked_episode.dart';
import 'package:lahv/models/tracking/tracked_show.dart';
import 'package:lahv/models/tvmaze/episode.dart';
import 'package:lahv/models/tvmaze/show.dart';
import 'package:lahv/services/hybrid_analytics_cache.dart';

class TrackingRepository {
  final AppDatabase _database;
  final HybridAnalyticsCache _analyticsCache;
  late final ShowDao _showDao;
  late final EpisodeDao _episodeDao;

  TrackingRepository(this._database, this._analyticsCache) {
    _showDao = ShowDao(_database);
    _episodeDao = EpisodeDao(_database);
  }

  /// Helper method to check if an episode has aired
  bool _hasEpisodeAired(String? airdate, [String? airtime]) {
    if (airdate == null || airdate.isEmpty) {
      return false;
    }

    try {
      DateTime episodeDateTime;

      if (airtime != null && airtime.isNotEmpty) {
        final dateParts = airdate.split('-');
        final timeParts = airtime.split(':');

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
      try {
        final episodeDate = DateTime.parse(airdate);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final epDate =
            DateTime(episodeDate.year, episodeDate.month, episodeDate.day);

        return epDate.isBefore(today);
      } catch (e) {
        return false;
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

    // 🔔 Cache Hook: Show added
    await _analyticsCache.onShowAdded(show.id!);
  }

  Future<void> removeShow(int showId) async {
    await _showDao.deleteShow(showId);
    await _episodeDao.deleteEpisodesForShow(showId);

    // 🔔 Cache Hook: Show removed
    await _analyticsCache.onShowRemoved(showId);
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

    final watchedAt = DateTime.now();

    await _episodeDao.markWatched(
      showId: showId,
      season: season,
      episode: episode,
    );

    // 🔔 Cache Hook: Episode marked watched
    await _analyticsCache.onEpisodeMarkedWatched(
      showId: showId,
      season: season,
      episode: episode,
      watchedAt: watchedAt,
    );
  }

  Future<void> markEpisodeUnwatched({
    required int showId,
    required int season,
    required int episode,
  }) async {
    // Get current watched time before unmarking
    final currentEpisode = await _episodeDao.getEpisode(
      showId: showId,
      season: season,
      episode: episode,
    );

    await _episodeDao.markUnwatched(
      showId: showId,
      season: season,
      episode: episode,
    );

    // 🔔 Cache Hook: Episode marked unwatched
    await _analyticsCache.onEpisodeMarkedUnwatched(
      showId: showId,
      season: season,
      episode: episode,
      previousWatchedAt: currentEpisode?.watchedAt,
    );
  }

  /// Batch mark multiple episodes - optimized for bulk operations
  Future<void> markMultipleEpisodesWatched({
    required int showId,
    required List<({int season, int episode})> episodes,
  }) async {
    final seasons = await tracker.getSeasons(showId);
    final List<Episode> allEpisodes = [];

    for (final seasonData in seasons) {
      if (seasonData.id != null) {
        final seasonEpisodes = await tracker.getEpisodes(seasonData.id!);
        allEpisodes.addAll(seasonEpisodes);
      }
    }

    final airedEpisodes = episodes.where((ep) {
      final matchingEpisode = allEpisodes.firstWhere(
        (apiEp) => apiEp.season == ep.season && apiEp.number == ep.episode,
        orElse: () => Episode(),
      );

      return _hasEpisodeAired(matchingEpisode.airdate, matchingEpisode.airtime);
    }).toList();

    if (airedEpisodes.isNotEmpty) {
      await _episodeDao.markMultipleWatched(
        showId: showId,
        episodes: airedEpisodes,
      );

      // 🔔 Cache Hook: Multiple episodes marked (update show analytics)
      await _analyticsCache.onShowAdded(showId); // Recompute show
    }
  }

  Future<void> markMultipleEpisodesUnwatched({
    required int showId,
    required List<({int season, int episode})> episodes,
  }) async {
    await _episodeDao.markMultipleUnwatched(
      showId: showId,
      episodes: episodes,
    );

    // 🔔 Cache Hook: Multiple episodes unmarked (update show analytics)
    await _analyticsCache.onShowAdded(showId); // Recompute show
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
  /// FIXED: Now filters out special episodes (number = 0 or null) when checking completion
  Future<bool> checkAndUpdateShowCompletion(int showId) async {
    try {
      final trackedShow = await _showDao.getShow(showId);

      if (trackedShow == null) return false;

      final seasons = await tracker.getSeasons(showId);
      final List<Episode> allEpisodes = [];

      for (final season in seasons) {
        if (season.id != null) {
          final seasonEpisodes = await tracker.getEpisodes(season.id!);
          allEpisodes.addAll(seasonEpisodes);
        }
      }

      if (allEpisodes.isEmpty) return false;

      // FIXED: Filter out special episodes (number = 0 or null)
      // Only consider regular episodes for completion status
      final regularEpisodes =
          allEpisodes.where((ep) => (ep.number ?? 0) > 0).toList();

      if (regularEpisodes.isEmpty) return false;

      final airedEpisodes = regularEpisodes
          .where((ep) => _hasEpisodeAired(ep.airdate, ep.airtime))
          .toList();

      if (airedEpisodes.isEmpty) return false;

      final watchedEpisodes = await _episodeDao.getEpisodesForShow(showId);

      final watchedSet =
          watchedEpisodes.map((e) => '${e.season}-${e.episode}').toSet();

      final allWatched = airedEpisodes.every((ep) {
        final key = '${ep.season ?? 0}-${ep.number ?? 0}';
        return watchedSet.contains(key);
      });

      if (allWatched && trackedShow.status != TrackedShowStatus.completed) {
        await _showDao.updateStatus(showId, TrackedShowStatus.completed);
        return true;
      } else if (!allWatched &&
          trackedShow.status == TrackedShowStatus.completed) {
        await _showDao.updateStatus(showId, TrackedShowStatus.watching);
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
