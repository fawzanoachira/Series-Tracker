import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/data/local/app_database.dart';
import 'package:lahv/data/local/show_dao.dart';
import 'package:lahv/data/local/episode_dao.dart';
import 'package:lahv/repository/tracking_repository.dart';
import 'package:lahv/services/hybrid_analytics_cache.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final showDaoProvider = Provider<ShowDao>((ref) {
  final db = ref.read(databaseProvider);
  return ShowDao(db);
});

final episodeDaoProvider = Provider<EpisodeDao>((ref) {
  final db = ref.read(databaseProvider);
  return EpisodeDao(db);
});

final hybridAnalyticsCacheProvider = Provider<HybridAnalyticsCache>((ref) {
  final database = ref.watch(databaseProvider);
  return HybridAnalyticsCache(database);
});

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepository(
    ref.read(databaseProvider),
    ref.read(hybridAnalyticsCacheProvider),
  );
});
