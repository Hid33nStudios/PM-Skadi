import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/hybrid_data_service.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';
import '../utils/error_cases.dart';

class ProductViewModel extends ChangeNotifier {
  final HybridDataService _dataService;
  final AuthService _authService;
  
  List<Product> _products = [];
  int _offset = 0;
  final int _limit = 100;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _error;
  AppErrorType? _errorType;
  AppErrorType? get errorType => _errorType;

  ProductViewModel(this._dataService, this._authService);

  List<Product> get products => _products.where((p) => p.id.isNotEmpty).toList();
  bool get isLoading => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadInitialProducts() async {
    _products = [];
    _offset = 0;
    _hasMore = true;
    await loadMoreProducts();
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final newProducts = await _dataService.getAllProducts(offset: _offset, limit: _limit);
      if (newProducts.length < _limit) {
        _hasMore = false;
      }
      // Filtrar duplicados por id
      final existingIds = _products.map((p) => p.id).toSet();
      final uniqueNewProducts = newProducts.where((p) => !existingIds.contains(p.id)).toList();
      _products.addAll(uniqueNewProducts);
      _offset += uniqueNewProducts.length;
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

  Future<bool> addProduct(Product product) async {
    try {
      print('🔄 ProductViewModel: Agregando producto: ${product.name}');
      
      await _dataService.createProduct(product);
      await loadInitialProducts();
      print('✅ ProductViewModel: Producto agregado exitosamente');
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

  Future<bool> updateProduct(Product product) async {
    try {
      print('🔄 ProductViewModel: Actualizando producto: ${product.name}');
      
      await _dataService.updateProduct(product);
      await loadInitialProducts();
      print('✅ ProductViewModel: Producto actualizado exitosamente');
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

  Future<bool> deleteProduct(String id) async {
    try {
      print('🔄 ProductViewModel: Eliminando producto con ID: $id');
      
      await _dataService.deleteProduct(id);
      await loadInitialProducts();
      print('✅ ProductViewModel: Producto eliminado exitosamente');
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