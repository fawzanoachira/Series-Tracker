import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/models/tvmaze/show.dart';
import 'package:series_tracker/providers/episode_tracking_revision_provider.dart';
import 'package:series_tracker/providers/is_show_tracked_provider.dart';
import 'core_providers.dart';
import 'tracked_shows_provider.dart';

class TrackingActions extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // no-op (actions only)
  }

  Future<void> addShow(Show show) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(trackingRepositoryProvider);
      await repo.addShow(show);

      ref.invalidate(trackedShowsProvider);
      ref.invalidate(isShowTrackedProvider(show.id!));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> removeShow(int showId) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(trackingRepositoryProvider);
      await repo.removeShow(showId);

      ref.invalidate(trackedShowsProvider);
      ref.invalidate(isShowTrackedProvider(showId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ---------------- EPISODES ----------------

  Future<void> markEpisodeWatched({
    required int showId,
    required int season,
    required int episode,
  }) async {
    final repo = ref.read(trackingRepositoryProvider);

    await repo.markEpisodeWatched(
      showId: showId,
      season: season,
      episode: episode,
    );

    // Increment only THIS show's revision counter
    ref.read(episodeTrackingRevisionProvider(showId).notifier).state++;

    // Check if show should be marked as completed
    await _checkAndUpdateShowStatus(showId);
  }

  Future<void> markEpisodeUnwatched({
    required int showId,
    required int season,
    required int episode,
  }) async {
    final repo = ref.read(trackingRepositoryProvider);

    await repo.markEpisodeUnwatched(
      showId: showId,
      season: season,
      episode: episode,
    );

    // Increment only THIS show's revision counter
    ref.read(episodeTrackingRevisionProvider(showId).notifier).state++;

    // Check if show should be moved back to watching
    await _checkAndUpdateShowStatus(showId);
  }

  /// Checks if a show should be marked as completed and updates it automatically
  Future<void> _checkAndUpdateShowStatus(int showId) async {
    try {
      final repo = ref.read(trackingRepositoryProvider);
      final bool statusChanged =
          await repo.checkAndUpdateShowCompletion(showId);

      // Only invalidate if status actually changed
      if (statusChanged == true) {
        ref.invalidate(trackedShowsProvider);
      }
    } catch (e) {
      // Silently fail - this is a background check
    }
  }
}

final trackingActionsProvider = AsyncNotifierProvider<TrackingActions, void>(
  TrackingActions.new,
);
