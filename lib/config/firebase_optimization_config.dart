import 'package:flutter/foundation.dart';

class FirebaseOptimizationConfig {
  // Configuración de cache con TTLs específicos
  static const Duration defaultCacheTTL = Duration(minutes: 5);
  static const Duration dashboardCacheTTL = Duration(minutes: 2);
  static const Duration productsCacheTTL = Duration(minutes: 10);
  static const Duration categoriesCacheTTL = Duration(minutes: 15);
  static const Duration salesCacheTTL = Duration(minutes: 3);
  static const Duration movementsCacheTTL = Duration(minutes: 5);
  
  static const int maxCacheSize = 100; // Máximo número de elementos en cache
  static const bool enableCache = true;
  
  // Configuración de batch operations
  static const Duration batchTimeout = Duration(seconds: 2);
  static const int maxBatchSize = 500; // Máximo número de operaciones por batch
  static const bool enableBatchOperations = true;
  
  // Configuración de métricas en tiempo real
  static const Duration metricsUpdateInterval = Duration(seconds: 30);
  static const bool enableRealTimeMetrics = true;
  static const bool enablePerformanceStreams = true;
  
  // Configuración de peticiones
  static const int maxConcurrentRequests = 10;
  static const Duration requestTimeout = Duration(seconds: 30);
  static const bool enableRequestRetry = true;
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  
  // Configuración de paginación
  static const int defaultPageSize = 50;
  static const int maxPageSize = 100;
  
  // Configuración de monitoreo
  static const bool enablePerformanceMonitoring = true;
  static const bool logRequestCounts = true;
  static const bool logCacheHits = true;
  
  // Configuración de optimizaciones específicas
  static const bool enableLazyLoading = true;
  static const bool enablePrefetching = true;
  static const bool enableBackgroundSync = false; // Para web, mantener en false
  
  // Configuración de queries optimizadas
  static const Map<String, String> defaultOrderBy = {
    'products': 'createdAt',
    'categories': 'createdAt',
    'sales': 'date',
    'movements': 'date',
  };
  
  static const Map<String, bool> defaultDescending = {
    'products': true,
    'categories': true,
    'sales': true,
    'movements': true,
  };
  
  // Configuración de logging
  static void log(String message) {
    if (logRequestCounts) {
      print('📊 FirebaseOptimization: $message');
    }
  }
  
  static void logCacheHit(String key) {
    if (logCacheHits) {
      print('📦 FirebaseOptimization: Cache hit para $key');
    }
  }
  
  static void logCacheMiss(String key) {
    if (logCacheHits) {
      print('❌ FirebaseOptimization: Cache miss para $key');
    }
  }
  
  static void logRequest(String operation, int count) {
    if (logRequestCounts) {
      print('🔄 FirebaseOptimization: $operation - $count elementos');
    }
  }
  
  static void logBatchOperation(String operation, int batchSize) {
    if (logRequestCounts) {
      print('📦 FirebaseOptimization: Batch $operation - $batchSize operaciones');
    }
  }
  
  // Configuración de validación
  static const bool validateDataBeforeWrite = true;
  static const bool validateDataAfterRead = false; // Para performance
  
  // Configuración de limpieza automática
  static const Duration autoCleanupInterval = Duration(minutes: 10);
  static const bool enableAutoCleanup = true;
  
  // Configuración de compresión
  static const bool enableDataCompression = false; // Para web, mantener en false
  
  // Configuración de índices recomendados
  static const List<String> recommendedIndexes = [
    'products.createdAt',
    'products.barcode',
    'products.categoryId',
    'categories.createdAt',
    'sales.date',
    'sales.productId',
    'movements.date',
    'movements.productId',
  ];
  
  // Configuración de seguridad
  static const bool enableRateLimiting = true;
  static const int maxRequestsPerMinute = 1000;
  static const int maxWritesPerMinute = 500;
  
  // Configuración de fallback
  static const bool enableOfflineFallback = false; // Para web, mantener en false
  static const bool enableErrorRecovery = true;
  
  // Configuración de métricas
  static const bool collectMetrics = true;
  static const Duration metricsCollectionInterval = Duration(minutes: 5);
  
  // Métricas de performance
  static int totalReads = 0;
  static int totalWrites = 0;
  static int cacheHits = 0;
  static int cacheMisses = 0;
  static int batchOperations = 0;
  
  // Métodos para métricas
  static void incrementReads() {
    if (collectMetrics) totalReads++;
  }
  
  static void incrementWrites() {
    if (collectMetrics) totalWrites++;
  }
  
  static void incrementCacheHits() {
    if (collectMetrics) cacheHits++;
  }
  
  static void incrementCacheMisses() {
    if (collectMetrics) cacheMisses++;
  }
  
  static void incrementBatchOperations() {
    if (collectMetrics) batchOperations++;
  }
  
  static Map<String, dynamic> getMetrics() {
    return {
      'reads': totalReads,
      'writes': totalWrites,
      'cacheHits': cacheHits,
      'cacheMisses': cacheMisses,
      'batchOperations': batchOperations,
      'cacheHitRate': cacheHits > 0 ? (cacheHits / (cacheHits + cacheMisses)) : 0.0,
    };
  }
  
  static void resetMetrics() {
    totalReads = 0;
    totalWrites = 0;
    cacheHits = 0;
    cacheMisses = 0;
    batchOperations = 0;
  }
} 