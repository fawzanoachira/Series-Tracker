/// Overview metrics showing high-level summary
class AnalyticsOverview {
  final int totalTrackedShows;
  final int totalEpisodesWatched;
  final int totalHoursWatched;
  final double overallCompletionPercentage;
  final int activeShows;
  final int completedShows;

  const AnalyticsOverview({
    required this.totalTrackedShows,
    required this.totalEpisodesWatched,
    required this.totalHoursWatched,
    required this.overallCompletionPercentage,
    required this.activeShows,
    required this.completedShows,
  });

  factory AnalyticsOverview.empty() {
    return const AnalyticsOverview(
      totalTrackedShows: 0,
      totalEpisodesWatched: 0,
      totalHoursWatched: 0,
      overallCompletionPercentage: 0.0,
      activeShows: 0,
      completedShows: 0,
    );
  }
}

/// Show status breakdown by tracking status
class ShowStatusBreakdown {
  final int watching;
  final int completed;
  final int dropped;

  const ShowStatusBreakdown({
    required this.watching,
    required this.completed,
    required this.dropped,
  });

  int get total => watching + completed + dropped;

  double get watchingPercentage => total > 0 ? (watching / total) * 100 : 0.0;
  double get completedPercentage => total > 0 ? (completed / total) * 100 : 0.0;
  double get droppedPercentage => total > 0 ? (dropped / total) * 100 : 0.0;

  factory ShowStatusBreakdown.empty() {
    return const ShowStatusBreakdown(
      watching: 0,
      completed: 0,
      dropped: 0,
    );
  }
}

/// Episode progress analytics
class EpisodeProgressAnalytics {
  final int totalEpisodesWatched;
  final int totalEpisodesRemaining;
  final int totalAvailableEpisodes;
  final double completionPercentage;

  const EpisodeProgressAnalytics({
    required this.totalEpisodesWatched,
    required this.totalEpisodesRemaining,
    required this.totalAvailableEpisodes,
    required this.completionPercentage,
  });

  factory EpisodeProgressAnalytics.empty() {
    return const EpisodeProgressAnalytics(
      totalEpisodesWatched: 0,
      totalEpisodesRemaining: 0,
      totalAvailableEpisodes: 0,
      completionPercentage: 0.0,
    );
  }
}

/// Time analytics showing watching time patterns
class TimeAnalytics {
  final int totalHoursWatched;
  final int totalMinutesWatched;
  final double averageMinutesPerDay;
  final double averageMinutesPerWeek;
  final int estimatedHoursRemaining;
  final int estimatedMinutesRemaining;

  const TimeAnalytics({
    required this.totalHoursWatched,
    required this.totalMinutesWatched,
    required this.averageMinutesPerDay,
    required this.averageMinutesPerWeek,
    required this.estimatedHoursRemaining,
    required this.estimatedMinutesRemaining,
  });

  factory TimeAnalytics.empty() {
    return const TimeAnalytics(
      totalHoursWatched: 0,
      totalMinutesWatched: 0,
      averageMinutesPerDay: 0.0,
      averageMinutesPerWeek: 0.0,
      estimatedHoursRemaining: 0,
      estimatedMinutesRemaining: 0,
    );
  }
}

/// Watching habit patterns
class WatchingHabits {
  final double episodesPerDay;
  final double episodesPerWeek;
  final Map<int, int> episodesPerDayOfWeek; // Day of week (1-7) -> count
  final WatchingPattern pattern;
  final int currentStreak;
  final int longestStreak;
  final int daysSinceLastWatch;

  const WatchingHabits({
    required this.episodesPerDay,
    required this.episodesPerWeek,
    required this.episodesPerDayOfWeek,
    required this.pattern,
    required this.currentStreak,
    required this.longestStreak,
    required this.daysSinceLastWatch,
  });

  factory WatchingHabits.empty() {
    return const WatchingHabits(
      episodesPerDay: 0.0,
      episodesPerWeek: 0.0,
      episodesPerDayOfWeek: {},
      pattern: WatchingPattern.casual,
      currentStreak: 0,
      longestStreak: 0,
      daysSinceLastWatch: 0,
    );
  }
}

enum WatchingPattern {
  binge, // Multiple episodes per day on average
  regular, // Consistent daily/weekly watching
  casual, // Sporadic viewing
}

/// Individual show insight
class ShowInsight {
  final int showId;
  final String showName;
  final String? posterUrl;
  final int episodesWatched;
  final int totalEpisodes;
  final int hoursWatched;
  final double completionPercentage;
  final DateTime? lastWatchedAt;
  final int daysSinceLastWatch;

  const ShowInsight({
    required this.showId,
    required this.showName,
    this.posterUrl,
    required this.episodesWatched,
    required this.totalEpisodes,
    required this.hoursWatched,
    required this.completionPercentage,
    this.lastWatchedAt,
    required this.daysSinceLastWatch,
  });
}

/// Upcoming episodes analytics
class UpcomingAnalytics {
  final int episodesAiringToday;
  final int episodesAiringThisWeek;
  final int episodesAiringThisMonth;
  final double weeklyUpcomingLoad;

  const UpcomingAnalytics({
    required this.episodesAiringToday,
    required this.episodesAiringThisWeek,
    required this.episodesAiringThisMonth,
    required this.weeklyUpcomingLoad,
  });

  factory UpcomingAnalytics.empty() {
    return const UpcomingAnalytics(
      episodesAiringToday: 0,
      episodesAiringThisWeek: 0,
      episodesAiringThisMonth: 0,
      weeklyUpcomingLoad: 0.0,
    );
  }
}

/// Daily activity data point
class DailyActivity {
  final DateTime date;
  final int episodesWatched;

  const DailyActivity({
    required this.date,
    required this.episodesWatched,
  });
}

/// Weekly trend data
class WeeklyTrend {
  final int weekNumber;
  final int year;
  final int episodesWatched;
  final DateTime weekStart;
  final DateTime weekEnd;

  const WeeklyTrend({
    required this.weekNumber,
    required this.year,
    required this.episodesWatched,
    required this.weekStart,
    required this.weekEnd,
  });
}

/// Complete analytics data
class CompleteAnalytics {
  final AnalyticsOverview overview;
  final ShowStatusBreakdown statusBreakdown;
  final EpisodeProgressAnalytics episodeProgress;
  final TimeAnalytics timeAnalytics;
  final WatchingHabits watchingHabits;
  final List<ShowInsight> topShows;
  final List<ShowInsight> abandonedShows;
  final UpcomingAnalytics upcoming;
  final List<DailyActivity> last30DaysActivity;
  final List<WeeklyTrend> last12WeeksTrend;

  const CompleteAnalytics({
    required this.overview,
    required this.statusBreakdown,
    required this.episodeProgress,
    required this.timeAnalytics,
    required this.watchingHabits,
    required this.topShows,
    required this.abandonedShows,
    required this.upcoming,
    required this.last30DaysActivity,
    required this.last12WeeksTrend,
  });

  factory CompleteAnalytics.empty() {
    return CompleteAnalytics(
      overview: AnalyticsOverview.empty(),
      statusBreakdown: ShowStatusBreakdown.empty(),
      episodeProgress: EpisodeProgressAnalytics.empty(),
      timeAnalytics: TimeAnalytics.empty(),
      watchingHabits: WatchingHabits.empty(),
      topShows: const [],
      abandonedShows: const [],
      upcoming: UpcomingAnalytics.empty(),
      last30DaysActivity: const [],
      last12WeeksTrend: const [],
    );
  }
}
