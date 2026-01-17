import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/models/tracking/season_episode_stats.dart';
import 'episode_progress_provider.dart';

typedef SeasonKey = ({int showId, int season, int totalEpisodes});

final seasonEpisodeStatsProvider =
    Provider.family<SeasonEpisodeStats, SeasonKey>((ref, key) {
  final episodesAsync = ref.watch(episodeProgressProvider(key.showId));

  return episodesAsync.when(
    loading: () => SeasonEpisodeStats.loading(),
    error: (_, __) => SeasonEpisodeStats.error(),
    data: (episodes) {
      final watchedInSeason =
          episodes.where((e) => e.season == key.season).length;

      return SeasonEpisodeStats(
        season: key.season,
        watched: watchedInSeason,
        total: key.totalEpisodes,
      );
    },
  );
});
