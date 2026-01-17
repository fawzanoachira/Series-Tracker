import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/models/analytics/analytics_models.dart';
import 'package:lahv/providers/core_providers.dart';
import 'package:lahv/repository/analytics_repository.dart';

// Analytics Repository Provider
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return AnalyticsRepository(database);
});

// Complete Analytics Provider
final completeAnalyticsProvider =
    FutureProvider<CompleteAnalytics>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getCompleteAnalytics();
});

// Overview Provider
final analyticsOverviewProvider =
    FutureProvider<AnalyticsOverview>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getOverview();
});

// Status Breakdown Provider
final statusBreakdownProvider =
    FutureProvider<ShowStatusBreakdown>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getStatusBreakdown();
});

// Episode Progress Provider
final episodeProgressAnalyticsProvider =
    FutureProvider<EpisodeProgressAnalytics>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getEpisodeProgress();
});

// Time Analytics Provider
final timeAnalyticsProvider = FutureProvider<TimeAnalytics>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getTimeAnalytics();
});

// Watching Habits Provider
final watchingHabitsProvider = FutureProvider<WatchingHabits>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getWatchingHabits();
});

// Top Shows Provider
final topShowsProvider = FutureProvider<List<ShowInsight>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getTopShows(limit: 5);
});

// Abandoned Shows Provider
final abandonedShowsProvider = FutureProvider<List<ShowInsight>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getAbandonedShows(daysSince: 30);
});

// Upcoming Analytics Provider
final upcomingAnalyticsProvider =
    FutureProvider<UpcomingAnalytics>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getUpcomingAnalytics();
});

// Last 30 Days Activity Provider
final last30DaysActivityProvider =
    FutureProvider<List<DailyActivity>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getLast30DaysActivity();
});

// Last 12 Weeks Trend Provider
final last12WeeksTrendProvider = FutureProvider<List<WeeklyTrend>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getLast12WeeksTrend();
});
