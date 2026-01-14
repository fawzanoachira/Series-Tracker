import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/models/tracking/tracked_show.dart';
import 'package:series_tracker/providers/tracked_shows_provider.dart';
import 'package:series_tracker/screens/watchlist/widgets/tracked_show_list_tile.dart';

class MyShowsScreen extends ConsumerWidget {
  const MyShowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackedShowsAsync = ref.watch(trackedShowsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shows'),
      ),
      body: trackedShowsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (shows) {
          if (shows.isEmpty) {
            return const Center(
              child: Text('No shows tracked yet'),
            );
          }

          // Group shows by status
          final watchingShows = shows
              .where((show) => show.status == TrackedShowStatus.watching)
              .toList();
          final completedShows = shows
              .where((show) => show.status == TrackedShowStatus.completed)
              .toList();
          final droppedShows = shows
              .where((show) => show.status == TrackedShowStatus.dropped)
              .toList();

          return ListView(
            children: [
              if (watchingShows.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Watching',
                  count: watchingShows.length,
                  color: Colors.blue,
                ),
                ...watchingShows.map((show) => TrackedShowListTile(show: show)),
                const SizedBox(height: 16),
              ],
              if (completedShows.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Completed',
                  count: completedShows.length,
                  color: Colors.green,
                ),
                ...completedShows
                    .map((show) => TrackedShowListTile(show: show)),
                const SizedBox(height: 16),
              ],
              if (droppedShows.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Dropped',
                  count: droppedShows.length,
                  color: Colors.grey,
                ),
                ...droppedShows.map((show) => TrackedShowListTile(show: show)),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: color.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
