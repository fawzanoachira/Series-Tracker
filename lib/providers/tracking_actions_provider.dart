import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/models/tvmaze/show.dart';
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

      // 🔁 refresh tracked shows
      ref.invalidate(trackedShowsProvider);

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

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final trackingActionsProvider =
    AsyncNotifierProvider<TrackingActions, void>(
  TrackingActions.new,
);
