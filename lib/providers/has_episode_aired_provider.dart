import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/models/tvmaze/episode.dart';

/// Provider to check if an episode has aired
/// Considers both airdate and airtime if available
final hasEpisodeAiredProvider = Provider.family<bool, Episode>((ref, episode) {
  return _hasEpisodeAired(episode.airdate, episode.airtime);
});

/// Helper method to check if an episode has aired
/// Considers both airdate and airtime if available
bool _hasEpisodeAired(String? airdate, [String? airtime]) {
  if (airdate == null || airdate.isEmpty) {
    return false; // If no airdate, consider it not aired
  }

  try {
    DateTime episodeDateTime;

    if (airtime != null && airtime.isNotEmpty) {
      // Combine airdate and airtime (format: "HH:MM")
      // TVMaze uses local time for the show's network
      final dateParts = airdate.split('-');
      final timeParts = airtime.split(':');

      episodeDateTime = DateTime(
        int.parse(dateParts[0]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[2]), // day
        int.parse(timeParts[0]), // hour
        timeParts.length > 1 ? int.parse(timeParts[1]) : 0, // minute
      );
    } else {
      // Only airdate available, assume end of day
      episodeDateTime =
          DateTime.parse(airdate).add(const Duration(hours: 23, minutes: 59));
    }

    final now = DateTime.now();

    // Episode has aired if the datetime is in the past
    return episodeDateTime.isBefore(now);
  } catch (e) {
    // If parsing fails, fall back to date-only comparison
    try {
      final episodeDate = DateTime.parse(airdate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final epDate =
          DateTime(episodeDate.year, episodeDate.month, episodeDate.day);

      return epDate.isBefore(today);
    } catch (e) {
      return false; // If all parsing fails, consider it not aired
    }
  }
}
