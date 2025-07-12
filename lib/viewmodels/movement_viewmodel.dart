import 'package:flutter/foundation.dart' as foundation;
import '../models/movement.dart';
import '../services/hybrid_data_service.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';
import '../utils/error_cases.dart';

class MovementViewModel extends foundation.ChangeNotifier {
  final HybridDataService _dataService;
  final AuthService _authService;
  
  List<Movement> _movements = [];
  Movement? _selectedMovement;
  Map<String, dynamic> _movementStats = {};
  bool _isLoading = false;
  String? _error;
  AppErrorType? _errorType;
  AppErrorType? get errorType => _errorType;
  int _offset = 0;
  final int _limit = 100;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  MovementViewModel(this._dataService, this._authService);

  List<Movement> get movements => _movements;
  Movement? get selectedMovement => _selectedMovement;
  Map<String, dynamic> get movementStats => _movementStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  HybridDataService get dataService => _dataService;

  Future<void> loadMovements() async {
    try {
      _isLoading = true;
      _error = null;
      _errorType = null;
      notifyListeners();

      print('🔄 Cargando movimientos');
      
      _movements = await _dataService.getAllMovements();
      
      print('📊 Movimientos cargados: ${_movements.length}');
      for (var movement in _movements) {
        print('  - Movimiento ${movement.id}: ${movement.type} - ${movement.quantity} unidades');
      }
      
      await _loadMovementStats();
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMovement(String movementId) async {
    try {
      _isLoading = true;
      _error = null;
      _errorType = null;
      notifyListeners();

      _selectedMovement = _movements.firstWhere((movement) => movement.id == movementId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMovement(Movement movement) async {
    try {
      print('🔄 MovementViewModel: Agregando movimiento: ${movement.type}');
      
      await _dataService.createMovement(movement);
      await loadMovements();
      print('✅ MovementViewModel: Movimiento agregado exitosamente');
      _errorType = null;
      return true;
    } catch (e, stackTrace) {
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMovement(String id) async {
    try {
      print('🔄 MovementViewModel: Eliminando movimiento con ID: $id');
      
      await _dataService.deleteMovement(id);
      await loadMovements();
      print('✅ MovementViewModel: Movimiento eliminado exitosamente');
      _errorType = null;
      return true;
    } catch (e, stackTrace) {
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      notifyListeners();
      return false;
    }
  }

  List<Movement> searchMovements(String query) {
    if (query.isEmpty) return _movements;
    
    return _movements.where((movement) {
      return movement.id.toLowerCase().contains(query.toLowerCase()) ||
             movement.type.toString().toLowerCase().contains(query.toLowerCase()) ||
             (movement.note?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  List<Movement> getMovementsByType(MovementType type) {
    return _movements.where((movement) => movement.type == type).toList();
  }

  List<Movement> getMovementsByProduct(String productId) {
    return _movements.where((movement) => movement.productId == productId).toList();
  }

  List<Movement> getMovementsByDateRange(DateTime startDate, DateTime endDate) {
    return _movements.where((movement) {
      return movement.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
             movement.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  Movement? getMovementById(String id) {
    try {
      return _movements.firstWhere((movement) => movement.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadMovementStats() async {
    try {
      if (_movements.isEmpty) {
        _movementStats = {
          'totalMovements': 0,
          'movementsByType': {},
          'recentMovements': 0,
        };
        return;
      }

      Map<String, int> movementsByType = {};
      int recentMovements = 0;
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));

      for (var movement in _movements) {
        final typeString = movement.type.toString().split('.').last;
        movementsByType[typeString] = (movementsByType[typeString] ?? 0) + 1;
        
        if (movement.date.isAfter(lastWeek)) {
          recentMovements++;
        }
      }

      _movementStats = {
        'totalMovements': _movements.length,
        'movementsByType': movementsByType,
        'recentMovements': recentMovements,
      };
    } catch (e, stackTrace) {
      print('❌ Error cargando estadísticas de movimientos: $e');
    }
  }

  void clearError() {
    _error = null;
    _errorType = null;
    notifyListeners();
  }

  void clearSelectedMovement() {
    _selectedMovement = null;
    notifyListeners();
  }

  Future<void> loadInitialMovements() async {
    _movements = [];
    _offset = 0;
    _hasMore = true;
    await loadMoreMovements();
  }

  Future<void> loadMoreMovements() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final newMovements = await _dataService.getAllMovements(offset: _offset, limit: _limit);
      if (newMovements.length < _limit) {
        _hasMore = false;
      }
      // Filtrar duplicados por id
      final existingIds = _movements.map((m) => m.id).toSet();
      final uniqueNewMovements = newMovements.where((m) => !existingIds.contains(m.id)).toList();
      _movements.addAll(uniqueNewMovements);
      _offset += uniqueNewMovements.length;
      await _loadMovementStats();
      _errorType = null;
    } catch (e, stackTrace) {
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
} 