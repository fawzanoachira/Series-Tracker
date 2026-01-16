import 'package:series_tracker/models/tvmaze/episode.dart';

class UpcomingEpisode {
  final int showId;
  final String showName;
  final String? posterUrl;
  final Episode episode;
  final DateTime? airDate;
  final String? airTime;

  UpcomingEpisode({
    required this.showId,
    required this.showName,
    this.posterUrl,
    required this.episode,
    this.airDate,
    this.airTime,
  });

  String get episodeIdentifier {
    final season = episode.season ?? 0;
    final number = episode.number ?? 0;
    return 'S${season.toString().padLeft(2, '0')}E${number.toString().padLeft(2, '0')}';
  }

  bool get isToday {
    if (airDate == null) return false;
    final now = DateTime.now();
    return airDate!.year == now.year &&
        airDate!.month == now.month &&
        airDate!.day == now.day;
  }

  bool get isPast {
    if (airDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final epDate = DateTime(airDate!.year, airDate!.month, airDate!.day);
    return epDate.isBefore(today);
  }

  /// Get number of days until air date
  int get daysUntilAir {
    if (airDate == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final epDate = DateTime(airDate!.year, airDate!.month, airDate!.day);

    return epDate.difference(today).inDays;
  }

  /// Get formatted days left text
  String get daysLeftText {
    if (airDate == null) return 'Unknown';

    final days = daysUntilAir;

    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days < 0) return 'Aired';

    // Show exact day count for all future episodes
    if (days == 2) return 'In 2 days';
    return 'in $days days';
  }

  /// Check if this is the first episode of a new season
  bool get isNewSeason {
    return episode.number == 1;
  }

  String get formattedAirDate {
    if (airDate == null) return 'TBA';

    final now = DateTime.now();
    final difference = airDate!.difference(now);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays == -1) {
      return 'Yesterday';
    } else if (difference.inDays < 0) {
      return 'Aired';
    } else if (difference.inDays <= 7) {
      // Show day of week for this week
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[airDate!.weekday - 1];
    } else {
      // Show date
      final month = airDate!.month.toString().padLeft(2, '0');
      final day = airDate!.day.toString().padLeft(2, '0');
      return '$month/$day';
    }
  }
}
