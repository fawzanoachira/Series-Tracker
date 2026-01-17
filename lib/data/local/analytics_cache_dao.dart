import 'package:lahv/data/local/app_database.dart';
import 'package:lahv/models/analytics/cached_analytics_models.dart';
import 'package:sqflite/sqflite.dart';

class AnalyticsCacheDao {
  final AppDatabase _database;

  AnalyticsCacheDao(this._database);

  // ========================================
  // Show Analytics Cache
  // ========================================

  /// Get cached analytics for a show
  Future<CachedShowAnalytics?> getShowAnalytics(int showId) async {
    final db = await _database.database;
    final result = await db.query(
      'show_analytics',
      where: 'show_id = ?',
      whereArgs: [showId],
    );

    if (result.isEmpty) return null;
    return CachedShowAnalytics.fromMap(result.first);
  }

  /// Get all cached show analytics
  Future<List<CachedShowAnalytics>> getAllShowAnalytics() async {
    final db = await _database.database;
    final result = await db.query('show_analytics');
    return result.map((map) => CachedShowAnalytics.fromMap(map)).toList();
  }

  /// Save or update show analytics
  Future<void> upsertShowAnalytics(CachedShowAnalytics analytics) async {
    final db = await _database.database;
    await db.insert(
      'show_analytics',
      analytics.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete show analytics
  Future<void> deleteShowAnalytics(int showId) async {
    final db = await _database.database;
    await db.delete(
      'show_analytics',
      where: 'show_id = ?',
      whereArgs: [showId],
    );
  }

  /// Check if show analytics exists
  Future<bool> hasShowAnalytics(int showId) async {
    final analytics = await getShowAnalytics(showId);
    return analytics != null;
  }

  // ========================================
  // Aggregate Analytics Cache
  // ========================================

  /// Get cached aggregate analytics
  Future<CachedAggregateAnalytics?> getAggregateAnalytics() async {
    final db = await _database.database;
    final result = await db.query(
      'aggregate_analytics',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (result.isEmpty) return null;
    return CachedAggregateAnalytics.fromMap(result.first);
  }

  /// Save or update aggregate analytics
  Future<void> upsertAggregateAnalytics(
    CachedAggregateAnalytics analytics,
  ) async {
    final db = await _database.database;
    await db.insert(
      'aggregate_analytics',
      analytics.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete aggregate analytics
  Future<void> deleteAggregateAnalytics() async {
    final db = await _database.database;
    await db.delete('aggregate_analytics');
  }

  // ========================================
  // Daily Activity Cache
  // ========================================

  /// Get daily activity for a specific date
  Future<CachedDailyActivity?> getDailyActivity(DateTime date) async {
    final db = await _database.database;
    final dateStr = _formatDate(date);
    final result = await db.query(
      'daily_activity',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    if (result.isEmpty) return null;
    return CachedDailyActivity.fromMap(result.first);
  }

  /// Get daily activity for a date range
  Future<List<CachedDailyActivity>> getDailyActivityRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _database.database;
    final startStr = _formatDate(startDate);
    final endStr = _formatDate(endDate);

    final result = await db.query(
      'daily_activity',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date ASC',
    );

    return result.map((map) => CachedDailyActivity.fromMap(map)).toList();
  }

  /// Get last N days of activity
  Future<List<CachedDailyActivity>> getLastNDaysActivity(int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days - 1));
    return getDailyActivityRange(startDate: startDate, endDate: endDate);
  }

  /// Save or update daily activity
  Future<void> upsertDailyActivity(CachedDailyActivity activity) async {
    final db = await _database.database;
    await db.insert(
      'daily_activity',
      activity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Increment episode count for a date
  Future<void> incrementDailyActivity(DateTime date) async {
    final existing = await getDailyActivity(date);

    if (existing == null) {
      await upsertDailyActivity(
        CachedDailyActivity(date: date, episodesCount: 1),
      );
    } else {
      await upsertDailyActivity(
        CachedDailyActivity(
          date: date,
          episodesCount: existing.episodesCount + 1,
        ),
      );
    }
  }

  /// Decrement episode count for a date
  Future<void> decrementDailyActivity(DateTime date) async {
    final existing = await getDailyActivity(date);

    if (existing != null && existing.episodesCount > 0) {
      await upsertDailyActivity(
        CachedDailyActivity(
          date: date,
          episodesCount: existing.episodesCount - 1,
        ),
      );
    }
  }

  /// Delete old activity data (older than N days)
  Future<void> deleteOldActivity(int daysToKeep) async {
    final db = await _database.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final cutoffStr = _formatDate(cutoffDate);

    await db.delete(
      'daily_activity',
      where: 'date < ?',
      whereArgs: [cutoffStr],
    );
  }

  // ========================================
  // Bulk Operations
  // ========================================

  /// Clear all analytics cache
  Future<void> clearAllCache() async {
    final db = await _database.database;
    await db.delete('show_analytics');
    await db.delete('aggregate_analytics');
    await db.delete('daily_activity');
  }

  /// Get cache status
  Future<Map<String, int>> getCacheStats() async {
    final db = await _database.database;

    final showCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM show_analytics'),
        ) ??
        0;

    final hasAggregate = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM aggregate_analytics'),
        ) ??
        0;

    final activityCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM daily_activity'),
        ) ??
        0;

    return {
      'show_analytics_count': showCount,
      'has_aggregate': hasAggregate,
      'activity_days_count': activityCount,
    };
  }

  // ========================================
  // Helpers
  // ========================================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
