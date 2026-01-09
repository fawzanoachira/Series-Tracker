import 'package:series_tracker/data/local/app_database.dart';
import 'package:series_tracker/models/tracking/tracked_episode.dart';
import 'package:sqflite/sqflite.dart';

class EpisodeDao {
  final AppDatabase _database;

  EpisodeDao(this._database);

  Future<void> markWatched({
    required int showId,
    required int season,
    required int episode,
  }) async {
    final db = await _database.database;

    final tracked = TrackedEpisode(
      showId: showId,
      season: season,
      episode: episode,
      watched: true,
      watchedAt: DateTime.now(),
    );

    await db.insert(
      'tracked_episodes',
      tracked.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markUnwatched({
    required int showId,
    required int season,
    required int episode,
  }) async {
    final db = await _database.database;

    await db.delete(
      'tracked_episodes',
      where: 'show_id = ? AND season = ? AND episode = ?',
      whereArgs: [showId, season, episode],
    );
  }

  Future<List<TrackedEpisode>> getEpisodesForShow(int showId) async {
    final db = await _database.database;

    final rows = await db.query(
      'tracked_episodes',
      where: 'show_id = ?',
      whereArgs: [showId],
      orderBy: 'season ASC, episode ASC',
    );

    return rows.map(TrackedEpisode.fromMap).toList();
  }

  Future<bool> isEpisodeWatched({
    required int showId,
    required int season,
    required int episode,
  }) async {
    final db = await _database.database;

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*) FROM tracked_episodes
        WHERE show_id = ? AND season = ? AND episode = ?
        ''',
        [showId, season, episode],
      ),
    );

    return (result ?? 0) > 0;
  }

  Future<void> deleteEpisodesForShow(int showId) async {
    final db = await _database.database;

    await db.delete(
      'tracked_episodes',
      where: 'show_id = ?',
      whereArgs: [showId],
    );
  }
}
