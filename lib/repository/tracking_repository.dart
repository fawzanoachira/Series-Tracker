import 'package:series_tracker/data/local/app_database.dart';
import 'package:series_tracker/data/local/show_dao.dart';
import 'package:series_tracker/data/local/episode_dao.dart';
import 'package:series_tracker/models/tracking/tracked_show.dart';
import 'package:series_tracker/models/tracking/tracked_episode.dart';
import 'package:series_tracker/models/tvmaze/show.dart';

class TrackingRepository {
  final ShowDao _showDao;
  final EpisodeDao _episodeDao;

  TrackingRepository(AppDatabase database)
      : _showDao = ShowDao(database),
        _episodeDao = EpisodeDao(database);

  // -------- Shows --------

  Future<void> addShow(Show show) async {
    final showId = show.id;
    final name = show.name;

    if (showId == null || name == null) {
      throw StateError('Cannot track show with null id or name');
    }

    final tracked = TrackedShow(
      showId: showId,
      name: name,
      posterUrl: show.image?.medium,
      status: TrackedShowStatus.watching,
      addedAt: DateTime.now(),
    );

    await _showDao.insertShow(tracked);
  }

  Future<void> removeShow(int showId) async {
    await _episodeDao.deleteEpisodesForShow(showId);
    await _showDao.deleteShow(showId);
  }

  Future<List<TrackedShow>> getTrackedShows() {
    return _showDao.getAllShows();
  }

  Future<bool> isShowTracked(int showId) {
    return _showDao.isShowTracked(showId);
  }

  Future<void> updateShowStatus(
    int showId,
    TrackedShowStatus status,
  ) {
    return _showDao.updateStatus(showId, status);
  }

  // -------- Episodes --------

  Future<void> markEpisodeWatched({
    required int showId,
    required int season,
    required int episode,
  }) {
    return _episodeDao.markWatched(
      showId: showId,
      season: season,
      episode: episode,
    );
  }

  Future<void> markEpisodeUnwatched({
    required int showId,
    required int season,
    required int episode,
  }) {
    return _episodeDao.markUnwatched(
      showId: showId,
      season: season,
      episode: episode,
    );
  }

  Future<List<TrackedEpisode>> getEpisodeProgress(int showId) {
    return _episodeDao.getEpisodesForShow(showId);
  }

  Future<bool> isEpisodeWatched({
    required int showId,
    required int season,
    required int episode,
  }) {
    return _episodeDao.isEpisodeWatched(
      showId: showId,
      season: season,
      episode: episode,
    );
  }
}
