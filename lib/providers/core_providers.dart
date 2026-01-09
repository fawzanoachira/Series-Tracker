import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/data/local/app_database.dart';
import 'package:series_tracker/data/local/show_dao.dart';
import 'package:series_tracker/data/local/episode_dao.dart';
import 'package:series_tracker/repository/tracking_repository.dart';

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

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepository(
    ref.read(databaseProvider),
  );
});
