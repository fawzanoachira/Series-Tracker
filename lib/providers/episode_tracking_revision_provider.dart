import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-show revision tracking instead of global
/// This prevents all shows from refetching when one show's episodes change
final episodeTrackingRevisionProvider =
    StateProvider.family<int, int>((ref, showId) => 0);
final analyticsRevisionProvider = StateProvider<int>((ref) => 0);
