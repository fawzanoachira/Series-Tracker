import 'package:flutter/material.dart';

class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeScaleRoute({required this.page})
      : super(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black.withAlpha((0.85 * 255).round()),
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );

            final scale = Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
            );

            return FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: child,
              ),
            );
          },
        );
}
