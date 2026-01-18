import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/providers/cached_analytics_providers.dart';
import 'package:lahv/services/hybrid_analytics_cache.dart';
import 'package:lahv/widgets/cached_image.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(simpleAnalyticsProvider);

    return Scaffold(
      body: analyticsAsync.when(
        data: (analytics) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(simpleAnalyticsProvider);
            await ref.read(simpleAnalyticsProvider.future);
          },
          child: _AnalyticsContent(analytics: analytics),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load analytics'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(simpleAnalyticsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  final SimpleAnalytics analytics;

  const _AnalyticsContent({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // App Bar
        const SliverAppBar.large(
          title: Text('Analytics'),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Time Watched Card
                _TimeWatchedCard(analytics: analytics),

                const SizedBox(height: 24),

                // 2. Episode Count Card
                _EpisodeCountCard(analytics: analytics),

                const SizedBox(height: 32),

                // 3. Most Watched Shows
                if (analytics.topShows.isNotEmpty) ...[
                  Text(
                    'Most Watched Shows',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...analytics.topShows.map(
                    (show) => _TopShowCard(show: show),
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ========================================
// 1. Time Watched Card
// ========================================

class _TimeWatchedCard extends StatelessWidget {
  final SimpleAnalytics analytics;

  const _TimeWatchedCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final breakdown = analytics.timeBreakdown;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Total Time Watched',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total minutes (large number)
            Text(
              '${_formatNumber(breakdown.totalMinutes)} minutes',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),

            // Breakdown
            Text(
              'which is exactly ${breakdown.formatted}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// ========================================
// 2. Episode Count Card
// ========================================

class _EpisodeCountCard extends StatelessWidget {
  final SimpleAnalytics analytics;

  const _EpisodeCountCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: theme.colorScheme.secondary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Episodes Watched',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total episodes (large number)
            Text(
              '${_formatNumber(analytics.totalEpisodesWatched)} episodes',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),

            const SizedBox(height: 8),

            // Breakdown
            Text(
              'in exactly ${analytics.totalShows} ${analytics.totalShows == 1 ? 'show' : 'shows'}, ${analytics.totalSeasons} ${analytics.totalSeasons == 1 ? 'season' : 'seasons'}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// ========================================
// 3. Top Show Card
// ========================================

class _TopShowCard extends StatelessWidget {
  final TopShow show;

  const _TopShowCard({required this.show});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: show.posterUrl != null
                  ? CachedImage(
                      url: show.posterUrl!,
                      width: 60,
                      height: 90,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 60,
                      height: 90,
                      color: theme.colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.tv,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    show.showName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${show.hoursWatched}h watched',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${show.episodesWatched} episodes • ${show.seasonCount} ${show.seasonCount == 1 ? 'season' : 'seasons'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
