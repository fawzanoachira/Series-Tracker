import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';

typedef EpisodeKey = ({int showId, int season, int episode});

final isEpisodeWatchedProvider =
    FutureProvider.family<bool, EpisodeKey>((ref, key) async {
  final repo = ref.read(trackingRepositoryProvider);
  return repo.isEpisodeWatched(
    showId: key.showId,
    season: key.season,
    episode: key.episode,
  );
});
