import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/models/tracking/tracked_show.dart';
import 'package:series_tracker/providers/tracked_shows_provider.dart';
import 'package:series_tracker/screens/show_detail_screen/show_detail_screen.dart';
import 'package:series_tracker/models/tvmaze/show.dart';
import 'package:series_tracker/models/tvmaze/image_tvmaze.dart';

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
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(trackedShowsProvider);
                await ref.read(trackedShowsProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: const Center(
                    child: Text('No shows tracked yet'),
                  ),
                ),
              ),
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

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(trackedShowsProvider);
              await ref.read(trackedShowsProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (watchingShows.isNotEmpty) ...[
                  _SectionSliverHeader(
                    title: 'Watching',
                    count: watchingShows.length,
                    color: Colors.blue,
                  ),
                  _buildGrid(watchingShows),
                ],
                if (completedShows.isNotEmpty) ...[
                  _SectionSliverHeader(
                    title: 'Completed',
                    count: completedShows.length,
                    color: Colors.green,
                  ),
                  _buildGrid(completedShows),
                ],
                if (droppedShows.isNotEmpty) ...[
                  _SectionSliverHeader(
                    title: 'Dropped',
                    count: droppedShows.length,
                    color: Colors.grey,
                  ),
                  _buildGrid(droppedShows),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverPadding _buildGrid(List<TrackedShow> shows) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisExtent: 200,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => TrackedShowGridCard(show: shows[index]),
          childCount: shows.length,
        ),
      ),
    );
  }
}

class _SectionSliverHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionSliverHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: color.withValues(alpha: 0.1),
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
      ),
    );
  }
}

class TrackedShowGridCard extends StatelessWidget {
  final TrackedShow show;

  const TrackedShowGridCard({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          final showModel = Show(
            id: show.showId,
            name: show.name,
            image: show.posterUrl != null
                ? ImageTvmaze(medium: show.posterUrl!)
                : null,
            summary: '',
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShowDetailScreen(show: showModel),
            ),
          );
        },
        child: show.posterUrl != null
            ? Image.network(
                show.posterUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[850],
      child: const Icon(Icons.tv, size: 64, color: Colors.grey),
    );
  }
}
