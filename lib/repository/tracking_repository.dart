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

  // -------- Shows --------
  Future<void> addShow(Show show) async {
    final trackedShow = TrackedShow(
      showId: show.id!,
      name: show.name ?? 'Unknown Show', // Handle nullable name
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
  Future<void> markMultipleEpisodesWatched({
    required int showId,
    required List<({int season, int episode})> episodes,
  }) async {
    await _episodeDao.markMultipleWatched(
      showId: showId,
      episodes: episodes,
    );
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
  Future<void> checkAndUpdateShowCompletion(int showId) async {
    try {
      // Get the tracked show
      final trackedShow = await _showDao.getShow(showId);

      if (trackedShow == null) return;

      // Get all episodes for the show from API
      final seasons = await tracker.getSeasons(showId);
      final List<Episode> allEpisodes = [];

      for (final season in seasons) {
        if (season.id != null) {
          final seasonEpisodes = await tracker.getEpisodes(season.id!);
          allEpisodes.addAll(seasonEpisodes);
        }
      }

      if (allEpisodes.isEmpty) return;

      // Get watched episodes from database
      final watchedEpisodes = await _episodeDao.getEpisodesForShow(showId);

      // Create set of watched episode keys
      final watchedSet =
          watchedEpisodes.map((e) => '${e.season}-${e.episode}').toSet();

      // Check if all episodes are watched
      final allWatched = allEpisodes.every((ep) {
        final key = '${ep.season ?? 0}-${ep.number ?? 0}';
        return watchedSet.contains(key);
      });

      // Update status based on completion
      if (allWatched && trackedShow.status != TrackedShowStatus.completed) {
        await _showDao.updateStatus(showId, TrackedShowStatus.completed);
      } else if (!allWatched &&
          trackedShow.status == TrackedShowStatus.completed) {
        // If previously completed but now has unwatched episodes, move back to watching
        await _showDao.updateStatus(showId, TrackedShowStatus.watching);
      }
    } catch (e) {
      // Silently fail - this is a background check
    }
  }
}
