import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'episode_progress_provider.dart';

class ShowEpisodeStats {
  final int watched;
  final int total;

  const ShowEpisodeStats({
    required this.watched,
    required this.total,
  });

  double get progress => total == 0 ? 0 : watched / total;

  bool get isComplete => watched == total;
}

typedef ShowStatsKey = ({int showId, int totalEpisodes});

final showEpisodeStatsProvider =
    Provider.family<ShowEpisodeStats, ShowStatsKey>((ref, key) {
  final episodesAsync = ref.watch(episodeProgressProvider(key.showId));

  return episodesAsync.maybeWhen(
    data: (episodes) {
      return ShowEpisodeStats(
        watched: episodes.length,
        total: key.totalEpisodes,
      );
    },
    orElse: () => const ShowEpisodeStats(watched: 0, total: 0),
  );
});
