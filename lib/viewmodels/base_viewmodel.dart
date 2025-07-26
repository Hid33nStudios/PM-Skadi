import 'package:flutter/foundation.dart';
import '../utils/safe_notifier.dart';

/// ViewModel base con notificación segura
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Notificar de forma segura
  @override
  void notifyListeners() {
    SafeNotifier.safeNotify(super.notifyListeners);
  }
  
  /// Establecer estado de carga
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  /// Establecer error
  void setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }
  
  /// Limpiar error
  void clearError() {
    setError(null);
  }
  
  /// Ejecutar operación con manejo de estado
  Future<T> executeOperation<T>(Future<T> Function() operation) async {
    try {
      setLoading(true);
      clearError();
      final result = await operation();
      return result;
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      setLoading(false);
    }
  }
} 