import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/sync_service.dart';
import '../services/hybrid_data_service.dart';
import '../utils/error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/error_cases.dart';

class SyncViewModel extends ChangeNotifier {
  final SyncService _syncService;
  final HybridDataService _hybridService;

  AppErrorType? _errorType;
  AppErrorType? get errorType => _errorType;

  SyncViewModel(this._syncService, this._hybridService);

  // Estados
  bool _isOnline = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _pendingChangesCount = 0;
  List<Map<String, dynamic>> _pendingChanges = [];
  Timer? _statusTimer;
  bool _isFirebaseConnected = true;
  DateTime? _lastFirebaseCheck;
  bool _lastFirebaseCheckResult = true;
  bool isInitialSyncDone = false;

  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingChangesCount => _pendingChangesCount;
  List<Map<String, dynamic>> get pendingChanges => _pendingChanges;
  bool get isFirebaseConnected => _isFirebaseConnected;

  /// Inicializar el ViewModel
  Future<void> initialize() async {
    try {
      // Obtener estado inicial
      await _updateSyncStatus();
      await checkFirebaseConnection(force: true);
      
      // Configurar timer para actualizar estado
      _startStatusTimer();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Actualizar estado de sincronización
  Future<void> _updateSyncStatus() async {
    try {
      print('🔄 SyncViewModel: Actualizando estado de sincronización...');
      
      // Obtener estado del servicio híbrido
      final hybridStatus = _hybridService.getSyncStatus();
      print('📊 SyncViewModel: Estado híbrido: $hybridStatus');
      
      // Obtener estado del servicio de sincronización
      final syncStatus = _syncService.getSyncStatus();
      print('📊 SyncViewModel: Estado de sincronización: $syncStatus');
      
      final newIsOnline = hybridStatus['isOnline'] as bool;
      final newIsSyncing = syncStatus['isSyncing'] as bool;
      final newLastSyncTime = hybridStatus['lastSync'] != null 
          ? DateTime.parse(hybridStatus['lastSync'] as String)
          : null;
      final newPendingChangesCount = hybridStatus['pendingOperations'] as int;
      bool changed = false;
      if (_isOnline != newIsOnline) { _isOnline = newIsOnline; changed = true; }
      if (_isSyncing != newIsSyncing) { _isSyncing = newIsSyncing; changed = true; }
      if (_lastSyncTime != newLastSyncTime) { _lastSyncTime = newLastSyncTime; changed = true; }
      if (_pendingChangesCount != newPendingChangesCount) { _pendingChangesCount = newPendingChangesCount; changed = true; }
      
      print('📊 SyncViewModel: Estado final:');
      print('  - Online: $_isOnline');
      print('  - Syncing: $_isSyncing');
      print('  - LastSync: $_lastSyncTime');
      print('  - PendingChanges: $_pendingChangesCount');
      
      // Obtener estadísticas de la base de datos local
      final stats = await _hybridService.getStats();
      print('📊 SyncViewModel: Estadísticas: $stats');
      // Marcar sincronización inicial como lista SIEMPRE tras la primera llamada exitosa
      if (!isInitialSyncDone) {
        isInitialSyncDone = true;
        print('✅ SyncViewModel: Sincronización inicial marcada como completada (independiente de si hay datos)');
        // También marcar como online si hay conexión
        if (_isOnline && _isFirebaseConnected) {
          print('✅ SyncViewModel: Estado online y Firebase conectado - marcando como sincronizado');
        }
        notifyListeners();
      }
      
      // Si hay usuario autenticado y está online, marcar como sincronizado
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && _isOnline && _isFirebaseConnected && _pendingChangesCount == 0) {
        print('✅ SyncViewModel: Usuario autenticado, online y sin pendientes - estado verde');
      }
      if (changed) notifyListeners();
    } catch (e) {
      print('❌ SyncViewModel: Error actualizando estado: $e');
      throw AppError.fromException(e);
    }
  }

  /// Verificar conexión real con Firebase (leyendo el doc del usuario)
  Future<void> checkFirebaseConnection({bool force = false}) async {
    try {
      print('🔄 SyncViewModel: Verificando conexión con Firebase...');
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        print('❌ SyncViewModel: No hay usuario autenticado');
        if (_isFirebaseConnected != false) {
          _isFirebaseConnected = false;
          notifyListeners();
        }
        return;
      }
      print('📊 SyncViewModel: UID del usuario: $uid');
      final now = DateTime.now();
      if (!force && _lastFirebaseCheck != null && now.difference(_lastFirebaseCheck!).inMinutes < 5) {
        // Usar el resultado cacheado por más tiempo
        if (_isFirebaseConnected != _lastFirebaseCheckResult) {
          _isFirebaseConnected = _lastFirebaseCheckResult;
          notifyListeners();
        }
        print('📊 SyncViewModel: Usando resultado cacheado de conexión Firebase: $_isFirebaseConnected');
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('pm').doc(uid).get();
      print('📊 SyncViewModel: Documento existe: ${doc.exists}');
      bool newResult = false;
      if (doc.exists) {
        final data = doc.data();
        print('📊 SyncViewModel: Datos del documento: $data');
        if (data?['username'] != null || data?['email'] != null) {
          newResult = true;
          print('✅ SyncViewModel: Conexión con Firebase exitosa');
        } else {
          newResult = false;
          print('❌ SyncViewModel: Documento existe pero no tiene username/email');
        }
      } else {
        newResult = false;
        print('❌ SyncViewModel: Documento del usuario no existe');
      }
      _lastFirebaseCheck = now;
      _lastFirebaseCheckResult = newResult;
      if (_isFirebaseConnected != newResult) {
        _isFirebaseConnected = newResult;
        notifyListeners();
      }
    } catch (e) {
      if (_isFirebaseConnected != false) {
        _isFirebaseConnected = false;
        notifyListeners();
      }
      print('❌ SyncViewModel: Error verificando conexión con Firebase: $e');
    }
    print('📊 SyncViewModel: Estado de conexión Firebase: $_isFirebaseConnected');
  }

  /// Iniciar timer de actualización de estado
  void _startStatusTimer() {
    // Actualizar estado cada 2 minutos (menos frecuente)
    _statusTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _updateSyncStatus();
      // Solo verificar Firebase cada 5 minutos
      if (_lastFirebaseCheck == null || 
          DateTime.now().difference(_lastFirebaseCheck!).inMinutes >= 5) {
        checkFirebaseConnection();
      }
    });
  }

  /// Sincronización manual
  Future<void> forceSync() async {
    try {
      await _hybridService.forceSync();
      await _updateSyncStatus();
      _errorType = null;
    } catch (e) {
      final appError = AppError.fromException(e);
      _errorType = appError.appErrorType;
      throw appError;
    }
  }

  /// Limpiar cambios pendientes
  Future<void> clearPendingChanges() async {
    try {
      // Limpiar datos locales (cuidado: esto eliminará todos los datos)
      await _hybridService.clearLocalData();
      await _updateSyncStatus();
      _errorType = null;
    } catch (e) {
      final appError = AppError.fromException(e);
      _errorType = appError.appErrorType;
      throw appError;
    }
  }

  /// Obtener estado de sincronización como texto
  String getSyncStatusText() {
    if (!_isOnline) {
      return 'Sin conexión';
    }
    
    if (_isSyncing) {
      return 'Sincronizando...';
    }
    
    if (_pendingChangesCount > 0) {
      return 'Pendientes: $_pendingChangesCount';
    }
    
    if (_lastSyncTime != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastSyncTime!);
      
      if (difference.inMinutes < 1) {
        return 'Sincronizado';
      } else if (difference.inHours < 1) {
        return 'Sincronizado';
      } else if (difference.inDays < 1) {
        return 'Sincronizado';
      } else {
        return 'Sincronizado';
      }
    }
    
    return 'Sincronizado';
  }

  /// Obtener icono de estado
  String getSyncStatusIcon() {
    if (!_isOnline) {
      return '📡'; // Sin conexión
    }
    
    if (_isSyncing) {
      return '🔄'; // Sincronizando
    }
    
    if (_pendingChangesCount > 0) {
      return '⏳'; // Pendientes
    }
    
    return '✅'; // Sincronizado
  }

  /// Obtener color de estado
  int getSyncStatusColor() {
    if (!_isOnline) {
      return 0xFFFF6B6B; // Rojo
    }
    if (!_isFirebaseConnected) {
      return 0xFFFF6B6B; // Rojo si no hay conexión real a Firebase
    }
    if (_isSyncing) {
      return 0xFFFFA726; // Naranja
    }
    if (_pendingChangesCount > 0) {
      return 0xFFFFB74D; // Amarillo
    }
    
    // Si está online, Firebase conectado, no sincronizando y no hay pendientes = VERDE
    // También verde si hay usuario autenticado y está online
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && _isOnline && _isFirebaseConnected) {
      return 0xFF66BB6A; // Verde
    }
    
    return 0xFF66BB6A; // Verde por defecto si está online
  }

  /// Obtener resumen de cambios pendientes
  String getPendingChangesSummary() {
    if (_pendingChangesCount == 0) {
      return 'No hay cambios pendientes';
    }

    return '$_pendingChangesCount operaciones pendientes de sincronización';
  }

  /// Verificar si hay conflictos de sincronización
  bool get hasConflicts {
    // Por ahora, no implementamos detección de conflictos
    // Se puede implementar más adelante
    return false;
  }

  /// Resolver conflictos de sincronización
  Future<void> resolveConflicts() async {
    try {
      // Por ahora, solo forzar sincronización
      await forceSync();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Obtener estadísticas de sincronización
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final stats = await _hybridService.getStats();
      
      return {
        'isOnline': _isOnline,
        'isSyncing': _isSyncing,
        'lastSyncTime': _lastSyncTime?.toIso8601String(),
        'pendingChangesCount': _pendingChangesCount,
        'hasConflicts': hasConflicts,
        'syncStatusText': getSyncStatusText(),
        'syncStatusIcon': getSyncStatusIcon(),
        'syncStatusColor': getSyncStatusColor(),
        'pendingChangesSummary': getPendingChangesSummary(),
        'localStats': stats['local'],
        'syncStats': stats['sync'],
      };
    } catch (e) {
      return {
        'isOnline': _isOnline,
        'isSyncing': _isSyncing,
        'lastSyncTime': _lastSyncTime?.toIso8601String(),
        'pendingChangesCount': _pendingChangesCount,
        'hasConflicts': hasConflicts,
        'syncStatusText': getSyncStatusText(),
        'syncStatusIcon': getSyncStatusIcon(),
        'syncStatusColor': getSyncStatusColor(),
        'pendingChangesSummary': getPendingChangesSummary(),
        'error': e.toString(),
      };
    }
  }

  /// Verificar si la sincronización está funcionando correctamente
  bool get isSyncHealthy {
    if (!_isOnline) return true; // Offline es normal
    
    // Si no hay datos para sincronizar, considerar saludable
    if (_pendingChangesCount == 0 && _lastSyncTime == null) {
      return true; // No hay datos = no hay problema
    }
    
    if (_lastSyncTime == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    
    // Considerar no saludable si no se sincronizó en más de 5 minutos Y hay cambios pendientes
    return difference.inMinutes < 5 || _pendingChangesCount == 0;
  }

  /// Obtener recomendaciones de sincronización
  String getSyncRecommendations() {
    if (!_isOnline) {
      return 'Sin conexión a internet. Los datos se guardan localmente.';
    }
    if (!_isFirebaseConnected) {
      return 'No se pudo conectar con Firebase. Revisa tu conexión o intenta más tarde.';
    }
    if (_isSyncing) {
      return 'Sincronizando datos con Firebase...';
    }
    if (_pendingChangesCount > 10) {
      return 'Muchos cambios pendientes ($_pendingChangesCount). Considera sincronizar manualmente.';
    }
    if (_pendingChangesCount > 0) {
      return 'Hay $_pendingChangesCount cambios pendientes de sincronización.';
    }
    // Si no hay datos y nunca se sincronizó, es normal
    if (_lastSyncTime == null && _pendingChangesCount == 0) {
      return 'No hay datos para sincronizar. Todo está funcionando correctamente.';
    }
    if (!isSyncHealthy) {
      if (_lastSyncTime == null) {
        return 'Nunca se ha sincronizado. Verifica tu conexión a internet.';
      } else {
        final now = DateTime.now();
        final difference = now.difference(_lastSyncTime!);
        return 'Última sincronización hace ${difference.inMinutes} minutos. Verifica tu conexión.';
      }
    }
    return 'La sincronización funciona correctamente.';
  }

  /// Obtener información detallada del estado
  Future<Map<String, dynamic>> getDetailedStatus() async {
    try {
      final stats = await _hybridService.getStats();
      
      return {
        'connectivity': {
          'isOnline': _isOnline,
          'lastSync': _lastSyncTime?.toIso8601String(),
        },
        'sync': {
          'isSyncing': _isSyncing,
          'pendingOperations': _pendingChangesCount,
          'isHealthy': isSyncHealthy,
        },
        'database': {
          'local': stats['local'],
          'sync': stats['sync'],
        },
        'recommendations': getSyncRecommendations(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'connectivity': {
          'isOnline': _isOnline,
          'lastSync': _lastSyncTime?.toIso8601String(),
        },
        'sync': {
          'isSyncing': _isSyncing,
          'pendingOperations': _pendingChangesCount,
          'isHealthy': isSyncHealthy,
        },
      };
    }
  }

  /// Limpiar recursos
  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }
} 