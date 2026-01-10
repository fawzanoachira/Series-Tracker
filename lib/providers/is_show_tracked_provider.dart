import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';

final isShowTrackedProvider =
    FutureProvider.family<bool, int>((ref, showId) async {
  final repo = ref.read(trackingRepositoryProvider);
  return repo.isShowTracked(showId);
});
