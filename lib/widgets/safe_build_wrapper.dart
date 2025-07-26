import 'package:flutter/material.dart';
import '../utils/safe_notifier.dart';

/// Widget wrapper que marca el inicio y fin del build
class SafeBuildWrapper extends StatefulWidget {
  final Widget child;
  
  const SafeBuildWrapper({
    super.key,
    required this.child,
  });

  @override
  State<SafeBuildWrapper> createState() => _SafeBuildWrapperState();
}

class _SafeBuildWrapperState extends State<SafeBuildWrapper> {
  @override
  Widget build(BuildContext context) {
    // Marcar inicio del build
    SafeNotifier.markBuildStart();
    
    // Programar el fin del build para después del frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SafeNotifier.markBuildEnd();
    });
    
    return widget.child;
  }
} 