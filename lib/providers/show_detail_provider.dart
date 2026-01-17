import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/api/tracker.dart';
import 'package:lahv/models/tvmaze/show.dart';

final showDetailProvider =
    FutureProvider.family<Show, int>((ref, showId) async {
  return getShow(showId);
});
