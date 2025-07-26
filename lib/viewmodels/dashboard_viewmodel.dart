import 'package:flutter/foundation.dart' as foundation;
import '../models/dashboard_data.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../services/firestore_data_service.dart';
import '../services/firestore_optimized_service.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';
import '../config/performance_config.dart';

class DashboardViewModel extends foundation.ChangeNotifier {
  FirestoreDataService? dataService;
  FirestoreOptimizedService? optimizedDataService;
  AuthService authService;
  
  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _error;

  /// UID del último usuario autenticado para detectar cambios de sesión
  String? lastUserId;

  DashboardViewModel(this.dataService, this.authService);
  
  // Constructor alternativo para usar FirestoreOptimizedService
  DashboardViewModel.withOptimizedService(this.optimizedDataService, this.authService);

  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // OPTIMIZACIÓN: Cache para categoryCounts
  Map<String, int>? _cachedCategoryCounts;
  List<Product>? _lastProductsForCache;
  List<Category>? _lastCategoriesForCache;

  /// Devuelve un mapa con el nombre de la categoría y la cantidad de productos en cada una
  Map<String, int> get categoryCounts {
    if (_dashboardData == null || _dashboardData!.products.isEmpty) return {};
    
    // OPTIMIZACIÓN: Usar cache si los datos no han cambiado
    if (_cachedCategoryCounts != null && 
        _lastProductsForCache == _dashboardData!.products &&
        _lastCategoriesForCache == _dashboardData!.categories) {
      return _cachedCategoryCounts!;
    }
    
    final Map<String, int> counts = {};
    // Crear un mapa de id de categoría a nombre
    final categoryIdToName = {for (var c in _dashboardData!.categories) c.id: c.name};
    for (final product in _dashboardData!.products) {
      final categoryName = categoryIdToName[product.categoryId] ?? 'Sin categoría';
      counts[categoryName] = (counts[categoryName] ?? 0) + 1;
    }
    
    // OPTIMIZACIÓN: Guardar en cache
    _cachedCategoryCounts = counts;
    _lastProductsForCache = List<Product>.from(_dashboardData!.products);
    _lastCategoriesForCache = List<Category>.from(_dashboardData!.categories);
    
    return counts;
  }

  Future<void> loadDashboardData() async {
    // Evitar múltiples llamadas simultáneas
    if (_isLoading) {
      print('⚠️  loadDashboardData ya está en ejecución, ignorando llamada');
      return;
    }
    
    // Permitir recargas si se solicita explícitamente o si no hay datos
    final user = authService.currentUser;
    if (_dashboardData != null && user?.uid == lastUserId && !_isLoading) {
      // Solo ignorar si no es una recarga explícita
      print('⚠️  Ya hay datos cargados para el mismo usuario, pero permitiendo recarga para actualizaciones');
    }
    
    // Actualizar lastUserId
    lastUserId = user?.uid;
    
    print('🚀 === INICIO loadDashboardData ===');
    print('⏰ Timestamp: ${DateTime.now()}');
    
    try {
      print('📝 Configurando estado de carga...');
      _isLoading = true;
      _error = null;
      notifyListeners();
      print('✅ Estado de carga configurado');

      print('🔍 Verificando usuario actual...');
      try {
        final user = authService.currentUser;
        print('🔑 Usuario actual: ${user?.uid ?? 'null'}');
        print('🔑 Email: ${user?.email ?? 'null'}');
        if (user == null) {
          print('⚠️  Usuario es null - esto podría ser el problema');
        }
      } catch (e) {
        print('❌ Error obteniendo usuario actual: $e');
      }
      
      // Declarar variables para los datos
      List<dynamic> products = [];
      List<dynamic> sales = [];
      List<dynamic> categories = [];
      List<dynamic> movements = [];
      
      int totalCategories = 0;
      // OPTIMIZACIÓN: Cargar datos en paralelo para mejor performance
      if (optimizedDataService != null) {
        print('🔄 Usando FirestoreOptimizedService con carga paralela...');
        
        // OPTIMIZACIÓN: Usar límites ajustados por hardware
        final maxItems = PerformanceConfig.getMaxItemsPerPage();
        print('📊 DashboardViewModel: Usando límite de ${maxItems} elementos por hardware');
        
        // Cargar datos críticos en paralelo
        final productsFuture = optimizedDataService!.getAllProducts(limit: maxItems);
        final salesFuture = optimizedDataService!.getAllSales(limit: maxItems);
        final categoriesFuture = optimizedDataService!.getAllCategories(limit: maxItems);
        final movementsFuture = optimizedDataService!.getAllMovements(limit: maxItems);
        
        // Ejecutar en paralelo
        final results = await Future.wait([
          productsFuture,
          salesFuture,
          categoriesFuture,
          movementsFuture,
        ]);
        
        final productsResult = results[0] as Map<String, dynamic>;
        final salesResult = results[1] as List<dynamic>;
        final categoriesResult = results[2] as List<dynamic>;
        final movementsResult = results[3] as List<dynamic>;
        
        products = productsResult['products'] as List<dynamic>;
        sales = salesResult;
        categories = categoriesResult;
        movements = movementsResult;
        
        // Obtener total de categorías por separado
        totalCategories = await optimizedDataService!.getCategoriesCount();
        
        print('✅ Carga paralela completada exitosamente');
      } else {
        print('🔄 Usando FirestoreDataService con carga paralela...');
        
        // Cargar datos críticos en paralelo
        final productsFuture = dataService?.getAllProducts() ?? Future.value([]);
        final salesFuture = dataService?.getAllSales() ?? Future.value([]);
        final categoriesFuture = dataService?.getAllCategories() ?? Future.value([]);
        final movementsFuture = dataService?.getAllMovements() ?? Future.value([]);
        
        // Ejecutar en paralelo
        final results = await Future.wait([
          productsFuture,
          salesFuture,
          categoriesFuture,
          movementsFuture,
        ]);
        
        products = results[0] as List<dynamic>;
        sales = results[1] as List<dynamic>;
        categories = results[2] as List<dynamic>;
        movements = results[3] as List<dynamic>;
        totalCategories = categories.length;
        
        print('✅ Carga paralela completada exitosamente');
      }
      
      print('📊 Datos cargados:');
      print('  - Productos: ${products.length}');
      print('  - Ventas: ${sales.length}');
      print('  - Categorías: ${categories.length}');
      print('  - Movimientos: ${movements.length}');
      
      // Mostrar categorías cargadas
      for (var category in categories) {
        print('    - Categoría: ${category.name} (ID: ${category.id})');
      }
      
      print('🔄 Calculando movimientos recientes...');
      final recentMovements = movements.cast<Movement>().where((m) => 
        m.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))
      ).toList();
      print('✅ Movimientos recientes calculados: ${recentMovements.length}');
      
      print('🔄 Calculando ingresos totales...');
      final totalRevenue = sales.fold<double>(0, (sum, sale) => sum + sale.total);
      print('✅ Ingresos totales calculados: \$${totalRevenue.toStringAsFixed(2)}');
      
      print('🔄 Creando DashboardData...');
      _dashboardData = DashboardData(
        totalProducts: products.length,
        totalSales: sales.length,
        totalRevenue: totalRevenue,
        totalCategories: totalCategories,
        recentMovements: recentMovements,
        products: products.cast<Product>(),
        sales: sales.cast<Sale>(),
        categories: categories.cast<Category>(),
      );
      print('✅ DashboardData creado exitosamente');
      
      print('📊 DashboardData final:');
      print('  - Total productos: ${_dashboardData!.totalProducts}');
      print('  - Total ventas: ${_dashboardData!.totalSales}');
      print('  - Total categorías: ${_dashboardData!.totalCategories}');
      print('  - Categorías en datos: ${_dashboardData!.categories.length}');
      print('  - Ingresos: \$${_dashboardData!.totalRevenue.toStringAsFixed(2)}');
      print('  - Movimientos recientes: ${recentMovements.length}');
      
      print('🔄 Configurando estado final...');
      _isLoading = false;
      print('✅ Estado final configurado');
      
      print('🔄 Notificando listeners...');
      notifyListeners();
      print('✅ Listeners notificados');
      
      print('🎉 === FIN loadDashboardData - EXITOSO ===');
      print('⏰ Timestamp: ${DateTime.now()}');
    } catch (e, stackTrace) {
      print('💥 === ERROR en loadDashboardData ===');
      print('⏰ Timestamp: ${DateTime.now()}');
      print('❌ Error: $e');
      print('📚 Stack trace:');
      print(stackTrace);
      print('🔄 Configurando estado de error...');
      _error = AppError.fromException(e, stackTrace).message;
      _isLoading = false;
      notifyListeners();
      print('✅ Estado de error configurado');
      print('💥 === FIN loadDashboardData - CON ERROR ===');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    print('🗑️  === clearData llamado ===');
    print('⏰ Timestamp: ${DateTime.now()}');
    print('🔄 Limpiando datos del dashboard...');
    _dashboardData = null;
    // OPTIMIZACIÓN: Limpiar cache cuando se limpian los datos
    _cachedCategoryCounts = null;
    _lastProductsForCache = null;
    _lastCategoriesForCache = null;
    print('✅ Datos y cache limpiados');
    print('🔄 Notificando listeners...');
    notifyListeners();
    print('✅ Listeners notificados');
    print('🗑️  === FIN clearData ===');
  }
  
  /// Recargar datos del dashboard cuando se detecten cambios
  Future<void> reloadOnChanges() async {
    print('🔄 DashboardViewModel: Recargando datos por cambios detectados...');
    await loadDashboardData();
    print('✅ DashboardViewModel: Datos recargados exitosamente');
  }

  /// Forzar recarga del dashboard
  Future<void> forceRefresh() async {
    print('🔄 === forceRefresh llamado ===');
    print('⏰ Timestamp: ${DateTime.now()}');
    
    // Invalidar cache del servicio de datos
    try {
      print('🗑️ Limpiando cache del servicio de datos...');
      if (optimizedDataService != null) {
        optimizedDataService!.clearCache();
        print('✅ Cache del FirestoreOptimizedService invalidado');
      } else {
        await dataService?.forceSync();
        print('✅ Cache del FirestoreDataService invalidado');
      }
    } catch (e) {
      print('⚠️ Error invalidando cache: $e');
    }
    
    print('🗑️ Limpiando datos del DashboardViewModel...');
    clearData();
    print('🔄 Recargando datos del dashboard...');
    await loadDashboardData();
    print('✅ === forceRefresh completado ===');
  }

  /// Actualizar solo el contador de categorías de manera eficiente
  void updateCategoryCount(int newCount) {
    if (_dashboardData != null) {
      _dashboardData = _dashboardData!.copyWith(totalCategories: newCount);
      notifyListeners();
      print('✅ Contador de categorías actualizado a: $newCount');
    }
  }

  /// Devuelve las ventas de los últimos 7 días (para RecentActivity)
  List get recentSalesSummary {
    if (_dashboardData == null || _dashboardData!.sales.isEmpty) return [];
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    return _dashboardData!.sales.where((sale) => sale.date.isAfter(lastWeek)).toList();
  }

  /// Devuelve el total de ingresos de la última semana
  double get weekRevenue {
    if (_dashboardData == null || _dashboardData!.sales.isEmpty) return 0.0;
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    return _dashboardData!.sales
        .where((sale) => sale.date.isAfter(lastWeek))
        .fold(0.0, (sum, sale) => sum + sale.total);
  }

  /// Devuelve la cantidad de ventas de la última semana
  int get weekSales {
    if (_dashboardData == null || _dashboardData!.sales.isEmpty) return 0;
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    return _dashboardData!.sales.where((sale) => sale.date.isAfter(lastWeek)).length;
  }

  /// Devuelve la lista de productos con stock bajo (stock <= minStock)
  List get lowStockProductsSummary {
    if (_dashboardData == null || _dashboardData!.products.isEmpty) return [];
    return _dashboardData!.products.where((p) => p.stock <= p.minStock).toList();
  }

  /// Ranking de productos más vendidos (por cantidad o ingresos)
  /// type: 'cantidad' o 'ingresos'
  List<Map<String, dynamic>> getProductRanking({String type = 'cantidad', int top = 10}) {
    if (_dashboardData == null || _dashboardData!.sales.isEmpty) return [];
    final Map<String, Map<String, dynamic>> ranking = {};
    for (final sale in _dashboardData!.sales) {
      for (final item in sale.items) {
        if (!ranking.containsKey(item.productId)) {
          ranking[item.productId] = {
            'productId': item.productId,
            'productName': item.productName,
            'cantidad': 0,
            'ingresos': 0.0,
          };
        }
        ranking[item.productId]!['cantidad'] += item.quantity;
        ranking[item.productId]!['ingresos'] += item.subtotal;
      }
    }
    final rankingList = ranking.values.toList();
    rankingList.sort((a, b) => (type == 'ingresos'
        ? (b['ingresos'] as double).compareTo(a['ingresos'] as double)
        : (b['cantidad'] as int).compareTo(a['cantidad'] as int)));
    return rankingList.take(top).toList();
  }

  /// Ejemplo de uso en la UI:
  /// final topPorCantidad = getProductRanking(type: 'cantidad');
  /// final topPorIngresos = getProductRanking(type: 'ingresos');
} 