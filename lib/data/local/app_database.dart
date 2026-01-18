import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const _dbName = 'lahv.db';
  static const _dbVersion = 2; // ← Incremented for analytics cache

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Original tables
    await db.execute('''
      CREATE TABLE tracked_shows (
        show_id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        poster_url TEXT,
        status TEXT NOT NULL,
        added_at INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE tracked_episodes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        show_id INTEGER NOT NULL,
        season INTEGER NOT NULL,
        episode INTEGER NOT NULL,
        watched INTEGER NOT NULL,
        watched_at INTEGER,
        UNIQUE (show_id, season, episode)
      );
    ''');

    // New analytics cache tables
    await _createAnalyticsTables(db);
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Add analytics cache tables
      await _createAnalyticsTables(db);
    }
  }

  Future<void> _createAnalyticsTables(Database db) async {
    // Per-show analytics cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS show_analytics (
        show_id INTEGER PRIMARY KEY,
        episodes_watched INTEGER NOT NULL,
        total_episodes INTEGER NOT NULL,
        season_count INTEGER NOT NULL,
        hours_watched INTEGER NOT NULL,
        completion_percentage REAL NOT NULL,
        last_watched_at INTEGER,
        last_updated INTEGER NOT NULL
      );
    ''');

    // Aggregate analytics cache
    await db.execute('''
      CREATE TABLE IF NOT EXISTS aggregate_analytics (
        id INTEGER PRIMARY KEY DEFAULT 1,
        total_shows INTEGER NOT NULL,
        total_episodes_watched INTEGER NOT NULL,
        total_seasons INTEGER NOT NULL,
        total_hours INTEGER NOT NULL,
        total_months INTEGER NOT NULL,
        total_days INTEGER NOT NULL,
        overall_completion REAL NOT NULL,
        current_streak INTEGER NOT NULL,
        longest_streak INTEGER NOT NULL,
        days_since_last_watch INTEGER NOT NULL,
        last_updated INTEGER NOT NULL
      );
    ''');

    // Daily activity cache (for heatmap)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_activity (
        date TEXT PRIMARY KEY,
        episodes_count INTEGER NOT NULL
      );
    ''');

    // Index for faster queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_daily_activity_date 
      ON daily_activity(date DESC);
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
