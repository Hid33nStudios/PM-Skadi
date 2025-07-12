import 'package:flutter/material.dart';

class ElegantPageTransition extends StatelessWidget {
  final Widget child;
  const ElegantPageTransition({Key? key, required this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) => child;
}

class ElegantPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final bool isForward;

  ElegantPageRoute({
    required this.child,
    this.isForward = true,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ElegantPageTransition(
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 600),
        );
}

// Transición alternativa con efecto de deslizamiento suave
class SmoothSlideTransition extends StatelessWidget {
  final Widget child;
  const SmoothSlideTransition({Key? key, required this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) => child;
}

class SmoothSlideRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final bool isForward;

  SmoothSlideRoute({
    required this.child,
    this.isForward = true,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SmoothSlideTransition(
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 500),
        );
} 