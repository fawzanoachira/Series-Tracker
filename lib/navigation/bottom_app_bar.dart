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
          _item(context, 0, _icon(0)),
          _item(context, 1, _icon(1)),
          _item(context, 2, _icon(2)),
          _item(context, 3, _icon(3)),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, int index, IconData icon) {
    return IconButton(
      onPressed: () => onTap(index),
      icon: Icon(
        icon,
        color: currentIndex == index
            ? Theme.of(context).colorScheme.primary
            : null,
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
        return isActive ? Icons.insights : Icons.insights_outlined;
      default:
        return Icons.circle;
    }
  }
}
