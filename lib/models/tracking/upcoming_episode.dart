import 'package:series_tracker/models/tvmaze/episode.dart';

/// Model representing an upcoming episode for a tracked show
class UpcomingEpisode {
  final int showId;
  final String showName;
  final String? posterUrl;
  final Episode episode;
  final DateTime? airDate;
  final String? airTime;

  const UpcomingEpisode({
    required this.showId,
    required this.showName,
    required this.posterUrl,
    required this.episode,
    required this.airDate,
    required this.airTime,
  });

  /// Check if episode airs today
  bool get isToday {
    if (airDate == null) return false;
    final now = DateTime.now();
    return airDate!.year == now.year &&
        airDate!.month == now.month &&
        airDate!.day == now.day;
  }

  /// Check if episode aired in the past
  bool get isPast {
    if (airDate == null) return false;
    return airDate!.isBefore(DateTime.now());
  }

  /// Get days until air date (negative if already aired)
  int? get daysUntilAir {
    if (airDate == null) return null;
    final now = DateTime.now();
    final difference =
        airDate!.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  /// Format air date for display
  String get formattedAirDate {
    if (airDate == null) return 'TBA';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final episodeDate = DateTime(airDate!.year, airDate!.month, airDate!.day);

    if (episodeDate == today) return 'Today';
    if (episodeDate == tomorrow) return 'Tomorrow';

    final daysUntil = daysUntilAir;
    if (daysUntil != null && daysUntil > 0 && daysUntil <= 7) {
      return 'In $daysUntil day${daysUntil == 1 ? '' : 's'}';
    }

    // Format as "Jan 15" or "Jan 15, 2026" if different year
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final month = monthNames[airDate!.month - 1];
    final day = airDate!.day;

    if (airDate!.year != now.year) {
      return '$month $day, ${airDate!.year}';
    }

    return '$month $day';
  }

  /// Episode identifier (e.g., "S01E01")
  String get episodeIdentifier {
    final s = (episode.season ?? 0).toString().padLeft(2, '0');
    final e = (episode.number ?? 0).toString().padLeft(2, '0');
    return 'S${s}E$e';
  }
}
