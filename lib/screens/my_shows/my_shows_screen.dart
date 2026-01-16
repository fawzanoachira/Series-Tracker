import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:series_tracker/models/tracking/tracked_show.dart';
import 'package:series_tracker/providers/tracked_shows_provider.dart';
import 'package:series_tracker/providers/upcoming_episodes_provider.dart';
import 'package:series_tracker/screens/show_detail_screen/show_detail_screen.dart';
import 'package:series_tracker/models/tvmaze/show.dart';
import 'package:series_tracker/models/tvmaze/image_tvmaze.dart';
import 'package:series_tracker/widgets/upcoming_episode_card.dart';

class MyShowsScreen extends ConsumerStatefulWidget {
  const MyShowsScreen({super.key});

  @override
  ConsumerState<MyShowsScreen> createState() => _MyShowsScreenState();
}

class _MyShowsScreenState extends ConsumerState<MyShowsScreen> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);

    // Clear cache for fresh data
    clearEpisodesCache();

    ref.invalidate(trackedShowsProvider);
    ref.invalidate(upcomingEpisodesProvider);

    await Future.wait([
      ref.read(trackedShowsProvider.future),
      ref.read(upcomingEpisodesProvider.future),
    ]);

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackedShowsAsync = ref.watch(trackedShowsProvider);
    final upcomingEpisodesAsync = ref.watch(upcomingEpisodesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shows'),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _handleRefresh,
            ),
        ],
      ),
      body: trackedShowsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (shows) {
          if (shows.isEmpty) {
            return RefreshIndicator(
              onRefresh: _handleRefresh,
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
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Upcoming Episodes Section
                upcomingEpisodesAsync.when(
                  loading: () => SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildLoadingSectionHeader(
                            context, 'Loading upcoming episodes...'),
                        ..._buildSkeletonCards(3),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  error: (_, __) => const SliverToBoxAdapter(
                    child: SizedBox.shrink(),
                  ),
                  data: (upcomingEpisodes) {
                    if (upcomingEpisodes.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: SizedBox.shrink(),
                      );
                    }

                    // Separate episodes by status
                    final pastEpisodes =
                        upcomingEpisodes.where((ep) => ep.isPast).toList();
                    final todayEpisodes =
                        upcomingEpisodes.where((ep) => ep.isToday).toList();
                    final futureEpisodes = upcomingEpisodes
                        .where((ep) => !ep.isToday && !ep.isPast)
                        .toList();

                    return SliverList(
                      delegate: SliverChildListDelegate([
                        // Recently Aired Episodes
                        if (pastEpisodes.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'Recently Aired',
                            pastEpisodes.length,
                            Colors.orange,
                          ),
                          ...pastEpisodes.map(
                            (ep) => UpcomingEpisodeCard(upcomingEpisode: ep),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Today's Episodes
                        if (todayEpisodes.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'Airing Today',
                            todayEpisodes.length,
                            Colors.green,
                          ),
                          ...todayEpisodes.map(
                            (ep) => UpcomingEpisodeCard(upcomingEpisode: ep),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Upcoming Episodes
                        if (futureEpisodes.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'Coming Soon',
                            futureEpisodes.length,
                            Colors.blue,
                          ),
                          ...futureEpisodes.map(
                            (ep) => UpcomingEpisodeCard(upcomingEpisode: ep),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ]),
                    );
                  },
                ),

                // Divider before show lists
                if (upcomingEpisodesAsync.hasValue &&
                    upcomingEpisodesAsync.value!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Divider(
                      thickness: 8,
                      color: Colors.grey[900],
                    ),
                  ),

                // My Shows Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'All Shows',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ),

                // Shows by Status
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

  Widget _buildLoadingSectionHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(top: 8),
      color: Colors.grey[850],
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey[400],
                ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSkeletonCards(int count) {
    return List.generate(
      count,
      (index) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          height: 110,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Skeleton poster
              Container(
                width: 70,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              // Skeleton text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Skeleton badge
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(top: 8),
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
