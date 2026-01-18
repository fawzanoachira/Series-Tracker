import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/providers/core_providers.dart';
import 'package:lahv/providers/episode_tracking_revision_provider.dart';
import 'package:lahv/services/hybrid_analytics_cache.dart';

// ========================================
// Simple Analytics Provider
// ========================================

/// Main analytics provider - auto-refreshes when episodes are marked
final simpleAnalyticsProvider =
    FutureProvider.autoDispose<SimpleAnalytics>((ref) async {
  final cache = ref.watch(hybridAnalyticsCacheProvider);

  // Watch analytics revision - refetches when ANY episode is marked
  ref.watch(analyticsRevisionProvider);

  return await cache.getAnalytics();
});

/// Helper to clear cache
final clearAnalyticsCacheProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final cache = ref.read(hybridAnalyticsCacheProvider);
    await cache.clearCache();
    ref.invalidate(simpleAnalyticsProvider);
  };
});

/// Helper to rebuild cache for all shows (one-time use for old data)
final rebuildAllShowCacheProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final cache = ref.read(hybridAnalyticsCacheProvider);
    await cache.rebuildAllShowCache();
    ref.invalidate(simpleAnalyticsProvider);
  };
});
