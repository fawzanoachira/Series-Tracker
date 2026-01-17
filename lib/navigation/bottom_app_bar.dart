import 'package:flutter/material.dart';

class BottomAppBarData extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomAppBarData({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 70,
      notchMargin: BorderSide.strokeAlignCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _item(context, 0, _icon(0), 'Watchlist'),
          _item(context, 1, _icon(1), 'My Shows'),
          _item(context, 2, _icon(2), 'Explore'),
          _item(context, 3, _icon(3), 'Analytics'),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, int index, IconData icon, String label) {
    final isActive = currentIndex == index;
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(int index) {
    final isActive = currentIndex == index;
    switch (index) {
      case 0:
        return isActive ? Icons.watch_later : Icons.watch_later_outlined;
      case 1:
        return isActive ? Icons.live_tv : Icons.live_tv_outlined;
      case 2:
        return isActive ? Icons.explore : Icons.explore_outlined;
      case 3:
        return isActive ? Icons.analytics : Icons.analytics_outlined;
      default:
        return Icons.circle;
    }
  }
}
