import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'episode_progress_provider.dart';

typedef EpisodeKey = ({int showId, int season, int episode});

final isEpisodeWatchedProvider = Provider.family<bool, EpisodeKey>((ref, key) {
  final progress = ref.watch(episodeProgressProvider(key.showId));

  return progress.maybeWhen(
    data: (episodes) => episodes.any(
      (e) => e.season == key.season && e.episode == key.episode,
    ),
    orElse: () => false,
  );
});
