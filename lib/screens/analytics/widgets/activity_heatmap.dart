import 'package:flutter/material.dart';
import 'package:lahv/models/analytics/analytics_models.dart';

class ActivityHeatmap extends StatelessWidget {
  final List<DailyActivity> activities;
  final double cellSize;

  const ActivityHeatmap({
    super.key,
    required this.activities,
    this.cellSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activities.isEmpty) {
      return Center(
        child: Text(
          'No activity data',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final maxEpisodes = activities
        .map((a) => a.episodesWatched)
        .reduce((a, b) => a > b ? a : b);

    // Calculate grid dimensions
    final totalDays = activities.length;
    final fullWeeks = totalDays ~/ 7;
    final remainingDays = totalDays % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last 30 Days Activity',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // GitHub-style grid
        _buildGitHubStyleGrid(
          context,
          activities,
          maxEpisodes,
          fullWeeks,
          remainingDays,
        ),

        const SizedBox(height: 12),

        // Legend
        _buildLegend(context, theme),
      ],
    );
  }

  Widget _buildGitHubStyleGrid(
    BuildContext context,
    List<DailyActivity> activities,
    int maxEpisodes,
    int fullWeeks,
    int remainingDays,
  ) {
    // Organize activities into weeks (columns)
    final weeks = <List<DailyActivity>>[];

    for (int weekIndex = 0; weekIndex < fullWeeks; weekIndex++) {
      final weekStart = weekIndex * 7;
      final weekActivities = activities.sublist(weekStart, weekStart + 7);
      weeks.add(weekActivities);
    }

    // Add remaining days as the last column
    if (remainingDays > 0) {
      final lastWeekActivities = activities.sublist(fullWeeks * 7);
      weeks.add(lastWeekActivities);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels
        _buildDayLabels(context),
        const SizedBox(width: 8),

        // Activity grid
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: weeks.asMap().entries.map((entry) {
                final isLastWeek = entry.key == weeks.length - 1;
                final weekActivities = entry.value;

                return _buildWeekColumn(
                  context,
                  weekActivities,
                  maxEpisodes,
                  isLastWeek,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayLabels(BuildContext context) {
    final theme = Theme.of(context);
    final labels = ['Mon', 'Wed', 'Fri'];
    final positions = [0, 2, 4];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final labelIndex = positions.indexOf(index);
        if (labelIndex != -1) {
          return SizedBox(
            height: cellSize + 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                labels[labelIndex],
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        }
        return SizedBox(height: cellSize + 2);
      }),
    );
  }

  Widget _buildWeekColumn(
    BuildContext context,
    List<DailyActivity> weekActivities,
    int maxEpisodes,
    bool isLastWeek,
  ) {
    final cellCount = weekActivities.length;

    // Calculate padding for centering last column
    double topPadding = 0;
    if (isLastWeek && cellCount < 7) {
      final emptyCells = 7 - cellCount;
      topPadding = (emptyCells * (cellSize + 2)) / 2;
    }

    return Padding(
      padding: EdgeInsets.only(right: 2, top: topPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...weekActivities.map((activity) {
            final intensity =
                maxEpisodes > 0 ? activity.episodesWatched / maxEpisodes : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: _ActivityCell(
                activity: activity,
                intensity: intensity,
                size: cellSize,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Text(
          'Less',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(5, (index) {
          final intensity = (index + 1) / 5;
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: _getColorForIntensity(
                  intensity,
                  theme.colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        Text(
          'More',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  static Color _getColorForIntensity(double intensity, Color baseColor) {
    if (intensity == 0) {
      return Colors.grey.shade200;
    }
    return baseColor.withValues(alpha: 0.2 + (intensity * 0.8));
  }
}

class _ActivityCell extends StatelessWidget {
  final DailyActivity activity;
  final double intensity;
  final double size;

  const _ActivityCell({
    required this.activity,
    required this.intensity,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ActivityHeatmap._getColorForIntensity(
      intensity,
      theme.colorScheme.primary,
    );

    return Tooltip(
      message:
          '${_formatDate(activity.date)}: ${activity.episodesWatched} episodes',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
