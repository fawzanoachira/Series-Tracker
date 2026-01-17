import 'dart:async';
import 'dart:developer';
import 'package:lahv/api/tracker.dart' as tracker;
import 'package:lahv/data/local/analytics_cache_dao.dart';
import 'package:lahv/data/local/app_database.dart';
import 'package:lahv/data/local/episode_dao.dart';
import 'package:lahv/data/local/show_dao.dart';
import 'package:lahv/models/analytics/analytics_models.dart';
import 'package:lahv/models/analytics/cached_analytics_models.dart';
import 'package:lahv/models/tracking/tracked_episode.dart';
import 'package:lahv/models/tracking/tracked_show.dart';
import 'package:lahv/models/tvmaze/episode.dart';
import 'package:lahv/repository/analytics_repository.dart'; // ✅ ADDED

/// Hybrid analytics cache with memory + DB storage
/// Fast reads, incremental updates, persistent across restarts
class HybridAnalyticsCache {
  final AppDatabase _database;
  late final AnalyticsCacheDao _cacheDao;
  late final ShowDao _showDao;
  late final EpisodeDao _episodeDao;
  late final AnalyticsRepository _analyticsRepo; // ✅ ADDED

  // Memory cache for ultra-fast access
  CompleteAnalytics? _memoryCache;
  DateTime? _memoryCacheTime;

  // Cache validity duration
  static const _cacheValidDuration = Duration(minutes: 5);
  static const _avgEpisodeMinutes = 40;

  HybridAnalyticsCache(this._database) {
    _cacheDao = AnalyticsCacheDao(_database);
    _showDao = ShowDao(_database);
    _episodeDao = EpisodeDao(_database);
    _analyticsRepo = AnalyticsRepository(_database); // ✅ ADDED
  }

  // ========================================
  // Public API - Fast Analytics Access
  // ========================================

  /// Get complete analytics (memory → DB → compute)
  Future<CompleteAnalytics> getCompleteAnalytics() async {
    log('🔍 getCompleteAnalytics called');
    log('   Memory valid: ${_isMemoryCacheValid()}');
    // 1. Try memory cache (fastest)
    if (_isMemoryCacheValid()) {
      log('📦 Cache HIT: Using memory cache');
      return _memoryCache!;
    }

    // 2. Try DB cache (fast)
    final dbCached = await _loadFromDB();
    if (dbCached != null) {
      log('💾 Cache HIT: Using DB cache');
      _memoryCache = dbCached;
      _memoryCacheTime = DateTime.now();
      return dbCached;
    }

    // 3. Compute from scratch (slow, first time only)
    log('🔄 Cache MISS: Computing analytics...');
    final computed = await _computeFullAnalytics();
    await _saveToDBAsync(computed);
    _memoryCache = computed;
    _memoryCacheTime = DateTime.now();
    log('✅ Analytics computed and cached');
    return computed;
  }

  /// Force refresh analytics
  Future<CompleteAnalytics> refresh() async {
    log('🔄 Force refresh requested');
    _invalidateMemoryCache();
    return await getCompleteAnalytics();
  }

  // ========================================
  // Event Hooks - Incremental Updates
  // ========================================

  /// Called when an episode is marked watched
  Future<void> onEpisodeMarkedWatched({
    required int showId,
    required int season,
    required int episode,
    required DateTime watchedAt,
  }) async {
    log('📺 Episode marked watched - updating cache');
    log('   Memory cache before: ${_memoryCache != null ? "EXISTS" : "NULL"}');

    // Update show analytics
    await _updateShowAnalytics(showId);

    // Update daily activity
    final date = DateTime(watchedAt.year, watchedAt.month, watchedAt.day);
    await _cacheDao.incrementDailyActivity(date);

    // Update aggregates
    await _updateAggregateAnalytics();

    // Invalidate memory cache
    _invalidateMemoryCache();

    log('   Memory cache after invalidate: ${_memoryCache != null ? "EXISTS" : "NULL"}');
  }

  /// Called when an episode is marked unwatched
  Future<void> onEpisodeMarkedUnwatched({
    required int showId,
    required int season,
    required int episode,
    DateTime? previousWatchedAt,
  }) async {
    log('📺 Episode marked unwatched - updating cache');

    // Update show analytics
    await _updateShowAnalytics(showId);

    // Update daily activity
    if (previousWatchedAt != null) {
      final date = DateTime(
        previousWatchedAt.year,
        previousWatchedAt.month,
        previousWatchedAt.day,
      );
      await _cacheDao.decrementDailyActivity(date);
    }

    // Update aggregates
    await _updateAggregateAnalytics();

    // Invalidate memory cache
    _invalidateMemoryCache();
  }

  /// Called when a show is added
  Future<void> onShowAdded(int showId) async {
    log('📺 Show added - updating cache');

    // Compute analytics for new show
    await _updateShowAnalytics(showId);

    // Update aggregates
    await _updateAggregateAnalytics();

    // Invalidate memory cache
    _invalidateMemoryCache();
  }

  /// Called when a show is removed
  Future<void> onShowRemoved(int showId) async {
    log('📺 Show removed - updating cache');

    // Delete show analytics
    await _cacheDao.deleteShowAnalytics(showId);

    // Update aggregates
    await _updateAggregateAnalytics();

    // Invalidate memory cache
    _invalidateMemoryCache();
  }

  // ========================================
  // Internal - Show Analytics
  // ========================================

  Future<void> _updateShowAnalytics(int showId) async {
    try {
      final show = await _showDao.getShow(showId);
      if (show == null) return;

      final watchedEpisodes = await _episodeDao.getEpisodesForShow(showId);
      final watchedCount = watchedEpisodes.where((e) => e.watched).length;

      if (watchedCount == 0) {
        // No episodes watched yet, don't cache
        await _cacheDao.deleteShowAnalytics(showId);
        return;
      }

      // Fetch show data from API
      final seasons = await tracker.getSeasons(showId);
      final seasonCount =
          seasons.where((s) => s.number != null && s.number! > 0).length;

      final List<Episode> allEpisodes = [];
      for (final season in seasons) {
        if (season.id != null) {
          final eps = await tracker.getEpisodes(season.id!);
          allEpisodes.addAll(eps);
        }
      }

      final airedEpisodes = allEpisodes
          .where((e) => _hasEpisodeAired(e.airdate, e.airtime))
          .toList();
      final totalEpisodes = airedEpisodes.length;

      // Find last watched
      final lastWatched = watchedEpisodes
          .where((e) => e.watched && e.watchedAt != null)
          .fold<DateTime?>(
            null,
            (prev, curr) => prev == null || curr.watchedAt!.isAfter(prev)
                ? curr.watchedAt
                : prev,
          );

      final analytics = CachedShowAnalytics(
        showId: showId,
        episodesWatched: watchedCount,
        totalEpisodes: totalEpisodes,
        seasonCount: seasonCount,
        hoursWatched: (watchedCount * _avgEpisodeMinutes) ~/ 60,
        completionPercentage:
            totalEpisodes > 0 ? (watchedCount / totalEpisodes) * 100 : 0.0,
        lastWatchedAt: lastWatched,
        lastUpdated: DateTime.now(),
      );

      await _cacheDao.upsertShowAnalytics(analytics);
    } catch (e) {
      log('⚠️ Failed to update show analytics: $e');
      // Silently fail - cache update is non-critical
    }
  }

  // ========================================
  // Internal - Aggregate Analytics
  // ========================================

  Future<void> _updateAggregateAnalytics() async {
    try {
      final shows = await _showDao.getAllShows();
      final allShowAnalytics = await _cacheDao.getAllShowAnalytics();

      // ✅ FIXED: Get all episodes by iterating through shows
      final List<TrackedEpisode> allEpisodes = [];
      for (final show in shows) {
        final showEpisodes = await _episodeDao.getEpisodesForShow(show.showId);
        allEpisodes.addAll(showEpisodes);
      }

      final watchedEpisodes = allEpisodes.where((e) => e.watched).toList();
      final totalEpisodesWatched = watchedEpisodes.length;
      final totalSeasons =
          allShowAnalytics.fold<int>(0, (sum, a) => sum + a.seasonCount);

      final totalMinutes = totalEpisodesWatched * _avgEpisodeMinutes;
      final totalHours = totalMinutes ~/ 60;
      final totalDays = totalHours ~/ 24;
      final totalMonths = totalDays ~/ 30;
      final remainingDays = totalDays % 30;

      // Calculate completion
      final totalAvailable =
          allShowAnalytics.fold<int>(0, (sum, a) => sum + a.totalEpisodes);
      final overallCompletion = totalAvailable > 0
          ? (totalEpisodesWatched / totalAvailable) * 100
          : 0.0;

      // Calculate streaks
      final streaks = _calculateStreaks(watchedEpisodes);
      final daysSinceLastWatch = _calculateDaysSinceLastWatch(watchedEpisodes);

      final aggregate = CachedAggregateAnalytics(
        totalShows: shows.length,
        totalEpisodesWatched: totalEpisodesWatched,
        totalSeasons: totalSeasons,
        totalHours: totalHours,
        totalMonths: totalMonths,
        totalDays: remainingDays,
        overallCompletion: overallCompletion,
        currentStreak: streaks.currentStreak,
        longestStreak: streaks.longestStreak,
        daysSinceLastWatch: daysSinceLastWatch,
        lastUpdated: DateTime.now(),
      );

      await _cacheDao.upsertAggregateAnalytics(aggregate);
    } catch (e) {
      log('⚠️ Failed to update aggregate analytics: $e');
      // Silently fail
    }
  }

  // ========================================
  // Internal - Load from DB
  // ========================================

  Future<CompleteAnalytics?> _loadFromDB() async {
    try {
      final aggregate = await _cacheDao.getAggregateAnalytics();
      if (aggregate == null) {
        log('⚠️ No aggregate cache found');
        return null;
      }

      // Check if cache is stale (> 1 hour)
      final age = DateTime.now().difference(aggregate.lastUpdated);
      if (age.inHours > 1) {
        log('⚠️ DB cache is stale (${age.inHours} hours old)');
        return null;
      }

      log('💾 Building analytics from DB cache...');

      // Get cached show analytics
      final allShowAnalytics = await _cacheDao.getAllShowAnalytics();
      final shows = await _showDao.getAllShows();

      // Build show insights from cache
      final topShows = allShowAnalytics
          .map((cached) {
            TrackedShow? show;
            try {
              show = shows.firstWhere((s) => s.showId == cached.showId);
            } catch (e) {
              return null;
            }

            return ShowInsight(
              showId: cached.showId,
              showName: show.name,
              posterUrl: show.posterUrl,
              episodesWatched: cached.episodesWatched,
              totalEpisodes: cached.totalEpisodes,
              seasonCount: cached.seasonCount,
              hoursWatched: cached.hoursWatched,
              completionPercentage: cached.completionPercentage,
              lastWatchedAt: cached.lastWatchedAt,
              daysSinceLastWatch: cached.lastWatchedAt != null
                  ? DateTime.now().difference(cached.lastWatchedAt!).inDays
                  : 0,
            );
          })
          .whereType<ShowInsight>()
          .toList()
        ..sort((a, b) => b.episodesWatched.compareTo(a.episodesWatched));

      // Calculate status breakdown
      final watching =
          shows.where((s) => s.status == TrackedShowStatus.watching).length;
      final completed =
          shows.where((s) => s.status == TrackedShowStatus.completed).length;
      final dropped =
          shows.where((s) => s.status == TrackedShowStatus.dropped).length;

      // Get activity data
      final last30Days = await _load30DaysActivity();
      final totalAvailableEpisodes = allShowAnalytics.fold<int>(
        0,
        (sum, a) => sum + a.totalEpisodes,
      );

      final totalWatchedEpisodes = allShowAnalytics.fold<int>(
        0,
        (sum, a) => sum + a.episodesWatched,
      );

      final totalRemainingEpisodes =
          totalAvailableEpisodes - totalWatchedEpisodes;

// Recalculate completion to ensure consistency
      final actualCompletion = totalAvailableEpisodes > 0
          ? (totalWatchedEpisodes / totalAvailableEpisodes) * 100
          : 0.0;

      // Build complete analytics from cache
      return CompleteAnalytics(
        overview: AnalyticsOverview(
          totalTrackedShows: aggregate.totalShows,
          totalEpisodesWatched: aggregate.totalEpisodesWatched,
          totalHoursWatched: aggregate.totalHours,
          overallCompletionPercentage: aggregate.overallCompletion,
          activeShows: watching + dropped,
          completedShows: completed,
        ),
        statusBreakdown: ShowStatusBreakdown(
          watching: watching,
          completed: completed,
          dropped: dropped,
        ),
        episodeProgress: EpisodeProgressAnalytics(
          totalEpisodesWatched: totalWatchedEpisodes, // ← Consistent
          totalEpisodesRemaining: totalRemainingEpisodes, // ← Consistent
          totalAvailableEpisodes: totalAvailableEpisodes, // ← Consistent
          totalSeasonCount: aggregate.totalSeasons,
          completionPercentage: actualCompletion, // ← Consistent
        ),
        timeAnalytics: TimeAnalytics(
          totalHoursWatched: aggregate.totalHours,
          totalMinutesWatched: aggregate.totalHours * 60,
          totalMonths: aggregate.totalMonths,
          totalDays: aggregate.totalDays,
          averageMinutesPerDay: aggregate.totalEpisodesWatched > 0
              ? (aggregate.totalEpisodesWatched * _avgEpisodeMinutes) /
                  (last30Days.isNotEmpty ? 30 : 1)
              : 0.0,
          averageMinutesPerWeek: aggregate.totalEpisodesWatched > 0
              ? (aggregate.totalEpisodesWatched * _avgEpisodeMinutes) /
                  (last30Days.isNotEmpty ? 4.3 : 1)
              : 0.0,
          estimatedHoursRemaining: allShowAnalytics.fold<int>(
            0,
            (sum, a) =>
                sum +
                ((a.totalEpisodes - a.episodesWatched) *
                    _avgEpisodeMinutes ~/
                    60),
          ),
          estimatedMinutesRemaining: allShowAnalytics.fold<int>(
            0,
            (sum, a) =>
                sum +
                ((a.totalEpisodes - a.episodesWatched) * _avgEpisodeMinutes),
          ),
        ),
        watchingHabits: WatchingHabits(
          episodesPerDay:
              aggregate.totalEpisodesWatched > 0 && last30Days.isNotEmpty
                  ? aggregate.totalEpisodesWatched / 30
                  : 0.0,
          episodesPerWeek:
              aggregate.totalEpisodesWatched > 0 && last30Days.isNotEmpty
                  ? (aggregate.totalEpisodesWatched / 30) * 7
                  : 0.0,
          episodesPerDayOfWeek: {},
          pattern: aggregate.totalEpisodesWatched > 30
              ? WatchingPattern.binge
              : aggregate.totalEpisodesWatched > 10
                  ? WatchingPattern.regular
                  : WatchingPattern.casual,
          currentStreak: aggregate.currentStreak,
          longestStreak: aggregate.longestStreak,
          daysSinceLastWatch: aggregate.daysSinceLastWatch,
        ),
        topShows: topShows.take(3).toList(),
        abandonedShows:
            topShows.where((s) => s.daysSinceLastWatch >= 30).toList(),
        upcoming: UpcomingAnalytics.empty(), // Would need separate cache
        last30DaysActivity: last30Days,
        last12WeeksTrend: const [], // Would need separate cache
      );
    } catch (e) {
      log('⚠️ Failed to load from DB: $e');
      return null;
    }
  }

  Future<List<DailyActivity>> _load30DaysActivity() async {
    final cached = await _cacheDao.getLastNDaysActivity(30);
    return cached
        .map((c) => DailyActivity(
              date: c.date,
              episodesWatched: c.episodesCount,
            ))
        .toList();
  }

  // ========================================
  // Internal - Full Computation (Fallback)
  // ========================================

  /// ✅ FIXED: Actually compute analytics using AnalyticsRepository
  Future<CompleteAnalytics> _computeFullAnalytics() async {
    return await _analyticsRepo.getCompleteAnalytics();
  }

  /// ✅ FIXED: Actually save to DB
  Future<void> _saveToDBAsync(CompleteAnalytics analytics) async {
    // Save to DB in background (don't await)
    unawaited(Future(() async {
      try {
        log('💾 Saving analytics to DB...');

        // Save aggregate analytics
        final aggregate = CachedAggregateAnalytics(
          totalShows: analytics.overview.totalTrackedShows,
          totalEpisodesWatched: analytics.overview.totalEpisodesWatched,
          totalSeasons: analytics.episodeProgress.totalSeasonCount,
          totalHours: analytics.timeAnalytics.totalHoursWatched,
          totalMonths: analytics.timeAnalytics.totalMonths,
          totalDays: analytics.timeAnalytics.totalDays,
          overallCompletion: analytics.overview.overallCompletionPercentage,
          currentStreak: analytics.watchingHabits.currentStreak,
          longestStreak: analytics.watchingHabits.longestStreak,
          daysSinceLastWatch: analytics.watchingHabits.daysSinceLastWatch,
          lastUpdated: DateTime.now(),
        );

        await _cacheDao.upsertAggregateAnalytics(aggregate);

        // Save daily activity
        for (final activity in analytics.last30DaysActivity) {
          final cached = CachedDailyActivity(
            date: activity.date,
            episodesCount: activity.episodesWatched,
          );
          await _cacheDao.upsertDailyActivity(cached);
        }

        log('✅ Analytics saved to DB');
      } catch (e) {
        log('⚠️ Failed to save to DB: $e');
        // Silent fail
      }
    }));
  }

  // ========================================
  // Helpers
  // ========================================

  bool _isMemoryCacheValid() {
    if (_memoryCache == null || _memoryCacheTime == null) return false;
    final age = DateTime.now().difference(_memoryCacheTime!);
    return age < _cacheValidDuration;
  }

  void _invalidateMemoryCache() {
    _memoryCache = null;
    _memoryCacheTime = null;
    log('🗑️ Memory cache invalidated');
  }

  bool _hasEpisodeAired(String? airdate, [String? airtime]) {
    if (airdate == null || airdate.isEmpty) return false;
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
      return episodeDateTime.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// ✅ FIXED: Proper streak calculation
  ({int currentStreak, int longestStreak}) _calculateStreaks(
      List<TrackedEpisode> episodes) {
    if (episodes.isEmpty) return (currentStreak: 0, longestStreak: 0);

    // Group episodes by date
    final watchDates = episodes
        .where((e) => e.watchedAt != null)
        .map((e) => DateTime(
              e.watchedAt!.year,
              e.watchedAt!.month,
              e.watchedAt!.day,
            ))
        .toSet()
        .toList()
      ..sort();

    if (watchDates.isEmpty) return (currentStreak: 0, longestStreak: 0);

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 1;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));

    // Check if there's activity today or yesterday for current streak
    final hasRecentActivity = watchDates.any((date) =>
        date.isAtSameMomentAs(todayDate) || date.isAtSameMomentAs(yesterday));

    for (int i = 1; i < watchDates.length; i++) {
      final diff = watchDates[i].difference(watchDates[i - 1]).inDays;

      if (diff == 1) {
        tempStreak++;
      } else {
        if (tempStreak > longestStreak) longestStreak = tempStreak;
        tempStreak = 1;
      }
    }

    if (tempStreak > longestStreak) longestStreak = tempStreak;

    if (hasRecentActivity) {
      currentStreak = tempStreak;
    }

    return (currentStreak: currentStreak, longestStreak: longestStreak);
  }

  /// ✅ FIXED: Proper days since last watch calculation
  int _calculateDaysSinceLastWatch(List<TrackedEpisode> episodes) {
    if (episodes.isEmpty) return 999;

    final lastWatched = episodes
        .where((e) => e.watchedAt != null)
        .map((e) => e.watchedAt!)
        .fold<DateTime?>(
          null,
          (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev,
        );

    if (lastWatched == null) return 999;

    final today = DateTime.now();
    final lastWatchedDay = DateTime(
      lastWatched.year,
      lastWatched.month,
      lastWatched.day,
    );
    final todayDay = DateTime(today.year, today.month, today.day);

    return todayDay.difference(lastWatchedDay).inDays;
  }
}
