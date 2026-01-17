import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/models/tracking/tracked_episode.dart';
import 'core_providers.dart';
import 'episode_tracking_revision_provider.dart';

final episodeProgressProvider =
    FutureProvider.family<List<TrackedEpisode>, int>((ref, showId) async {
  // Watch only THIS show's revision, not all shows
  ref.watch(episodeTrackingRevisionProvider(showId));

  final repo = ref.read(trackingRepositoryProvider);
  return repo.getEpisodeProgress(showId);
});

// Add this extension to make it easier to keep previous data
extension KeepAliveExtension on Ref {
  void keepAlive() {
    onDispose(() {});
  }
}
