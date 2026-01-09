import 'package:series_tracker/data/local/app_database.dart';
import 'package:series_tracker/models/tracking/tracked_show.dart';
import 'package:sqflite/sqflite.dart';

class ShowDao {
  final AppDatabase _database;

  ShowDao(this._database);

  Future<void> insertShow(TrackedShow show) async {
    final db = await _database.database;

    await db.insert(
      'tracked_shows',
      show.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteShow(int showId) async {
    final db = await _database.database;

    await db.delete(
      'tracked_shows',
      where: 'show_id = ?',
      whereArgs: [showId],
    );
  }

  Future<List<TrackedShow>> getAllShows() async {
    final db = await _database.database;

    final rows = await db.query(
      'tracked_shows',
      orderBy: 'added_at DESC',
    );

    return rows.map(TrackedShow.fromMap).toList();
  }

  Future<TrackedShow?> getShow(int showId) async {
    final db = await _database.database;

    final rows = await db.query(
      'tracked_shows',
      where: 'show_id = ?',
      whereArgs: [showId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return TrackedShow.fromMap(rows.first);
  }

  Future<bool> isShowTracked(int showId) async {
    final db = await _database.database;

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM tracked_shows WHERE show_id = ?',
        [showId],
      ),
    );

    return (result ?? 0) > 0;
  }

  Future<void> updateStatus(
    int showId,
    TrackedShowStatus status,
  ) async {
    final db = await _database.database;

    await db.update(
      'tracked_shows',
      {'status': status.name},
      where: 'show_id = ?',
      whereArgs: [showId],
    );
  }
}
