import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lahv/models/analytics/analytics_models.dart';
import 'package:lahv/providers/cached_analytics_providers.dart'; // ✅ Changed import
import 'package:lahv/screens/analytics/widgets/activity_heatmap.dart';
import 'package:lahv/screens/analytics/widgets/pie_chart.dart';
import 'package:lahv/screens/analytics/widgets/progress_chart.dart';
import 'package:lahv/screens/analytics/widgets/show_insight_card.dart';
import 'package:lahv/screens/analytics/widgets/stat_card.dart';
import 'package:lahv/screens/analytics/widgets/weekly_trend_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ FIXED: Using cached provider instead of slow repository
    final analyticsAsync = ref.watch(cachedCompleteAnalyticsProvider);

    return Scaffold(
      body: analyticsAsync.when(
        data: (analytics) => RefreshIndicator(
          onRefresh: () async {
            // ✅ FIXED: Invalidate cache on refresh
            ref.invalidate(cachedCompleteAnalyticsProvider);
            await ref.read(cachedCompleteAnalyticsProvider.future);
          },
          child: _AnalyticsContent(analytics: analytics),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(cachedCompleteAnalyticsProvider);
            await ref.read(cachedCompleteAnalyticsProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
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
                      onPressed: () =>
                          ref.invalidate(cachedCompleteAnalyticsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Rest of the code remains the same...
class _AnalyticsContent extends StatelessWidget {
  final CompleteAnalytics analytics;

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
                // Overview Section
                const _SectionTitle(title: 'Overview'),
                const SizedBox(height: 12),
                _OverviewSection(overview: analytics.overview),

                const SizedBox(height: 32),

                // Show Status Breakdown
                const _SectionTitle(title: 'Show Status'),
                const SizedBox(height: 12),
                _StatusBreakdownSection(breakdown: analytics.statusBreakdown),

                const SizedBox(height: 32),

                // Progress Section
                const _SectionTitle(title: 'Progress'),
                const SizedBox(height: 12),
                _ProgressSection(progress: analytics.episodeProgress),

                const SizedBox(height: 32),

                // Time Analytics
                const _SectionTitle(title: 'Time Spent'),
                const SizedBox(height: 12),
                _TimeSection(time: analytics.timeAnalytics),

                const SizedBox(height: 32),

                // Watching Habits
                const _SectionTitle(title: 'Watching Habits'),
                const SizedBox(height: 12),
                _HabitsSection(habits: analytics.watchingHabits),

                const SizedBox(height: 32),

                // Streaks
                const _SectionTitle(title: 'Streaks'),
                const SizedBox(height: 12),
                _StreakSection(habits: analytics.watchingHabits),

                const SizedBox(height: 32),

                // Activity Heatmap
                if (analytics.last30DaysActivity.isNotEmpty) ...[
                  ActivityHeatmap(activities: analytics.last30DaysActivity),
                  const SizedBox(height: 32),
                ],

                // Weekly Trend
                if (analytics.last12WeeksTrend.isNotEmpty) ...[
                  WeeklyTrendChart(trends: analytics.last12WeeksTrend),
                  const SizedBox(height: 32),
                ],

                // Upcoming Episodes
                const _SectionTitle(title: 'Upcoming Episodes'),
                const SizedBox(height: 12),
                _UpcomingSection(upcoming: analytics.upcoming),

                const SizedBox(height: 32),

                // Top Shows
                if (analytics.topShows.isNotEmpty) ...[
                  const _SectionTitle(title: 'Most Watched Shows'),
                  const SizedBox(height: 12),
                  ...analytics.topShows.map(
                    (insight) => ShowInsightCard(insight: insight),
                  ),
                  const SizedBox(height: 32),
                ],

                // Abandoned Shows
                if (analytics.abandonedShows.isNotEmpty) ...[
                  const _SectionTitle(title: 'On Hold (30+ Days)'),
                  const SizedBox(height: 12),
                  ...analytics.abandonedShows.map(
                    (insight) => ShowInsightCard(insight: insight),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  final AnalyticsOverview overview;

  const _OverviewSection({required this.overview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          title: 'Tracked Shows',
          value: '${overview.totalTrackedShows}',
          icon: Icons.tv,
          color: theme.colorScheme.primary,
        ),
        StatCard(
          title: 'Episodes Watched',
          value: '${overview.totalEpisodesWatched}',
          icon: Icons.play_circle_outline,
          color: theme.colorScheme.secondary,
        ),
        StatCard(
          title: 'Hours Watched',
          value: '${overview.totalHoursWatched}h',
          icon: Icons.access_time,
          color: theme.colorScheme.tertiary,
        ),
        StatCard(
          title: 'Completion',
          value: '${overview.overallCompletionPercentage.toStringAsFixed(0)}%',
          icon: Icons.trending_up,
          color: Colors.green,
        ),
      ],
    );
  }
}

class _StatusBreakdownSection extends StatelessWidget {
  final ShowStatusBreakdown breakdown;

  const _StatusBreakdownSection({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (breakdown.total == 0) {
      return Center(
        child: Text(
          'No shows tracked yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Center(
      child: PieChartWidget(
        data: [
          PieChartData(
            label: 'Watching',
            value: breakdown.watching,
            color: Colors.blue,
          ),
          PieChartData(
            label: 'Completed',
            value: breakdown.completed,
            color: Colors.green,
          ),
          PieChartData(
            label: 'Dropped',
            value: breakdown.dropped,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final EpisodeProgressAnalytics progress;

  const _ProgressSection({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProgressChart(
          title: 'Overall Progress',
          percentage: progress.completionPercentage,
          subtitle:
              '${progress.totalEpisodesWatched} of ${progress.totalAvailableEpisodes} episodes • ${progress.totalSeasonCount} seasons',
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Watched',
                value: '${progress.totalEpisodesWatched}',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Remaining',
                value: '${progress.totalEpisodesRemaining}',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeSection extends StatelessWidget {
  final TimeAnalytics time;

  const _TimeSection({required this.time});

  @override
  Widget build(BuildContext context) {
    // Format total watched time
    String totalWatchedText;
    if (time.totalMonths > 0) {
      totalWatchedText = '${time.totalMonths}mo ${time.totalDays}d';
    } else {
      totalWatchedText = '${time.totalHoursWatched}h';
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Watched',
                value: totalWatchedText,
                subtitle:
                    '${time.totalHoursWatched}h ${time.totalMinutesWatched % 60}m total',
                icon: Icons.access_time,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Remaining',
                value: '${time.estimatedHoursRemaining}h',
                subtitle: 'Estimated',
                icon: Icons.hourglass_empty,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Daily Average',
                value: '${time.averageMinutesPerDay.toStringAsFixed(0)}m',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Weekly Average',
                value: '${time.averageMinutesPerWeek.toStringAsFixed(0)}m',
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HabitsSection extends StatelessWidget {
  final WatchingHabits habits;

  const _HabitsSection({required this.habits});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Pattern',
                value: _getPatternLabel(habits.pattern),
                subtitle: _getPatternDescription(habits.pattern),
                icon: _getPatternIcon(habits.pattern),
                color: _getPatternColor(habits.pattern),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Episodes/Day',
                value: habits.episodesPerDay.toStringAsFixed(1),
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Episodes/Week',
                value: habits.episodesPerWeek.toStringAsFixed(1),
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getPatternLabel(WatchingPattern pattern) {
    switch (pattern) {
      case WatchingPattern.binge:
        return 'Binge Watcher';
      case WatchingPattern.regular:
        return 'Regular Viewer';
      case WatchingPattern.casual:
        return 'Casual Viewer';
    }
  }

  String _getPatternDescription(WatchingPattern pattern) {
    switch (pattern) {
      case WatchingPattern.binge:
        return 'Multiple episodes per day';
      case WatchingPattern.regular:
        return 'Consistent watching';
      case WatchingPattern.casual:
        return 'Sporadic viewing';
    }
  }

  IconData _getPatternIcon(WatchingPattern pattern) {
    switch (pattern) {
      case WatchingPattern.binge:
        return Icons.local_fire_department;
      case WatchingPattern.regular:
        return Icons.schedule;
      case WatchingPattern.casual:
        return Icons.coffee;
    }
  }

  Color _getPatternColor(WatchingPattern pattern) {
    switch (pattern) {
      case WatchingPattern.binge:
        return Colors.red;
      case WatchingPattern.regular:
        return Colors.blue;
      case WatchingPattern.casual:
        return Colors.green;
    }
  }
}

class _StreakSection extends StatelessWidget {
  final WatchingHabits habits;

  const _StreakSection({required this.habits});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Current Streak',
            value: '${habits.currentStreak}',
            subtitle: habits.currentStreak == 1 ? 'day' : 'days',
            icon: Icons.whatshot,
            color: habits.currentStreak > 0 ? Colors.orange : Colors.grey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Longest Streak',
            value: '${habits.longestStreak}',
            subtitle: habits.longestStreak == 1 ? 'day' : 'days',
            icon: Icons.emoji_events,
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Last Watch',
            value: '${habits.daysSinceLastWatch}',
            subtitle: 'days ago',
            icon: Icons.history,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  final UpcomingAnalytics upcoming;

  const _UpcomingSection({required this.upcoming});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Airing Today',
                value: '${upcoming.episodesAiringToday}',
                icon: Icons.today,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'This Week',
                value: '${upcoming.episodesAiringThisWeek}',
                icon: Icons.calendar_today,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'This Month',
                value: '${upcoming.episodesAiringThisMonth}',
                icon: Icons.calendar_month,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Weekly Load',
                value: '${upcoming.weeklyUpcomingLoad.toStringAsFixed(0)}%',
                subtitle: 'vs your pace',
                icon: Icons.trending_up,
                color: upcoming.weeklyUpcomingLoad > 100
                    ? Colors.orange
                    : Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
