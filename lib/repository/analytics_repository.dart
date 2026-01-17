import 'package:lahv/api/tracker.dart' as tracker;
import 'package:lahv/data/local/app_database.dart';
import 'package:lahv/models/analytics/analytics_models.dart';
import 'package:lahv/models/tracking/tracked_episode.dart';
import 'package:lahv/models/tracking/tracked_show.dart';
import 'package:lahv/models/tvmaze/episode.dart';

class AnalyticsRepository {
  final AppDatabase _database;

  AnalyticsRepository(this._database);

  /// Assuming average episode runtime of 45 minutes for dramas, 22 for comedies
  /// We'll use a conservative 40 minutes average
  static const int _avgEpisodeMinutes = 40;

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

      return episodeDateTime.isBefore(DateTime.now());
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

  /// Get all tracked shows from database
  Future<List<TrackedShow>> _getAllShows() async {
    final db = await _database.database;
    final result = await db.query('tracked_shows');
    return result.map((map) => TrackedShow.fromMap(map)).toList();
  }

  /// Get all tracked episodes from database
  Future<List<TrackedEpisode>> _getAllEpisodes() async {
    final db = await _database.database;
    final result = await db.query('tracked_episodes');
    return result.map((map) => TrackedEpisode.fromMap(map)).toList();
  }

  /// Get episodes for a specific show
  Future<List<TrackedEpisode>> _getEpisodesForShow(int showId) async {
    final db = await _database.database;
    final result = await db.query(
      'tracked_episodes',
      where: 'show_id = ?',
      whereArgs: [showId],
    );
    return result.map((map) => TrackedEpisode.fromMap(map)).toList();
  }

  /// Compute overview metrics
  Future<AnalyticsOverview> getOverview() async {
    final shows = await _getAllShows();
    final episodes = await _getAllEpisodes();

    final watchedEpisodes = episodes.where((e) => e.watched).length;
    final totalHours = (watchedEpisodes * _avgEpisodeMinutes) ~/ 60;

    final activeShows =
        shows.where((s) => s.status != TrackedShowStatus.completed).length;
    final completedShows =
        shows.where((s) => s.status == TrackedShowStatus.completed).length;

    // Calculate overall completion
    double overallCompletion = 0.0;
    if (shows.isNotEmpty) {
      int totalAired = 0;
      int totalWatched = 0;

      for (final show in shows) {
        try {
          final seasons = await tracker.getSeasons(show.showId);
          final List<Episode> allEpisodes = [];

          for (final season in seasons) {
            if (season.id != null) {
              final seasonEps = await tracker.getEpisodes(season.id!);
              allEpisodes.addAll(seasonEps);
            }
          }

          final aired =
              allEpisodes.where((e) => _hasEpisodeAired(e.airdate, e.airtime));
          totalAired += aired.length;

          final showEpisodes = await _getEpisodesForShow(show.showId);
          totalWatched += showEpisodes.where((e) => e.watched).length;
        } catch (e) {
          // Skip shows that fail to load
          continue;
        }
      }

      if (totalAired > 0) {
        overallCompletion = (totalWatched / totalAired) * 100;
      }
    }

    return AnalyticsOverview(
      totalTrackedShows: shows.length,
      totalEpisodesWatched: watchedEpisodes,
      totalHoursWatched: totalHours,
      overallCompletionPercentage: overallCompletion,
      activeShows: activeShows,
      completedShows: completedShows,
    );
  }

  /// Get show status breakdown
  Future<ShowStatusBreakdown> getStatusBreakdown() async {
    final shows = await _getAllShows();

    final watching =
        shows.where((s) => s.status == TrackedShowStatus.watching).length;
    final completed =
        shows.where((s) => s.status == TrackedShowStatus.completed).length;
    final dropped =
        shows.where((s) => s.status == TrackedShowStatus.dropped).length;

    return ShowStatusBreakdown(
      watching: watching,
      completed: completed,
      dropped: dropped,
    );
  }

  /// Get episode progress analytics
  Future<EpisodeProgressAnalytics> getEpisodeProgress() async {
    final shows = await _getAllShows();

    int totalWatched = 0;
    int totalAired = 0;
    int totalSeasons = 0;

    for (final show in shows) {
      try {
        final seasons = await tracker.getSeasons(show.showId);

        // Count unique seasons
        final uniqueSeasons =
            seasons.where((s) => s.number != null && s.number! > 0).length;
        totalSeasons += uniqueSeasons;

        // Fetch only first few episodes to check if show has content
        // This is much faster than fetching all episodes
        if (seasons.isEmpty) continue;

        final firstSeason = seasons.first;
        if (firstSeason.id == null) continue;

        // Quick check: if first season has episodes, count all
        final sampleEpisodes = await tracker.getEpisodes(firstSeason.id!);
        if (sampleEpisodes.isEmpty) continue;

        // Now fetch all episodes (we know show has content)
        final List<Episode> allEpisodes = [];
        for (final season in seasons) {
          if (season.id != null) {
            final seasonEps = await tracker.getEpisodes(season.id!);
            allEpisodes.addAll(seasonEps);
          }
        }

        final aired =
            allEpisodes.where((e) => _hasEpisodeAired(e.airdate, e.airtime));
        totalAired += aired.length;

        final showEpisodes = await _getEpisodesForShow(show.showId);
        totalWatched += showEpisodes.where((e) => e.watched).length;
      } catch (e) {
        continue;
      }
    }

    final remaining = totalAired - totalWatched;
    final completion = totalAired > 0 ? (totalWatched / totalAired) * 100 : 0.0;

    return EpisodeProgressAnalytics(
      totalEpisodesWatched: totalWatched,
      totalEpisodesRemaining: remaining,
      totalAvailableEpisodes: totalAired,
      totalSeasonCount: totalSeasons,
      completionPercentage: completion,
    );
  }

  /// Get time analytics
  Future<TimeAnalytics> getTimeAnalytics() async {
    final episodes = await _getAllEpisodes();
    final watchedEpisodes = episodes.where((e) => e.watched).toList();

    final totalMinutes = watchedEpisodes.length * _avgEpisodeMinutes;
    final totalHours = totalMinutes ~/ 60;

    // Calculate months and days
    final totalDays = totalHours ~/ 24;
    final totalMonths = totalDays ~/ 30;
    final remainingDays = totalDays % 30;

    // Calculate time span
    double avgMinutesPerDay = 0.0;
    double avgMinutesPerWeek = 0.0;

    if (watchedEpisodes.isNotEmpty) {
      final validWatchedEpisodes =
          watchedEpisodes.where((e) => e.watchedAt != null).toList();

      if (validWatchedEpisodes.isNotEmpty) {
        final oldestWatch = validWatchedEpisodes
            .reduce((a, b) => a.watchedAt!.isBefore(b.watchedAt!) ? a : b)
            .watchedAt!;
        final daysSinceStart = DateTime.now().difference(oldestWatch).inDays;

        if (daysSinceStart > 0) {
          avgMinutesPerDay = totalMinutes / daysSinceStart;
          avgMinutesPerWeek = avgMinutesPerDay * 7;
        }
      }
    }

    // Calculate remaining time
    final progress = await getEpisodeProgress();
    final remainingMinutes =
        progress.totalEpisodesRemaining * _avgEpisodeMinutes;
    final remainingHours = remainingMinutes ~/ 60;

    return TimeAnalytics(
      totalHoursWatched: totalHours,
      totalMinutesWatched: totalMinutes,
      totalMonths: totalMonths,
      totalDays: remainingDays, // Days remaining after months
      averageMinutesPerDay: avgMinutesPerDay,
      averageMinutesPerWeek: avgMinutesPerWeek,
      estimatedHoursRemaining: remainingHours,
      estimatedMinutesRemaining: remainingMinutes,
    );
  }

  /// Get watching habits
  Future<WatchingHabits> getWatchingHabits() async {
    final episodes = await _getAllEpisodes();
    final watchedEpisodes =
        episodes.where((e) => e.watched && e.watchedAt != null).toList();

    if (watchedEpisodes.isEmpty) {
      return WatchingHabits.empty();
    }

    // Sort by watch date
    watchedEpisodes.sort((a, b) => a.watchedAt!.compareTo(b.watchedAt!));

    final oldest = watchedEpisodes.first.watchedAt!;
    final newest = watchedEpisodes.last.watchedAt!;
    final daysSinceStart = DateTime.now().difference(oldest).inDays;
    final daysSinceLastWatch = DateTime.now().difference(newest).inDays;

    final episodesPerDay = daysSinceStart > 0
        ? watchedEpisodes.length / daysSinceStart
        : watchedEpisodes.length.toDouble();
    final episodesPerWeek = episodesPerDay * 7;

    // Calculate episodes per day of week
    final Map<int, int> episodesPerDayOfWeek = {};
    for (var episode in watchedEpisodes) {
      final dayOfWeek = episode.watchedAt!.weekday;
      episodesPerDayOfWeek[dayOfWeek] =
          (episodesPerDayOfWeek[dayOfWeek] ?? 0) + 1;
    }

    // Determine pattern
    WatchingPattern pattern;
    if (episodesPerDay >= 2) {
      pattern = WatchingPattern.binge;
    } else if (episodesPerDay >= 0.5) {
      pattern = WatchingPattern.regular;
    } else {
      pattern = WatchingPattern.casual;
    }

    // Calculate streaks
    final streakData = _calculateStreaks(watchedEpisodes);

    return WatchingHabits(
      episodesPerDay: episodesPerDay,
      episodesPerWeek: episodesPerWeek,
      episodesPerDayOfWeek: episodesPerDayOfWeek,
      pattern: pattern,
      currentStreak: streakData.currentStreak,
      longestStreak: streakData.longestStreak,
      daysSinceLastWatch: daysSinceLastWatch,
    );
  }

  /// Calculate current and longest streaks
  ({int currentStreak, int longestStreak}) _calculateStreaks(
    List<TrackedEpisode> watchedEpisodes,
  ) {
    if (watchedEpisodes.isEmpty) {
      return (currentStreak: 0, longestStreak: 0);
    }

    // Group episodes by date
    final Map<DateTime, int> episodesByDate = {};
    for (var episode in watchedEpisodes) {
      final date = DateTime(
        episode.watchedAt!.year,
        episode.watchedAt!.month,
        episode.watchedAt!.day,
      );
      episodesByDate[date] = (episodesByDate[date] ?? 0) + 1;
    }

    final sortedDates = episodesByDate.keys.toList()..sort();

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 1;

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // Check if there's activity today or yesterday for current streak
    final lastDate = sortedDates.last;
    final daysSinceLastWatch = today.difference(lastDate).inDays;

    if (daysSinceLastWatch <= 1) {
      currentStreak = 1;

      // Count backwards
      for (int i = sortedDates.length - 2; i >= 0; i--) {
        final diff = sortedDates[i + 1].difference(sortedDates[i]).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          break;
        }
      }
    }

    // Calculate longest streak
    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        tempStreak++;
      } else {
        longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
        tempStreak = 1;
      }
    }
    longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

    return (currentStreak: currentStreak, longestStreak: longestStreak);
  }

  /// Get top shows by episodes watched
  Future<List<ShowInsight>> getTopShows({int limit = 3}) async {
    final shows = await _getAllShows();
    final insights = <ShowInsight>[];

    for (final show in shows) {
      try {
        final episodes = await _getEpisodesForShow(show.showId);
        final watchedEps = episodes.where((e) => e.watched).toList();

        if (watchedEps.isEmpty) continue;

        final seasons = await tracker.getSeasons(show.showId);

        // Count unique seasons
        final seasonCount =
            seasons.where((s) => s.number != null && s.number! > 0).length;

        final List<Episode> allEpisodes = [];

        for (final season in seasons) {
          if (season.id != null) {
            final seasonEps = await tracker.getEpisodes(season.id!);
            allEpisodes.addAll(seasonEps);
          }
        }

        final totalAired =
            allEpisodes.where((e) => _hasEpisodeAired(e.airdate, e.airtime));

        final lastWatched =
            watchedEps.where((e) => e.watchedAt != null).fold<TrackedEpisode?>(
                  null,
                  (prev, curr) =>
                      prev == null || curr.watchedAt!.isAfter(prev.watchedAt!)
                          ? curr
                          : prev,
                );

        final daysSince = lastWatched != null
            ? DateTime.now().difference(lastWatched.watchedAt!).inDays
            : 0;

        insights.add(ShowInsight(
          showId: show.showId,
          showName: show.name,
          posterUrl: show.posterUrl,
          episodesWatched: watchedEps.length,
          totalEpisodes: totalAired.length,
          seasonCount: seasonCount,
          hoursWatched: (watchedEps.length * _avgEpisodeMinutes) ~/ 60,
          completionPercentage: totalAired.isNotEmpty
              ? (watchedEps.length / totalAired.length) * 100
              : 0.0,
          lastWatchedAt: lastWatched?.watchedAt,
          daysSinceLastWatch: daysSince,
        ));
      } catch (e) {
        continue;
      }
    }

    insights.sort((a, b) => b.episodesWatched.compareTo(a.episodesWatched));
    return insights.take(limit).toList();
  }

  /// Get abandoned shows (started but not watched in 30+ days)
  Future<List<ShowInsight>> getAbandonedShows({int daysSince = 30}) async {
    final shows = await _getAllShows();
    final insights = <ShowInsight>[];

    for (final show in shows) {
      if (show.status == TrackedShowStatus.completed ||
          show.status == TrackedShowStatus.dropped) {
        continue;
      }

      try {
        final episodes = await _getEpisodesForShow(show.showId);
        final watchedEps = episodes.where((e) => e.watched).toList();

        if (watchedEps.isEmpty) continue;

        final lastWatched =
            watchedEps.where((e) => e.watchedAt != null).fold<TrackedEpisode?>(
                  null,
                  (prev, curr) =>
                      prev == null || curr.watchedAt!.isAfter(prev.watchedAt!)
                          ? curr
                          : prev,
                );

        if (lastWatched == null) continue;

        final daysSinceWatch =
            DateTime.now().difference(lastWatched.watchedAt!).inDays;

        if (daysSinceWatch >= daysSince) {
          final seasons = await tracker.getSeasons(show.showId);

          // Count unique seasons
          final seasonCount =
              seasons.where((s) => s.number != null && s.number! > 0).length;

          final List<Episode> allEpisodes = [];

          for (final season in seasons) {
            if (season.id != null) {
              final seasonEps = await tracker.getEpisodes(season.id!);
              allEpisodes.addAll(seasonEps);
            }
          }

          final totalAired =
              allEpisodes.where((e) => _hasEpisodeAired(e.airdate, e.airtime));

          insights.add(ShowInsight(
            showId: show.showId,
            showName: show.name,
            posterUrl: show.posterUrl,
            episodesWatched: watchedEps.length,
            totalEpisodes: totalAired.length,
            seasonCount: seasonCount,
            hoursWatched: (watchedEps.length * _avgEpisodeMinutes) ~/ 60,
            completionPercentage: totalAired.isNotEmpty
                ? (watchedEps.length / totalAired.length) * 100
                : 0.0,
            lastWatchedAt: lastWatched.watchedAt,
            daysSinceLastWatch: daysSinceWatch,
          ));
        }
      } catch (e) {
        continue;
      }
    }

    insights
        .sort((a, b) => b.daysSinceLastWatch.compareTo(a.daysSinceLastWatch));
    return insights;
  }

  /// Get upcoming episodes analytics
  Future<UpcomingAnalytics> getUpcomingAnalytics() async {
    final shows = await _getAllShows()
      ..removeWhere((s) =>
          s.status == TrackedShowStatus.completed ||
          s.status == TrackedShowStatus.dropped);

    int airingToday = 0;
    int airingThisWeek = 0;
    int airingThisMonth = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));
    final monthEnd = today.add(const Duration(days: 30));

    for (final show in shows) {
      try {
        final seasons = await tracker.getSeasons(show.showId);
        final watchedEpisodes = await _getEpisodesForShow(show.showId);
        final watchedSet =
            watchedEpisodes.map((e) => '${e.season}-${e.episode}').toSet();

        for (final season in seasons) {
          if (season.id != null) {
            final episodes = await tracker.getEpisodes(season.id!);

            for (final ep in episodes) {
              final key = '${ep.season ?? 0}-${ep.number ?? 0}';
              if (watchedSet.contains(key)) continue;

              if (ep.airdate == null) continue;

              try {
                final airDate = DateTime.parse(ep.airdate!);
                final epDate =
                    DateTime(airDate.year, airDate.month, airDate.day);

                if (epDate.isAtSameMomentAs(today)) {
                  airingToday++;
                  airingThisWeek++;
                  airingThisMonth++;
                } else if (epDate.isAfter(today) && epDate.isBefore(weekEnd)) {
                  airingThisWeek++;
                  airingThisMonth++;
                } else if (epDate.isAfter(today) && epDate.isBefore(monthEnd)) {
                  airingThisMonth++;
                }
              } catch (e) {
                continue;
              }
            }
          }
        }
      } catch (e) {
        continue;
      }
    }

    final habits = await getWatchingHabits();
    final weeklyLoad = habits.episodesPerWeek > 0
        ? (airingThisWeek / habits.episodesPerWeek) * 100
        : 0.0;

    return UpcomingAnalytics(
      episodesAiringToday: airingToday,
      episodesAiringThisWeek: airingThisWeek,
      episodesAiringThisMonth: airingThisMonth,
      weeklyUpcomingLoad: weeklyLoad,
    );
  }

  /// Get last 30 days activity
  Future<List<DailyActivity>> getLast30DaysActivity() async {
    final episodes = await _getAllEpisodes();
    final watchedEpisodes =
        episodes.where((e) => e.watched && e.watchedAt != null).toList();

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final Map<DateTime, int> activityMap = {};

    // Initialize all days with 0
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      activityMap[dateOnly] = 0;
    }

    // Count episodes per day
    for (var episode in watchedEpisodes) {
      if (episode.watchedAt!.isAfter(thirtyDaysAgo)) {
        final dateOnly = DateTime(
          episode.watchedAt!.year,
          episode.watchedAt!.month,
          episode.watchedAt!.day,
        );
        activityMap[dateOnly] = (activityMap[dateOnly] ?? 0) + 1;
      }
    }

    final activities = activityMap.entries
        .map((e) => DailyActivity(date: e.key, episodesWatched: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return activities;
  }

  /// Get last 12 weeks trend
  Future<List<WeeklyTrend>> getLast12WeeksTrend() async {
    final episodes = await _getAllEpisodes();
    final watchedEpisodes =
        episodes.where((e) => e.watched && e.watchedAt != null).toList();

    final now = DateTime.now();
    final trends = <WeeklyTrend>[];

    for (int i = 0; i < 12; i++) {
      final weekStart = now.subtract(Duration(days: 7 * (i + 1)));
      final weekEnd = now.subtract(Duration(days: 7 * i));

      final weekEpisodes = watchedEpisodes.where((e) =>
          e.watchedAt!.isAfter(weekStart) && e.watchedAt!.isBefore(weekEnd));

      // Get week number and year
      final weekNumber = _getWeekNumber(weekStart);

      trends.add(WeeklyTrend(
        weekNumber: weekNumber,
        year: weekStart.year,
        episodesWatched: weekEpisodes.length,
        weekStart: weekStart,
        weekEnd: weekEnd,
      ));
    }

    return trends.reversed.toList();
  }

  /// Get ISO week number
  int _getWeekNumber(DateTime date) {
    final dayOfYear =
        int.parse(date.difference(DateTime(date.year, 1, 1)).inDays.toString());
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Get complete analytics
  Future<CompleteAnalytics> getCompleteAnalytics() async {
    final overview = await getOverview();
    final statusBreakdown = await getStatusBreakdown();
    final episodeProgress = await getEpisodeProgress();
    final timeAnalytics = await getTimeAnalytics();
    final watchingHabits = await getWatchingHabits();
    final topShows = await getTopShows();
    final abandonedShows = await getAbandonedShows();
    final upcoming = await getUpcomingAnalytics();
    final last30Days = await getLast30DaysActivity();
    final last12Weeks = await getLast12WeeksTrend();

    return CompleteAnalytics(
      overview: overview,
      statusBreakdown: statusBreakdown,
      episodeProgress: episodeProgress,
      timeAnalytics: timeAnalytics,
      watchingHabits: watchingHabits,
      topShows: topShows,
      abandonedShows: abandonedShows,
      upcoming: upcoming,
      last30DaysActivity: last30Days,
      last12WeeksTrend: last12Weeks,
    );
  }
}
