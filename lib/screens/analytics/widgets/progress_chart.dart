import 'package:flutter/material.dart';

class ProgressChart extends StatelessWidget {
  final String title;
  final double percentage;
  final String? subtitle;
  final Color? color;

  const ProgressChart({
    super.key,
    required this.title,
    required this.percentage,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: progressColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 12,
                    backgroundColor: progressColor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(progressColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
