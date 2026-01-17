/// Cached analytics for individual shows
class CachedShowAnalytics {
  final int showId;
  final int episodesWatched;
  final int totalEpisodes;
  final int seasonCount;
  final int hoursWatched;
  final double completionPercentage;
  final DateTime? lastWatchedAt;
  final DateTime lastUpdated;

  const CachedShowAnalytics({
    required this.showId,
    required this.episodesWatched,
    required this.totalEpisodes,
    required this.seasonCount,
    required this.hoursWatched,
    required this.completionPercentage,
    this.lastWatchedAt,
    required this.lastUpdated,
  });

  factory CachedShowAnalytics.fromMap(Map<String, dynamic> map) {
    return CachedShowAnalytics(
      showId: map['show_id'] as int,
      episodesWatched: map['episodes_watched'] as int,
      totalEpisodes: map['total_episodes'] as int,
      seasonCount: map['season_count'] as int,
      hoursWatched: map['hours_watched'] as int,
      completionPercentage: map['completion_percentage'] as double,
      lastWatchedAt: map['last_watched_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_watched_at'] as int)
          : null,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        map['last_updated'] as int,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'show_id': showId,
      'episodes_watched': episodesWatched,
      'total_episodes': totalEpisodes,
      'season_count': seasonCount,
      'hours_watched': hoursWatched,
      'completion_percentage': completionPercentage,
      'last_watched_at': lastWatchedAt?.millisecondsSinceEpoch,
      'last_updated': lastUpdated.millisecondsSinceEpoch,
    };
  }
}

/// Cached aggregate analytics
class CachedAggregateAnalytics {
  final int totalShows;
  final int totalEpisodesWatched;
  final int totalSeasons;
  final int totalHours;
  final int totalMonths;
  final int totalDays;
  final double overallCompletion;
  final int currentStreak;
  final int longestStreak;
  final int daysSinceLastWatch;
  final DateTime lastUpdated;

  const CachedAggregateAnalytics({
    required this.totalShows,
    required this.totalEpisodesWatched,
    required this.totalSeasons,
    required this.totalHours,
    required this.totalMonths,
    required this.totalDays,
    required this.overallCompletion,
    required this.currentStreak,
    required this.longestStreak,
    required this.daysSinceLastWatch,
    required this.lastUpdated,
  });

  factory CachedAggregateAnalytics.fromMap(Map<String, dynamic> map) {
    return CachedAggregateAnalytics(
      totalShows: map['total_shows'] as int,
      totalEpisodesWatched: map['total_episodes_watched'] as int,
      totalSeasons: map['total_seasons'] as int,
      totalHours: map['total_hours'] as int,
      totalMonths: map['total_months'] as int,
      totalDays: map['total_days'] as int,
      overallCompletion: map['overall_completion'] as double,
      currentStreak: map['current_streak'] as int,
      longestStreak: map['longest_streak'] as int,
      daysSinceLastWatch: map['days_since_last_watch'] as int,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        map['last_updated'] as int,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1, // Single row
      'total_shows': totalShows,
      'total_episodes_watched': totalEpisodesWatched,
      'total_seasons': totalSeasons,
      'total_hours': totalHours,
      'total_months': totalMonths,
      'total_days': totalDays,
      'overall_completion': overallCompletion,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'days_since_last_watch': daysSinceLastWatch,
      'last_updated': lastUpdated.millisecondsSinceEpoch,
    };
  }
}

/// Cached daily activity for heatmap
class CachedDailyActivity {
  final DateTime date;
  final int episodesCount;

  const CachedDailyActivity({
    required this.date,
    required this.episodesCount,
  });

  factory CachedDailyActivity.fromMap(Map<String, dynamic> map) {
    return CachedDailyActivity(
      date: DateTime.parse(map['date'] as String),
      episodesCount: map['episodes_count'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': _formatDate(date),
      'episodes_count': episodesCount,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
