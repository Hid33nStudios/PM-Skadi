import '../config/performance_config.dart';

/// Sistema de logging optimizado para diferentes tipos de hardware
class PerformanceLogger {
  static bool _isInitialized = false;
  static bool _enableDetailedLogs = true;
  static bool _enablePerformanceMetrics = true;

  /// Inicializar el sistema de logging
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // OPTIMIZACIÓN: Detectar hardware y configurar logging
      await PerformanceConfig.detectLegacyHardware();
      
      _enableDetailedLogs = PerformanceConfig.getEnableDetailedLogs();
      _enablePerformanceMetrics = PerformanceConfig.getEnablePerformanceMetrics();
      
      print('📊 PerformanceLogger: Inicializado');
      print('  - Logs detallados: ${_enableDetailedLogs ? "Habilitados" : "Deshabilitados"}');
      print('  - Métricas de performance: ${_enablePerformanceMetrics ? "Habilitadas" : "Deshabilitadas"}');
      
      _isInitialized = true;
    } catch (e) {
      print('⚠️ PerformanceLogger: Error inicializando, usando configuración estándar: $e');
      _enableDetailedLogs = true;
      _enablePerformanceMetrics = true;
      _isInitialized = true;
    }
  }

  /// Log de información general (siempre habilitado)
  static void info(String message) {
    print('ℹ️ $message');
  }

  /// Log de éxito (siempre habilitado)
  static void success(String message) {
    print('✅ $message');
  }

  /// Log de advertencia (siempre habilitado)
  static void warning(String message) {
    print('⚠️ $message');
  }

  /// Log de error (siempre habilitado)
  static void error(String message, [dynamic error]) {
    if (error != null) {
      print('❌ $message: $error');
    } else {
      print('❌ $message');
    }
  }

  /// Log detallado (solo en hardware moderno)
  static void debug(String message) {
    if (_enableDetailedLogs) {
      print('🔍 $message');
    }
  }

  /// Log de performance (solo en hardware moderno)
  static void performance(String message) {
    if (_enablePerformanceMetrics) {
      print('⚡ $message');
    }
  }

  /// Log de cache (solo en hardware moderno)
  static void cache(String message) {
    if (_enableDetailedLogs) {
      print('📦 $message');
    }
  }

  /// Log de sincronización (solo en hardware moderno)
  static void sync(String message) {
    if (_enableDetailedLogs) {
      print('🔄 $message');
    }
  }

  /// Log de Firebase (solo en hardware moderno)
  static void firebase(String message) {
    if (_enableDetailedLogs) {
      print('🔥 $message');
    }
  }

  /// Log de UI (solo en hardware moderno)
  static void ui(String message) {
    if (_enableDetailedLogs) {
      print('🎨 $message');
    }
  }

  /// Log de métricas con timestamp
  static void metric(String operation, {int? count, Duration? duration, String? details}) {
    if (!_enablePerformanceMetrics) return;

    final timestamp = DateTime.now().toIso8601String();
    final countStr = count != null ? ' ($count elementos)' : '';
    final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    final detailsStr = details != null ? ' - $details' : '';
    
    print('📊 [$timestamp] $operation$countStr$durationStr$detailsStr');
  }

  /// Log de inicio de operación
  static void startOperation(String operation) {
    if (_enableDetailedLogs) {
      print('🚀 === INICIO $operation ===');
      print('⏰ Timestamp: ${DateTime.now()}');
    }
  }

  /// Log de fin de operación
  static void endOperation(String operation, {bool success = true, String? details}) {
    if (_enableDetailedLogs) {
      final status = success ? 'EXITOSO' : 'CON ERROR';
      print('🎉 === FIN $operation - $status ===');
      if (details != null) {
        print('📝 Detalles: $details');
      }
      print('⏰ Timestamp: ${DateTime.now()}');
    }
  }

  /// Log de configuración aplicada
  static void config(String category, Map<String, dynamic> config) {
    if (_enableDetailedLogs) {
      print('⚙️ Configuración $category:');
      config.forEach((key, value) {
        print('  - $key: $value');
      });
    }
  }

  /// Log de estadísticas
  static void stats(String title, Map<String, dynamic> stats) {
    if (_enableDetailedLogs) {
      print('📊 $title:');
      stats.forEach((key, value) {
        print('  - $key: $value');
      });
    }
  }

  /// Log de progreso
  static void progress(String stage, {int? current, int? total}) {
    if (_enableDetailedLogs) {
      if (current != null && total != null) {
        final percentage = ((current / total) * 100).round();
        print('📈 $stage: $current/$total ($percentage%)');
      } else {
        print('📈 $stage');
      }
    }
  }

  /// Log de memoria
  static void memory(String operation, {int? bytes, String? details}) {
    if (_enablePerformanceMetrics) {
      final bytesStr = bytes != null ? ' (${_formatBytes(bytes)})' : '';
      final detailsStr = details != null ? ' - $details' : '';
      print('💾 $operation$bytesStr$detailsStr');
    }
  }

  /// Formatear bytes de forma legible
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Log de rendimiento de red
  static void network(String operation, {Duration? duration, int? bytes, String? endpoint}) {
    if (_enablePerformanceMetrics) {
      final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
      final bytesStr = bytes != null ? ' (${_formatBytes(bytes)})' : '';
      final endpointStr = endpoint != null ? ' -> $endpoint' : '';
      print('🌐 $operation$durationStr$bytesStr$endpointStr');
    }
  }

  /// Log de cache hit/miss
  static void cacheHit(String key) {
    if (_enableDetailedLogs) {
      print('📦 Cache HIT: $key');
    }
  }

  static void cacheMiss(String key) {
    if (_enableDetailedLogs) {
      print('❌ Cache MISS: $key');
    }
  }

  /// Log de batch operations
  static void batch(String operation, {int? count, String? details}) {
    if (_enableDetailedLogs) {
      final countStr = count != null ? ' ($count operaciones)' : '';
      final detailsStr = details != null ? ' - $details' : '';
      print('📦 Batch $operation$countStr$detailsStr');
    }
  }

  /// Log de sincronización
  static void syncStatus(String status, {String? details, int? pendingChanges}) {
    if (_enableDetailedLogs) {
      final detailsStr = details != null ? ' - $details' : '';
      final pendingStr = pendingChanges != null ? ' (${pendingChanges} pendientes)' : '';
      print('🔄 Sync: $status$detailsStr$pendingStr');
    }
  }

  /// Log de error con stack trace
  static void errorWithStack(String message, dynamic error, StackTrace stackTrace) {
    print('❌ $message');
    print('Error: $error');
    if (_enableDetailedLogs) {
      print('Stack trace:');
      print(stackTrace);
    }
  }

  /// Log de configuración de hardware
  static void hardwareConfig() {
    final config = PerformanceConfig.getCurrentConfig();
    print('🔧 Configuración de hardware aplicada:');
    print('  - Hardware: ${config['isLegacyHardware'] ? "Antiguo" : "Moderno"}');
    print('  - Logs detallados: ${config['enableDetailedLogs'] ? "Habilitados" : "Deshabilitados"}');
    print('  - Métricas: ${config['enablePerformanceMetrics'] ? "Habilitadas" : "Deshabilitadas"}');
    print('  - Animaciones: ${config['enableAnimations'] ? "Habilitadas" : "Deshabilitadas"}');
    print('  - Cache: ${config['cacheExpiration']} minutos');
    print('  - Elementos por página: ${config['maxItemsPerPage']}');
  }
} 