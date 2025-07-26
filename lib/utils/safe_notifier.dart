import 'package:flutter/scheduler.dart';

/// Utilidad para notificar de forma segura sin causar setState durante build
class SafeNotifier {
  static bool _isInBuild = false;
  
  /// Marcar que estamos en un build
  static void markBuildStart() {
    _isInBuild = true;
  }
  
  /// Marcar que terminamos el build
  static void markBuildEnd() {
    _isInBuild = false;
  }
  
  /// Notificar de forma segura
  static void safeNotify(VoidCallback notifyCallback) {
    if (_isInBuild) {
      // Si estamos en build, programar la notificación para después
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyCallback();
      });
    } else {
      // Si no estamos en build, notificar inmediatamente
      notifyCallback();
    }
  }
  
  /// Verificar si estamos en build
  static bool get isInBuild => _isInBuild;
} 