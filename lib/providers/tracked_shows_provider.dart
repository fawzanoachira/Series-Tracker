import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/models/tracking/tracked_show.dart';
import 'core_providers.dart';

final trackedShowsProvider = FutureProvider<List<TrackedShow>>((ref) async {
  final repo = ref.read(trackingRepositoryProvider);
  return repo.getTrackedShows();
});
