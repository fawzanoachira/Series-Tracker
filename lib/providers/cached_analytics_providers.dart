import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/models/analytics/analytics_models.dart';
import 'package:lahv/providers/core_providers.dart';
import 'package:lahv/providers/episode_tracking_revision_provider.dart';

// ========================================
// Fast Analytics Providers (Using Cache)
// ========================================

/// Complete analytics with hybrid cache (FAST!)
final cachedCompleteAnalyticsProvider =
    FutureProvider.autoDispose<CompleteAnalytics>((ref) async {
  final cache = ref.watch(hybridAnalyticsCacheProvider);

  // 🔔 Watch analytics revision - refetches when ANY episode is marked
  ref.watch(analyticsRevisionProvider);

  return await cache.getCompleteAnalytics();
});

/// Force refresh analytics
final refreshAnalyticsProvider = FutureProvider.family<CompleteAnalytics, void>(
  (ref, _) async {
    final cache = ref.watch(hybridAnalyticsCacheProvider);
    return await cache.refresh();
  },
);

// ========================================
// Analytics Components (from cache)
// ========================================

/// Overview from cache
final cachedOverviewProvider = Provider<AnalyticsOverview>((ref) {
  final analytics = ref.watch(cachedCompleteAnalyticsProvider);
  return analytics.when(
    data: (data) => data.overview,
    loading: () => AnalyticsOverview.empty(),
    error: (_, __) => AnalyticsOverview.empty(),
  );
});

/// Status breakdown from cache
final cachedStatusBreakdownProvider = Provider<ShowStatusBreakdown>((ref) {
  final analytics = ref.watch(cachedCompleteAnalyticsProvider);
  return analytics.when(
    data: (data) => data.statusBreakdown,
    loading: () => ShowStatusBreakdown.empty(),
    error: (_, __) => ShowStatusBreakdown.empty(),
  );
});

/// Episode progress from cache
final cachedEpisodeProgressProvider = Provider<EpisodeProgressAnalytics>((ref) {
  final analytics = ref.watch(cachedCompleteAnalyticsProvider);
  return analytics.when(
    data: (data) => data.episodeProgress,
    loading: () => EpisodeProgressAnalytics.empty(),
    error: (_, __) => EpisodeProgressAnalytics.empty(),
  );
});

/// Time analytics from cache
final cachedTimeAnalyticsProvider = Provider<TimeAnalytics>((ref) {
  final analytics = ref.watch(cachedCompleteAnalyticsProvider);
  return analytics.when(
    data: (data) => data.timeAnalytics,
    loading: () => TimeAnalytics.empty(),
    error: (_, __) => TimeAnalytics.empty(),
  );
});

/// Watching habits from cache
final cachedWatchingHabitsProvider = Provider<WatchingHabits>((ref) {
  final analytics = ref.watch(cachedCompleteAnalyticsProvider);
  return analytics.when(
    data: (data) => data.watchingHabits,
    loading: () => WatchingHabits.empty(),
    error: (_, __) => WatchingHabits.empty(),
  );
});

/// Top shows from cache
final cachedTopShowsProvider = Provider<List<ShowInsight>>((ref) {
  final analytics = ref.watch(cachedCompleteAnalyticsProvider);
  return analytics.when(
    data: (data) => data.topShows,
    loading: () => const [],
    error: (_, __) => const [],
  );
});

/// Abandoned shows from cache
final cachedAbandonedShowsProvider = Provider<List<ShowInsight>>((ref) {
  final analytics = ref.watch(cachedCompleteAnalyticsProvider);
  return analytics.when(
    data: (data) => data.abandonedShows,
    loading: () => const [],
    error: (_, __) => const [],
  );
});

/// Daily activity from cache
final cachedDailyActivityProvider = Provider<List<DailyActivity>>((ref) {
  final analytics = ref.watch(cachedCompleteAnalyticsProvider);
  return analytics.when(
    data: (data) => data.last30DaysActivity,
    loading: () => const [],
    error: (_, __) => const [],
  );
});

// ========================================
// Cache Management
// ========================================

/// Invalidate cache and reload
final invalidateAnalyticsCacheProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(cachedCompleteAnalyticsProvider);
  };
});
