import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'episode_progress_provider.dart';

class NextEpisode {
  final int season;
  final int episode;

  const NextEpisode({
    required this.season,
    required this.episode,
  });
}

final nextEpisodeProvider =
    FutureProvider.family<NextEpisode?, int>((ref, showId) async {
  final episodesAsync = ref.watch(episodeProgressProvider(showId));

  // episodesAsync is AsyncValue<List<TrackedEpisode>>
  return episodesAsync.when(
    data: (episodes) {
      if (episodes.isEmpty) {
        return const NextEpisode(season: 1, episode: 1);
      }

      episodes.sort((a, b) {
        if (a.season != b.season) return a.season.compareTo(b.season);
        return a.episode.compareTo(b.episode);
      });

      final last = episodes.last;

      return NextEpisode(
        season: last.season,
        episode: last.episode + 1,
      );
    },
    loading: () => const NextEpisode(season: 1, episode: 1),
    error: (_, __) => const NextEpisode(season: 1, episode: 1),
  );
});
