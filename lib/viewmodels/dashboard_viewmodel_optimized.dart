import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/firestore_optimized_service.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/category.dart' as stock_category;
import '../utils/error_handler.dart';

class DashboardViewModelOptimized extends ChangeNotifier {
  final FirestoreOptimizedService _firestoreService;
  
  // Estado del dashboard
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  
  // Datos del dashboard
  Map<String, dynamic>? _dashboardData;
  List<Product> _products = [];
  List<stock_category.Category> _categories = [];
  List<Sale> _recentSales = [];
  List<Product> _lowStockProducts = [];
  
  // Métricas en tiempo real
  Map<String, dynamic>? _currentMetrics;
  Map<String, dynamic>? _performanceMetrics;
  
  // Streams para métricas
  StreamSubscription<Map<String, dynamic>>? _metricsSubscription;
  StreamSubscription<Map<String, dynamic>>? _performanceSubscription;

  DashboardViewModelOptimized({
    required FirestoreOptimizedService firestoreService,
  }) : _firestoreService = firestoreService {
    _initializeMetricsStreams();
  }

  // ===== GETTERS =====

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  
  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<Product> get products => _products;
  List<stock_category.Category> get categories => _categories;
  List<Sale> get recentSales => _recentSales;
  List<Product> get lowStockProducts => _lowStockProducts;
  
  Map<String, dynamic>? get currentMetrics => _currentMetrics;
  Map<String, dynamic>? get performanceMetrics => _performanceMetrics;

  // ===== INICIALIZACIÓN =====

  /// Inicializar métricas en tiempo real
  void _initializeMetricsStreams() {
    _metricsSubscription = _firestoreService.metricsStream.listen(
      (metrics) {
        _currentMetrics = metrics;
        notifyListeners();
      },
      onError: (error) {
        print('❌ DashboardViewModelOptimized: Error en métricas: $error');
      },
    );

    _performanceSubscription = _firestoreService.performanceStream.listen(
      (performance) {
        _performanceMetrics = performance;
        notifyListeners();
      },
      onError: (error) {
        print('❌ DashboardViewModelOptimized: Error en performance: $error');
      },
    );
  }

  /// Inicializar dashboard
  Future<void> initializeDashboard() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      _clearError();
      
      print('🔄 DashboardViewModelOptimized: Inicializando dashboard...');
      
      // Cargar datos en paralelo para mejor performance
      await Future.wait([
        _loadDashboardData(),
        _loadProducts(),
        _loadCategories(),
        _loadRecentSales(),
        _loadLowStockProducts(),
      ]);
      
      _isInitialized = true;
      print('✅ DashboardViewModelOptimized: Dashboard inicializado exitosamente');
    } catch (e) {
      _setError('Error inicializando dashboard: ${e.toString()}');
      print('❌ DashboardViewModelOptimized: Error inicializando dashboard: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Recargar dashboard
  Future<void> refreshDashboard() async {
    try {
      _setLoading(true);
      _clearError();
      
      print('🔄 DashboardViewModelOptimized: Recargando dashboard...');
      
      // Limpiar cache del servicio para forzar recarga
      _firestoreService.clearCache();
      
      // Recargar datos en paralelo
      await Future.wait([
        _loadDashboardData(),
        _loadProducts(),
        _loadCategories(),
        _loadRecentSales(),
        _loadLowStockProducts(),
      ]);
      
      print('✅ DashboardViewModelOptimized: Dashboard recargado exitosamente');
    } catch (e) {
      _setError('Error recargando dashboard: ${e.toString()}');
      print('❌ DashboardViewModelOptimized: Error recargando dashboard: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ===== CARGA DE DATOS =====

  /// Cargar datos del dashboard
  Future<void> _loadDashboardData() async {
    try {
      final data = await _firestoreService.getDashboardData();
      _dashboardData = data;
      print('📊 DashboardViewModelOptimized: Datos del dashboard cargados');
    } catch (e) {
      print('❌ DashboardViewModelOptimized: Error cargando datos del dashboard: $e');
      rethrow;
    }
  }

  /// Cargar productos
  Future<void> _loadProducts() async {
    try {
      final result = await _firestoreService.getAllProducts(limit: 50);
      _products = result['products'] as List<Product>;
      print('📦 DashboardViewModelOptimized: Productos cargados: ${_products.length}');
    } catch (e) {
      print('❌ DashboardViewModelOptimized: Error cargando productos: $e');
      rethrow;
    }
  }

  /// Cargar categorías
  Future<void> _loadCategories() async {
    try {
      final categories = await _firestoreService.getAllCategories(limit: 20);
      _categories = categories;
      print('📂 DashboardViewModelOptimized: Categorías cargadas: ${categories.length}');
    } catch (e) {
      print('❌ DashboardViewModelOptimized: Error cargando categorías: $e');
      rethrow;
    }
  }

  /// Cargar ventas recientes
  Future<void> _loadRecentSales() async {
    try {
      final sales = await _firestoreService.getAllSales(limit: 10);
      _recentSales = sales;
      print('💰 DashboardViewModelOptimized: Ventas recientes cargadas: ${sales.length}');
    } catch (e) {
      print('❌ DashboardViewModelOptimized: Error cargando ventas recientes: $e');
      rethrow;
    }
  }

  /// Cargar productos con stock bajo
  Future<void> _loadLowStockProducts() async {
    try {
      final lowStock = await _firestoreService.getLowStockProducts();
      _lowStockProducts = lowStock;
      print('⚠️ DashboardViewModelOptimized: Productos con stock bajo cargados: ${lowStock.length}');
    } catch (e) {
      print('❌ DashboardViewModelOptimized: Error cargando productos con stock bajo: $e');
      rethrow;
    }
  }

  // ===== OPERACIONES DE PRODUCTOS =====

  /// Recargar productos después de agregar uno nuevo
  Future<void> reloadProducts() async {
    try {
      print('🔄 DashboardViewModelOptimized: Recargando productos...');
      await _loadProducts();
      print('✅ DashboardViewModelOptimized: Productos recargados exitosamente');
    } catch (e) {
      print('❌ DashboardViewModelOptimized: Error recargando productos: $e');
      _setError('Error recargando productos: ${e.toString()}');
    }
  }

  /// Recargar datos del dashboard después de cambios
  Future<void> reloadDashboardData() async {
    try {
      print('🔄 DashboardViewModelOptimized: Recargando datos del dashboard...');
      await _loadDashboardData();
      print('✅ DashboardViewModelOptimized: Datos del dashboard recargados exitosamente');
    } catch (e) {
      print('❌ DashboardViewModelOptimized: Error recargando datos del dashboard: $e');
      _setError('Error recargando datos del dashboard: ${e.toString()}');
    }
  }

  /// Crear producto
  Future<void> createProduct(Product product) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _firestoreService.createProduct(product);
      
      // Recargar productos después de crear
      await _loadProducts();
      await _loadLowStockProducts();
      
      print('✅ DashboardViewModelOptimized: Producto creado exitosamente');
    } catch (e) {
      _setError('Error creando producto: ${e.toString()}');
      print('❌ DashboardViewModelOptimized: Error creando producto: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Actualizar producto
  Future<void> updateProduct(Product product) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _firestoreService.updateProduct(product);
      
      // Recargar productos después de actualizar
      await _loadProducts();
      await _loadLowStockProducts();
      
      print('✅ DashboardViewModelOptimized: Producto actualizado exitosamente');
    } catch (e) {
      _setError('Error actualizando producto: ${e.toString()}');
      print('❌ DashboardViewModelOptimized: Error actualizando producto: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Eliminar producto
  Future<void> deleteProduct(String productId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _firestoreService.deleteProduct(productId);
      
      // Recargar productos después de eliminar
      await _loadProducts();
      await _loadLowStockProducts();
      
      print('✅ DashboardViewModelOptimized: Producto eliminado exitosamente');
    } catch (e) {
      _setError('Error eliminando producto: ${e.toString()}');
      print('❌ DashboardViewModelOptimized: Error eliminando producto: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ===== OPERACIONES DE CATEGORÍAS =====

  /// Crear categoría
  Future<void> createCategory(stock_category.Category category) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _firestoreService.createCategory(category);
      
      // Recargar categorías después de crear
      await _loadCategories();
      
      print('✅ DashboardViewModelOptimized: Categoría creada exitosamente');
    } catch (e) {
      _setError('Error creando categoría: ${e.toString()}');
      print('❌ DashboardViewModelOptimized: Error creando categoría: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Actualizar categoría
  Future<void> updateCategory(stock_category.Category category) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _firestoreService.updateCategory(category);
      
      // Recargar categorías después de actualizar
      await _loadCategories();
      
      print('✅ DashboardViewModelOptimized: Categoría actualizada exitosamente');
    } catch (e) {
      _setError('Error actualizando categoría: ${e.toString()}');
      print('❌ DashboardViewModelOptimized: Error actualizando categoría: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Eliminar categoría
  Future<void> deleteCategory(String categoryId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _firestoreService.deleteCategory(categoryId);
      
      // Recargar categorías después de eliminar
      await _loadCategories();
      
      print('✅ DashboardViewModelOptimized: Categoría eliminada exitosamente');
    } catch (e) {
      _setError('Error eliminando categoría: ${e.toString()}');
      print('❌ DashboardViewModelOptimized: Error eliminando categoría: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ===== OPERACIONES DE VENTAS =====

  /// Crear venta
  Future<void> createSale(Sale sale) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _firestoreService.createSale(sale);
      
      // Recargar datos después de crear venta
      await Future.wait([
        _loadDashboardData(),
        _loadRecentSales(),
        _loadProducts(),
        _loadLowStockProducts(),
      ]);
      
      print('✅ DashboardViewModelOptimized: Venta creada exitosamente');
    } catch (e) {
      _setError('Error creando venta: ${e.toString()}');
      print('❌ DashboardViewModelOptimized: Error creando venta: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ===== MÉTRICAS Y ESTADÍSTICAS =====

  /// Obtener estadísticas del servicio
  Future<Map<String, dynamic>> getServiceStats() async {
    try {
      return await _firestoreService.getStats();
    } catch (e) {
      print('❌ DashboardViewModelOptimized: Error obteniendo estadísticas: $e');
      return {};
    }
  }

  /// Obtener estado de sincronización
  Map<String, dynamic> getSyncStatus() {
    return _firestoreService.getSyncStatus();
  }

  /// Forzar sincronización
  Future<void> forceSync() async {
    try {
      await _firestoreService.forceSync();
      print('✅ DashboardViewModelOptimized: Sincronización forzada');
    } catch (e) {
      print('❌ DashboardViewModelOptimized: Error en sincronización: $e');
    }
  }

  /// Resetear métricas
  void resetMetrics() {
    _firestoreService.resetMetrics();
    print('🔄 DashboardViewModelOptimized: Métricas reseteadas');
  }

  // ===== UTILIDADES =====

  /// Establecer estado de carga
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Establecer error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Limpiar error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Limpiar recursos
  @override
  void dispose() {
    _metricsSubscription?.cancel();
    _performanceSubscription?.cancel();
    super.dispose();
    print('🧹 DashboardViewModelOptimized: Recursos limpiados');
  }
} 