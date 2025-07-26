import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Configuración de optimizaciones de performance
class PerformanceConfig {
  // Cache settings
  static const Duration cacheExpiration = Duration(minutes: 5);
  static const Duration syncInterval = Duration(minutes: 10);
  
  // Firebase settings
  static const int maxBatchSize = 500;
  static const Duration batchTimeout = Duration(seconds: 30);
  
  // UI settings
  static const int maxItemsPerPage = 50;
  static const Duration debounceDelay = Duration(milliseconds: 300);
  
  // Network settings
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;
  
  // Debug settings
  static const bool enableDetailedLogs = true;
  static const bool enablePerformanceMetrics = true;

  // OPTIMIZACIÓN: Configuración específica para hardware antiguo
  static const Map<String, dynamic> legacyHardwareConfig = {
    'cacheExpiration': Duration(minutes: 15), // Cache más largo
    'maxCacheSize': 50, // Cache más pequeño
    'syncInterval': Duration(minutes: 5), // Sync menos frecuente
    'enableRealTimeSync': false, // Sin sync en tiempo real
    'maxConcurrentRequests': 3, // Menos requests simultáneos
    'maxItemsPerPage': 25, // Menos elementos por página
    'debounceDelay': Duration(milliseconds: 500), // Debounce más largo
    'enableAnimations': false, // Sin animaciones
    'enableDetailedLogs': false, // Menos logs
    'enablePerformanceMetrics': false, // Sin métricas
    'enableLazyLoading': true, // Lazy loading obligatorio
    'enablePrefetching': false, // Sin prefetch
    'enableBackgroundSync': false, // Sin sync en background
  };

  // OPTIMIZACIÓN: Configuración estándar para hardware moderno
  static const Map<String, dynamic> modernHardwareConfig = {
    'cacheExpiration': Duration(minutes: 5),
    'maxCacheSize': 100,
    'syncInterval': Duration(minutes: 2),
    'enableRealTimeSync': true,
    'maxConcurrentRequests': 10,
    'maxItemsPerPage': 50,
    'debounceDelay': Duration(milliseconds: 300),
    'enableAnimations': true,
    'enableDetailedLogs': true,
    'enablePerformanceMetrics': true,
    'enableLazyLoading': true,
    'enablePrefetching': true,
    'enableBackgroundSync': true,
  };

  // OPTIMIZACIÓN: Detección de hardware
  static bool _isLegacyHardware = false;
  static bool _hardwareDetected = false;

  /// Detectar si el hardware es antiguo
  static Future<bool> detectLegacyHardware() async {
    if (_hardwareDetected) return _isLegacyHardware;

    try {
      // OPTIMIZACIÓN: Detectar características del hardware
      final isLegacy = await _checkHardwareCapabilities();
      _isLegacyHardware = isLegacy;
      _hardwareDetected = true;
      
      print('🔍 PerformanceConfig: Hardware detectado - ${isLegacy ? "Antiguo" : "Moderno"}');
      return isLegacy;
    } catch (e) {
      print('⚠️ PerformanceConfig: Error detectando hardware, usando configuración estándar: $e');
      _isLegacyHardware = false;
      _hardwareDetected = true;
      return false;
    }
  }

  /// Verificar capacidades del hardware
  static Future<bool> _checkHardwareCapabilities() async {
    // OPTIMIZACIÓN: Heurísticas para detectar hardware antiguo
    try {
      // En web, detectar por características del navegador
      if (kIsWeb) {
        return await _detectWebHardware();
      }
      
      // En móvil, usar configuración estándar
      return false;
    } catch (e) {
      print('⚠️ PerformanceConfig: Error en detección de hardware: $e');
      return false;
    }
  }

  /// Detectar hardware en web
  static Future<bool> _detectWebHardware() async {
    try {
      // OPTIMIZACIÓN: Detectar por características del navegador
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      
      // Detectar navegadores antiguos
      if (userAgent.contains('msie') || 
          userAgent.contains('trident') ||
          userAgent.contains('edge/12') ||
          userAgent.contains('edge/13') ||
          userAgent.contains('edge/14') ||
          userAgent.contains('edge/15') ||
          userAgent.contains('edge/16')) {
        return true;
      }
      
      // Detectar dispositivos móviles (considerar como hardware limitado)
      if (userAgent.contains('mobile') || 
          userAgent.contains('android') ||
          userAgent.contains('iphone') ||
          userAgent.contains('ipad')) {
        return true;
      }
      
      // Detectar por rendimiento
      return await _testPerformance();
    } catch (e) {
      print('⚠️ PerformanceConfig: Error detectando hardware web: $e');
      return false;
    }
  }

  /// Test de rendimiento simple
  static Future<bool> _testPerformance() async {
    try {
      final start = DateTime.now();
      
      // OPTIMIZACIÓN: Test simple de rendimiento
      for (int i = 0; i < 10000; i++) {
        // Operación simple para medir rendimiento
        final result = i * i;
        if (result > 1000000) break;
      }
      
      final duration = DateTime.now().difference(start);
      
      // Si toma más de 10ms, considerar hardware antiguo
      return duration.inMilliseconds > 10;
    } catch (e) {
      print('⚠️ PerformanceConfig: Error en test de rendimiento: $e');
      return false;
    }
  }

  /// Obtener configuración optimizada para el hardware
  static Map<String, dynamic> getOptimizedConfig() {
    if (_isLegacyHardware) {
      print('⚙️ PerformanceConfig: Usando configuración para hardware antiguo');
      return legacyHardwareConfig;
    } else {
      print('⚙️ PerformanceConfig: Usando configuración para hardware moderno');
      return modernHardwareConfig;
    }
  }

  /// Obtener valor específico de configuración
  static T getConfigValue<T>(String key, T defaultValue) {
    final config = getOptimizedConfig();
    return config[key] ?? defaultValue;
  }

  /// Verificar si una característica está habilitada
  static bool isFeatureEnabled(String feature) {
    return getConfigValue(feature, false);
  }

  /// Obtener configuración de cache optimizada
  static Duration getCacheExpiration() {
    return getConfigValue('cacheExpiration', Duration(minutes: 5));
  }

  /// Obtener tamaño máximo de cache
  static int getMaxCacheSize() {
    return getConfigValue('maxCacheSize', 100);
  }

  /// Obtener intervalo de sincronización
  static Duration getSyncInterval() {
    return getConfigValue('syncInterval', Duration(minutes: 10));
  }

  /// Obtener número máximo de elementos por página
  static int getMaxItemsPerPage() {
    return getConfigValue('maxItemsPerPage', 50);
  }

  /// Obtener delay de debounce
  static Duration getDebounceDelay() {
    return getConfigValue('debounceDelay', Duration(milliseconds: 300));
  }

  /// Obtener número máximo de requests concurrentes
  static int getMaxConcurrentRequests() {
    return getConfigValue('maxConcurrentRequests', 10);
  }

  /// Verificar si las animaciones están habilitadas
  static bool getEnableAnimations() {
    return getConfigValue('enableAnimations', true);
  }

  /// Verificar si los logs detallados están habilitados
  static bool getEnableDetailedLogs() {
    return getConfigValue('enableDetailedLogs', true);
  }

  /// Verificar si las métricas de performance están habilitadas
  static bool getEnablePerformanceMetrics() {
    return getConfigValue('enablePerformanceMetrics', true);
  }

  /// Verificar si el lazy loading está habilitado
  static bool getEnableLazyLoading() {
    return getConfigValue('enableLazyLoading', true);
  }

  /// Verificar si el prefetch está habilitado
  static bool getEnablePrefetching() {
    return getConfigValue('enablePrefetching', true);
  }

  /// Verificar si el sync en background está habilitado
  static bool getEnableBackgroundSync() {
    return getConfigValue('enableBackgroundSync', true);
  }

  /// Obtener información de configuración actual
  static Map<String, dynamic> getCurrentConfig() {
    return {
      'isLegacyHardware': _isLegacyHardware,
      'hardwareDetected': _hardwareDetected,
      'cacheExpiration': getCacheExpiration().inMinutes,
      'maxCacheSize': getMaxCacheSize(),
      'syncInterval': getSyncInterval().inMinutes,
      'maxItemsPerPage': getMaxItemsPerPage(),
      'debounceDelay': getDebounceDelay().inMilliseconds,
      'maxConcurrentRequests': getMaxConcurrentRequests(),
      'enableAnimations': getEnableAnimations(),
      'enableDetailedLogs': getEnableDetailedLogs(),
      'enablePerformanceMetrics': getEnablePerformanceMetrics(),
      'enableLazyLoading': getEnableLazyLoading(),
      'enablePrefetching': getEnablePrefetching(),
      'enableBackgroundSync': getEnableBackgroundSync(),
    };
  }
} 