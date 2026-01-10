import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/api/tracker.dart';
import 'package:series_tracker/models/tvmaze/show.dart';

final showDetailProvider =
    FutureProvider.family<Show, int>((ref, showId) async {
  return getShow(showId);
});
