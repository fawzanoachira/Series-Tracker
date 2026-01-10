import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/models/tracking/tracked_episode.dart';
import 'core_providers.dart';

final episodeProgressProvider =
    FutureProvider.family<List<TrackedEpisode>, int>((ref, showId) async {
  final repo = ref.read(trackingRepositoryProvider);
  return repo.getEpisodeProgress(showId);
});
