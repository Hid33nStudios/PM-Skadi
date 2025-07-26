import 'package:flutter/foundation.dart';

class MigrationConfig {
  static const bool enableMigration = true;
  static const bool enableHiveCleanup = true;
  static const bool enableLogging = true;
  
  // Configuración de migración
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration migrationTimeout = Duration(minutes: 5);
  
  // Configuración de logging
  static void log(String message) {
    if (enableLogging) {
      print('📋 MigrationConfig: $message');
    }
  }
  
  static void logError(String message) {
    if (enableLogging) {
      print('❌ MigrationConfig: $message');
    }
  }
  
  static void logSuccess(String message) {
    if (enableLogging) {
      print('✅ MigrationConfig: $message');
    }
  }
  
  // Configuración de migración por tipo de dato
  static const Map<String, bool> migrationSettings = {
    'categories': true,
    'products': true,
    'sales': true,
    'movements': true,
  };
  
  // Verificar si un tipo de dato debe migrarse
  static bool shouldMigrate(String dataType) {
    return migrationSettings[dataType] ?? false;
  }
  
  // Configuración de validación
  static const bool validateAfterMigration = true;
  static const bool backupBeforeMigration = false;
  
  // Configuración de limpieza
  static const bool clearHiveAfterSuccessfulMigration = true;
  static const bool keepHiveBackup = false;
} 