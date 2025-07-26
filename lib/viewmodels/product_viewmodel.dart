import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/firestore_data_service.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';
import '../utils/error_cases.dart';
import 'base_viewmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_optimized_service.dart';
import 'dashboard_viewmodel.dart';
import 'package:uuid/uuid.dart';

class ProductViewModel extends BaseViewModel {
  final FirestoreOptimizedService _dataService;
  final AuthService _authService;
  DashboardViewModel? _dashboardViewModel;
  
  List<Product> _products = [];
  int _totalProducts = 0;
  DocumentSnapshot? _lastProductDoc;
  final int _limit = 100;
  int get totalProducts => _totalProducts;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _error;
  AppErrorType? _errorType;
  AppErrorType? get errorType => _errorType;

  ProductViewModel(this._dataService, this._authService);
  
  /// Establecer referencia al DashboardViewModel para notificaciones
  void setDashboardViewModel(DashboardViewModel dashboardViewModel) {
    _dashboardViewModel = dashboardViewModel;
  }

  List<Product> get products => _products.where((p) => p.id.isNotEmpty).toList();
  bool get isLoading => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadInitialProducts() async {
    // OPTIMIZACIÓN: No recargar si ya tenemos datos
    if (_products.isNotEmpty) {
      print('📦 ProductViewModel: Ya hay productos cargados (${_products.length}), usando datos existentes');
      return;
    }
    
    _products = [];
    _lastProductDoc = null;
    _hasMore = true;
    
    try {
      print('🔄 ProductViewModel: Cargando productos iniciales...');
      final firestoreService = _dataService as FirestoreOptimizedService;
      
      // Limpiar cache antes de cargar para asegurar datos frescos
      firestoreService.clearCache();
      
      // OPTIMIZACIÓN: Cargar solo la primera página para mejor performance
      final result = await firestoreService.getAllProducts(limit: _limit);
      final firstPageProducts = result['products'] as List<Product>;
      final lastDoc = result['lastDoc'] as DocumentSnapshot?;
      
      _products = firstPageProducts;
      _totalProducts = firstPageProducts.length; // Actualizar basándose en productos reales
      _hasMore = firstPageProducts.length >= _limit;
      _lastProductDoc = lastDoc;
      
      print('📊 ProductViewModel: Total de productos en primera página: $_totalProducts');
      print('📊 ProductViewModel: ¿Hay más páginas? $_hasMore');
      print('✅ ProductViewModel: Productos cargados: ${_products.length}');
      _errorType = null;
    } catch (e, stackTrace) {
      print('❌ ProductViewModel: Error en loadInitialProducts: $e');
      print(stackTrace);
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
    } finally {
      notifyListeners();
    }
  }

  /// Método para forzar recarga de productos después de cambios
  Future<void> forceReloadProducts() async {
    try {
      print('🔄 ProductViewModel: Forzando recarga de productos...');
      
      // Limpiar cache del servicio
      if (_dataService is FirestoreOptimizedService) {
        (_dataService as FirestoreOptimizedService).clearCache();
        print('🗑️ ProductViewModel: Cache limpiado para forzar recarga');
      }
      
      // Esperar un momento para asegurar que Firestore haya procesado los cambios
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Forzar recarga incluso si ya hay datos
      _products = [];
      _lastProductDoc = null;
      _hasMore = true;
      
      await loadInitialProducts();
      
      print('✅ ProductViewModel: Recarga forzada completada');
    } catch (e, stackTrace) {
      print('❌ ProductViewModel: Error en forceReloadProducts: $e');
      print(stackTrace);
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
    }
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final firestoreService = _dataService as FirestoreOptimizedService;
      final result = await firestoreService.getAllProducts(
        limit: _limit,
        startAfter: _lastProductDoc,
      );
      final newProducts = result['products'] as List<Product>;
      final lastDoc = result['lastDoc'] as DocumentSnapshot?;
      if (newProducts.length < _limit) {
        _hasMore = false;
      }
      if (lastDoc != null) {
        _lastProductDoc = lastDoc;
      }
      // Filtrar duplicados por id
      final existingIds = _products.map((p) => p.id).toSet();
      final uniqueNewProducts = newProducts.where((p) => !existingIds.contains(p.id)).toList();
      _products.addAll(uniqueNewProducts);
      _errorType = null;
    } catch (e, stackTrace) {
      print('❌ ProductViewModel: Error en loadMoreProducts: $e');
      print(stackTrace);
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(Product product) async {
    try {
      print('🔄 ProductViewModel: Agregando producto: ${product.name}');
      print('📝 ProductViewModel: Datos del producto: ${product.toMap()}');
      
      // Generar un UUID si el id está vacío
      final String newId = product.id.isEmpty ? const Uuid().v4() : product.id;
      final newProduct = product.copyWith(id: newId);
      
      // OPTIMIZACIÓN: Agregar inmediatamente a la lista local para UI instantánea
      _products.insert(0, newProduct); // Insertar al inicio
      _totalProducts++;
      notifyListeners(); // Actualizar UI inmediatamente
      
      print('✅ ProductViewModel: Producto agregado localmente para UI instantánea');
      
      // Sincronizar con Firestore en background (sin bloquear la UI)
      _syncProductToFirestore(newProduct);
      
      _errorType = null;
      return true;
    } catch (e, stackTrace) {
      print('❌ ProductViewModel: Error al agregar producto: $e');
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      notifyListeners();
      return false;
    }
  }

  /// Sincronizar producto con Firestore en background
  Future<void> _syncProductToFirestore(Product product) async {
    try {
      print('🔄 ProductViewModel: Sincronizando producto con Firestore en background');
      
      // Crear el producto en Firestore
      await _dataService.createProduct(product);
      print('✅ ProductViewModel: Producto sincronizado con Firestore');
      
      // Limpiar cache del servicio para forzar recarga en otros ViewModels
      if (_dataService is FirestoreOptimizedService) {
        (_dataService as FirestoreOptimizedService).clearCache();
        print('🗑️ ProductViewModel: Cache limpiado para forzar recarga');
      }
      
      // Notificar al DashboardViewModel para que recargue sus datos
      if (_dashboardViewModel != null) {
        print('🔄 ProductViewModel: Notificando al DashboardViewModel...');
        await _dashboardViewModel!.reloadOnChanges();
        print('✅ ProductViewModel: DashboardViewModel notificado');
      }
      
    } catch (e) {
      print('❌ ProductViewModel: Error sincronizando con Firestore: $e');
      // Si falla la sincronización, mantener el producto local pero marcar como error
      _error = 'Producto agregado localmente pero no se pudo sincronizar con el servidor';
      _errorType = AppErrorType.sincronizacion;
      notifyListeners();
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      print('🔄 ProductViewModel: Actualizando producto: ${product.name}');
      
      // OPTIMIZACIÓN: Actualizar inmediatamente en la lista local para UI instantánea
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners(); // Actualizar UI inmediatamente
        print('✅ ProductViewModel: Producto actualizado localmente para UI instantánea');
      }
      
      // Sincronizar con Firestore en background
      _syncUpdateToFirestore(product);
      
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

  /// Sincronizar actualización con Firestore en background
  Future<void> _syncUpdateToFirestore(Product product) async {
    try {
      print('🔄 ProductViewModel: Sincronizando actualización con Firestore en background');
      
      // Actualizar el producto en Firestore
      await _dataService.updateProduct(product);
      print('✅ ProductViewModel: Producto actualizado en Firestore');
      
      // Limpiar cache del servicio para forzar recarga en otros ViewModels
      if (_dataService is FirestoreOptimizedService) {
        (_dataService as FirestoreOptimizedService).clearCache();
        print('🗑️ ProductViewModel: Cache limpiado para forzar recarga');
      }
      
      // Notificar al DashboardViewModel para que recargue sus datos
      if (_dashboardViewModel != null) {
        print('🔄 ProductViewModel: Notificando al DashboardViewModel...');
        await _dashboardViewModel!.reloadOnChanges();
        print('✅ ProductViewModel: DashboardViewModel notificado');
      }
      
    } catch (e) {
      print('❌ ProductViewModel: Error sincronizando actualización con Firestore: $e');
      // Si falla la sincronización, mantener el producto local pero marcar como error
      _error = 'Producto actualizado localmente pero no se pudo sincronizar con el servidor';
      _errorType = AppErrorType.sincronizacion;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      print('🔄 ProductViewModel: Eliminando producto con ID: $id');
      
      // OPTIMIZACIÓN: Eliminar inmediatamente de la lista local para UI instantánea
      final deletedProduct = _products.firstWhere((p) => p.id == id);
      _products.removeWhere((p) => p.id == id);
      _totalProducts--;
      notifyListeners(); // Actualizar UI inmediatamente
      
      print('✅ ProductViewModel: Producto eliminado localmente para UI instantánea');
      
      // Sincronizar con Firestore en background
      _syncDeleteToFirestore(id, deletedProduct);
      
      _errorType = null;
      return true;
    } catch (e, stackTrace) {
      print('❌ ProductViewModel: Error al eliminar producto: $e');
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      notifyListeners();
      return false;
    }
  }

  /// Sincronizar eliminación con Firestore en background
  Future<void> _syncDeleteToFirestore(String id, Product deletedProduct) async {
    try {
      print('🔄 ProductViewModel: Sincronizando eliminación con Firestore en background');
      
      // Eliminar el producto en Firestore
      await _dataService.deleteProduct(id);
      print('✅ ProductViewModel: Producto eliminado en Firestore');
      
      // Limpiar cache del servicio para forzar recarga en otros ViewModels
      if (_dataService is FirestoreOptimizedService) {
        (_dataService as FirestoreOptimizedService).clearCache();
        print('🗑️ ProductViewModel: Cache limpiado para forzar recarga');
      }
      
      // Notificar al DashboardViewModel para que recargue sus datos
      if (_dashboardViewModel != null) {
        print('🔄 ProductViewModel: Notificando al DashboardViewModel...');
        await _dashboardViewModel!.reloadOnChanges();
        print('✅ ProductViewModel: DashboardViewModel notificado');
      }
      
    } catch (e) {
      print('❌ ProductViewModel: Error sincronizando eliminación con Firestore: $e');
      // Si falla la eliminación en Firestore, restaurar el producto localmente
      _products.add(deletedProduct);
      _totalProducts++;
      notifyListeners();
      _error = 'Producto eliminado localmente pero no se pudo sincronizar con el servidor';
      _errorType = AppErrorType.sincronizacion;
      notifyListeners();
    }
  }

  Future<bool> updateStock(String id, int newStock) async {
    try {
      print('🔄 ProductViewModel: Actualizando stock del producto $id a $newStock');
      
      final product = _products.firstWhere((p) => p.id == id);
      final updatedProduct = product.copyWith(
        stock: newStock,
        updatedAt: DateTime.now(),
      );
      
      final success = await updateProduct(updatedProduct);
      
      if (success) {
        print('✅ ProductViewModel: Stock actualizado exitosamente');
        _errorType = null;
        return true;
      } else {
        print('❌ ProductViewModel: Error al actualizar stock');
        return false;
      }
    } catch (e, stackTrace) {
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      notifyListeners();
      return false;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      if (query.isEmpty) return _products;
      
      // Usar el método de búsqueda del servicio híbrido
      final results = await _dataService.searchProducts(query);
      _errorType = null;
      return results;
    } catch (e, stackTrace) {
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      notifyListeners();
      return [];
    }
  }

  Future<List<Product>> getLowStockProducts() async {
    try {
      return await _dataService.getLowStockProducts();
      _errorType = null;
    } catch (e, stackTrace) {
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      notifyListeners();
      return [];
    }
  }

  List<Product> getProductsByCategory(String categoryId) {
    return _products.where((product) => product.categoryId == categoryId).toList();
  }

  Future<Product?> getProductById(String id) async {
    try {
      return await _dataService.getProductById(id);
      _errorType = null;
    } catch (e, stackTrace) {
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      notifyListeners();
      return null;
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      return await _dataService.getProductByBarcode(barcode);
      _errorType = null;
    } catch (e, stackTrace) {
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    _errorType = null;
    notifyListeners();
  }
} 