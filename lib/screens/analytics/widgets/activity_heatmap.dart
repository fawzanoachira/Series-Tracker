import 'package:flutter/material.dart';
import 'package:lahv/models/analytics/analytics_models.dart';

class ActivityHeatmap extends StatelessWidget {
  final List<DailyActivity> activities;
  final double cellSize;

  const ActivityHeatmap({
    super.key,
    required this.activities,
    this.cellSize = 32,
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
        SizedBox(
          height: cellSize * 7 + 48, // 7 rows + spacing
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: (activities.length / 7).ceil(),
            itemBuilder: (context, weekIndex) {
              final weekStart = weekIndex * 7;
              // final weekEnd = math.min(weekStart + 7, activities.length);

              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  children: List.generate(7, (dayIndex) {
                    final activityIndex = weekStart + dayIndex;

                    if (activityIndex >= activities.length) {
                      return SizedBox(
                        width: cellSize,
                        height: cellSize,
                      );
                    }

                    final activity = activities[activityIndex];
                    final intensity = maxEpisodes > 0
                        ? activity.episodesWatched / maxEpisodes
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _ActivityCell(
                        activity: activity,
                        intensity: intensity,
                        size: cellSize,
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Less',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 4),
            ...List.generate(5, (index) {
              final intensity = (index + 1) / 5;
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Container(
                  width: 12,
                  height: 12,
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
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
          borderRadius: BorderRadius.circular(4),
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
