import 'dart:async';
import 'package:lahv/api/tracker.dart' as tracker;
import 'package:lahv/data/local/analytics_cache_dao.dart';
import 'package:lahv/data/local/app_database.dart';
import 'package:lahv/data/local/episode_dao.dart';
import 'package:lahv/data/local/show_dao.dart';
import 'package:lahv/models/analytics/cached_analytics_models.dart';
import 'package:lahv/models/tracking/tracked_episode.dart';
import 'package:lahv/models/tvmaze/episode.dart';

/// Simple analytics with 3 features:
/// 1. Total time watched (with year/month/day breakdown)
/// 2. Total episodes across shows/seasons
/// 3. Top shows by watch time
class HybridAnalyticsCache {
  final AppDatabase _database;
  late final AnalyticsCacheDao _cacheDao;
  late final ShowDao _showDao;
  late final EpisodeDao _episodeDao;

  // Memory cache
  SimpleAnalytics? _memoryCache;
  DateTime? _memoryCacheTime;

  static const _cacheValidDuration = Duration(minutes: 5);
  static const _avgEpisodeMinutes = 40;

  HybridAnalyticsCache(this._database) {
    _cacheDao = AnalyticsCacheDao(_database);
    _showDao = ShowDao(_database);
    _episodeDao = EpisodeDao(_database);
  }

  // ========================================
  // Public API
  // ========================================

  Future<SimpleAnalytics> getAnalytics() async {
    // Try memory cache
    if (_isMemoryCacheValid()) {
      print('📦 Using memory cache');
      return _memoryCache!;
    }

    // Try DB cache
    final aggregate = await _cacheDao.getAggregateAnalytics();
    if (aggregate != null && _isCacheFresh(aggregate.lastUpdated)) {
      print('💾 Using DB cache');

      // Build analytics from cache
      final analytics = await _buildFromCache(aggregate);

      // Save to memory
      _memoryCache = analytics;
      _memoryCacheTime = DateTime.now();

      return analytics;
    }

    // Compute from scratch
    print('🔄 Computing analytics from scratch...');
    final analytics = await _computeAnalytics();

    // Save to DB
    await _saveToCache(analytics);

    // Save to memory
    _memoryCache = analytics;
    _memoryCacheTime = DateTime.now();

    print('✅ Analytics computed');
    return analytics;
  }

  Future<void> clearCache() async {
    await _cacheDao.clearAllCache();
    _invalidateMemory();
    print('🗑️ Cache cleared');
  }

  /// Rebuild cache for ALL shows (use once after adding cache feature)
  Future<void> rebuildAllShowCache() async {
    print('🔄 Rebuilding cache for all shows...');
    final shows = await _showDao.getAllShows();

    for (final show in shows) {
      await _updateShowAnalytics(show.showId);
      print('  ✅ Cached show ${show.showId}');
    }

    await _updateAggregateAnalytics();
    _invalidateMemory();
    print('✅ All shows cached');
  }

  // ========================================
  // Cache Hooks (called from repository)
  // ========================================

  Future<void> onEpisodeMarkedWatched({
    required int showId,
    required int season,
    required int episode,
    required DateTime watchedAt,
  }) async {
    print('📺 Episode watched - updating cache');
    await _updateShowAnalytics(showId);
    await _updateAggregateAnalytics();
    _invalidateMemory();
  }

  Future<void> onEpisodeMarkedUnwatched({
    required int showId,
    required int season,
    required int episode,
    DateTime? previousWatchedAt,
  }) async {
    print('📺 Episode unwatched - updating cache');
    await _updateShowAnalytics(showId);
    await _updateAggregateAnalytics();
    _invalidateMemory();
  }

  Future<void> onShowAdded(int showId) async {
    print('📺 Show added - updating cache');
    await _updateShowAnalytics(showId);
    await _updateAggregateAnalytics();
    _invalidateMemory();
  }

  Future<void> onShowRemoved(int showId) async {
    print('📺 Show removed - updating cache');
    await _cacheDao.deleteShowAnalytics(showId);
    await _updateAggregateAnalytics();
    _invalidateMemory();
  }

  // ========================================
  // Internal - Computation
  // ========================================

  Future<SimpleAnalytics> _computeAnalytics() async {
    final shows = await _showDao.getAllShows();

    // ✅ FIX: Ensure ALL shows have cache entries (for old shows added before cache)
    final cachedShowIds =
        (await _cacheDao.getAllShowAnalytics()).map((a) => a.showId).toSet();

    for (final show in shows) {
      if (!cachedShowIds.contains(show.showId)) {
        print('⚠️ Show ${show.showId} missing cache, building...');
        await _updateShowAnalytics(show.showId);
      }
    }

    // Get all episodes
    final List<TrackedEpisode> allEpisodes = [];
    for (final show in shows) {
      final episodes = await _episodeDao.getEpisodesForShow(show.showId);
      allEpisodes.addAll(episodes);
    }

    final watchedEpisodes = allEpisodes.where((e) => e.watched).toList();
    final totalMinutes = watchedEpisodes.length * _avgEpisodeMinutes;

    // Get show analytics from cache (now guaranteed to have all shows)
    final showAnalytics = await _cacheDao.getAllShowAnalytics();
    final totalSeasons =
        showAnalytics.fold<int>(0, (sum, a) => sum + a.seasonCount);

    // Get top shows by hours
    final topShows = await _getTopShowsByTime();

    return SimpleAnalytics(
      totalMinutesWatched: totalMinutes,
      totalEpisodesWatched: watchedEpisodes.length,
      totalShows: shows.length,
      totalSeasons: totalSeasons,
      topShows: topShows,
    );
  }

  Future<List<TopShow>> _getTopShowsByTime() async {
    final showAnalytics = await _cacheDao.getAllShowAnalytics();
    final shows = await _showDao.getAllShows();

    // Build list of top shows
    final List<TopShow> topList = [];
    for (final analytics in showAnalytics) {
      final show = shows.where((s) => s.showId == analytics.showId).firstOrNull;
      if (show != null && analytics.hoursWatched > 0) {
        topList.add(TopShow(
          showId: analytics.showId,
          showName: show.name,
          posterUrl: show.posterUrl,
          episodesWatched: analytics.episodesWatched,
          hoursWatched: analytics.hoursWatched,
          seasonCount: analytics.seasonCount,
        ));
      }
    }

    // Sort by hours watched (descending)
    topList.sort((a, b) => b.hoursWatched.compareTo(a.hoursWatched));

    return topList.take(3).toList();
  }

  Future<SimpleAnalytics> _buildFromCache(
      CachedAggregateAnalytics aggregate) async {
    final topShows = await _getTopShowsByTime();

    return SimpleAnalytics(
      totalMinutesWatched: aggregate.totalHours * 60,
      totalEpisodesWatched: aggregate.totalEpisodesWatched,
      totalShows: aggregate.totalShows,
      totalSeasons: aggregate.totalSeasons,
      topShows: topShows,
    );
  }

  // ========================================
  // Internal - Cache Updates
  // ========================================

  Future<void> _updateShowAnalytics(int showId) async {
    try {
      final show = await _showDao.getShow(showId);
      if (show == null) return;

      final watchedEpisodes = await _episodeDao.getEpisodesForShow(showId);
      final watchedCount = watchedEpisodes.where((e) => e.watched).length;

      if (watchedCount == 0) {
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

      final lastWatched = watchedEpisodes
          .where((e) => e.watched && e.watchedAt != null)
          .fold<DateTime?>(
              null,
              (prev, curr) => prev == null || curr.watchedAt!.isAfter(prev)
                  ? curr.watchedAt
                  : prev);

      final analytics = CachedShowAnalytics(
        showId: showId,
        episodesWatched: watchedCount,
        totalEpisodes: airedEpisodes.length,
        seasonCount: seasonCount,
        hoursWatched: (watchedCount * _avgEpisodeMinutes) ~/ 60,
        completionPercentage: airedEpisodes.length > 0
            ? (watchedCount / airedEpisodes.length) * 100
            : 0.0,
        lastWatchedAt: lastWatched,
        lastUpdated: DateTime.now(),
      );

      await _cacheDao.upsertShowAnalytics(analytics);
    } catch (e) {
      print('⚠️ Failed to update show analytics: $e');
    }
  }

  Future<void> _updateAggregateAnalytics() async {
    try {
      final shows = await _showDao.getAllShows();
      final allShowAnalytics = await _cacheDao.getAllShowAnalytics();

      final totalEpisodesWatched =
          allShowAnalytics.fold<int>(0, (sum, a) => sum + a.episodesWatched);
      final totalSeasons =
          allShowAnalytics.fold<int>(0, (sum, a) => sum + a.seasonCount);

      final totalMinutes = totalEpisodesWatched * _avgEpisodeMinutes;
      final totalHours = totalMinutes ~/ 60;
      final totalDays = totalHours ~/ 24;
      final totalMonths = totalDays ~/ 30;
      final remainingDays = totalDays % 30;

      final aggregate = CachedAggregateAnalytics(
        totalShows: shows.length,
        totalEpisodesWatched: totalEpisodesWatched,
        totalSeasons: totalSeasons,
        totalHours: totalHours,
        totalMonths: totalMonths,
        totalDays: remainingDays,
        overallCompletion: 0.0, // Not used
        currentStreak: 0, // Not used
        longestStreak: 0, // Not used
        daysSinceLastWatch: 0, // Not used
        lastUpdated: DateTime.now(),
      );

      await _cacheDao.upsertAggregateAnalytics(aggregate);
    } catch (e) {
      print('⚠️ Failed to update aggregate: $e');
    }
  }

  Future<void> _saveToCache(SimpleAnalytics analytics) async {
    final totalHours = analytics.totalMinutesWatched ~/ 60;
    final totalDays = totalHours ~/ 24;
    final totalMonths = totalDays ~/ 30;
    final remainingDays = totalDays % 30;

    final aggregate = CachedAggregateAnalytics(
      totalShows: analytics.totalShows,
      totalEpisodesWatched: analytics.totalEpisodesWatched,
      totalSeasons: analytics.totalSeasons,
      totalHours: totalHours,
      totalMonths: totalMonths,
      totalDays: remainingDays,
      overallCompletion: 0.0,
      currentStreak: 0,
      longestStreak: 0,
      daysSinceLastWatch: 0,
      lastUpdated: DateTime.now(),
    );

    await _cacheDao.upsertAggregateAnalytics(aggregate);
  }

  // ========================================
  // Helpers
  // ========================================

  bool _isMemoryCacheValid() {
    if (_memoryCache == null || _memoryCacheTime == null) return false;
    final age = DateTime.now().difference(_memoryCacheTime!);
    return age < _cacheValidDuration;
  }

  bool _isCacheFresh(DateTime lastUpdated) {
    final age = DateTime.now().difference(lastUpdated);
    return age.inHours < 1;
  }

  void _invalidateMemory() {
    _memoryCache = null;
    _memoryCacheTime = null;
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
}

// ========================================
// Simple Models
// ========================================

class SimpleAnalytics {
  final int totalMinutesWatched;
  final int totalEpisodesWatched;
  final int totalShows;
  final int totalSeasons;
  final List<TopShow> topShows;

  const SimpleAnalytics({
    required this.totalMinutesWatched,
    required this.totalEpisodesWatched,
    required this.totalShows,
    required this.totalSeasons,
    required this.topShows,
  });

  // Convert minutes to readable format
  TimeBreakdown get timeBreakdown {
    final hours = totalMinutesWatched ~/ 60;
    final days = hours ~/ 24;
    final years = days ~/ 365;
    final months = (days % 365) ~/ 30;
    final remainingDays = (days % 365) % 30;
    final remainingHours = hours % 24;

    return TimeBreakdown(
      years: years,
      months: months,
      days: remainingDays,
      hours: remainingHours,
      totalMinutes: totalMinutesWatched,
    );
  }
}

class TimeBreakdown {
  final int years;
  final int months;
  final int days;
  final int hours;
  final int totalMinutes;

  const TimeBreakdown({
    required this.years,
    required this.months,
    required this.days,
    required this.hours,
    required this.totalMinutes,
  });

  String get formatted {
    final parts = <String>[];
    if (years > 0) parts.add('$years ${years == 1 ? 'year' : 'years'}');
    if (months > 0) parts.add('$months ${months == 1 ? 'month' : 'months'}');
    if (days > 0) parts.add('$days ${days == 1 ? 'day' : 'days'}');
    if (hours > 0) parts.add('$hours ${hours == 1 ? 'hour' : 'hours'}');

    if (parts.isEmpty) return '0 hours';
    return parts.join(', ');
  }
}

class TopShow {
  final int showId;
  final String showName;
  final String? posterUrl;
  final int episodesWatched;
  final int hoursWatched;
  final int seasonCount;

  const TopShow({
    required this.showId,
    required this.showName,
    this.posterUrl,
    required this.episodesWatched,
    required this.hoursWatched,
    required this.seasonCount,
  });
}
