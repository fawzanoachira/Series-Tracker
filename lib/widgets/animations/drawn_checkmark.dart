import 'package:flutter/material.dart';
import 'drawn_checkmark_painter.dart';

class DrawnCheckmark extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const DrawnCheckmark({
    super.key,
    this.size = 56,
    this.color = Colors.white,
    this.duration = const Duration(milliseconds: 420),
  });

  @override
  State<DrawnCheckmark> createState() => _DrawnCheckmarkState();
}

class _DrawnCheckmarkState extends State<DrawnCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: DrawnCheckmarkPainter(
          animation: _controller,
          color: widget.color,
        ),
      ),
    );
  }
}
