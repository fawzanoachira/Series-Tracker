import 'package:flutter/material.dart';
import 'package:lahv/models/analytics/analytics_models.dart';

class WeeklyTrendChart extends StatelessWidget {
  final List<WeeklyTrend> trends;

  const WeeklyTrendChart({
    super.key,
    required this.trends,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (trends.isEmpty) {
      return Center(
        child: Text(
          'No trend data',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final maxEpisodes =
        trends.map((t) => t.episodesWatched).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last 12 Weeks Trend',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: trends.map((trend) {
              final barHeight = maxEpisodes > 0
                  ? (trend.episodesWatched / maxEpisodes) * 160
                  : 0.0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (trend.episodesWatched > 0)
                        Text(
                          '${trend.episodesWatched}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'W${trend.weekNumber}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
