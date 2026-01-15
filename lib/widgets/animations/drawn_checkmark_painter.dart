import 'package:flutter/material.dart';

class DrawnCheckmarkPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  DrawnCheckmarkPainter({
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.70,
        size.width * 0.45,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.38,
        size.width * 0.85,
        size.height * 0.28,
      );

    final metrics = path.computeMetrics().first;
    final extracted = metrics.extractPath(0, metrics.length * animation.value);

    canvas.drawPath(extracted, paint);
  }

  @override
  bool shouldRepaint(covariant DrawnCheckmarkPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.color != color;
  }
}
