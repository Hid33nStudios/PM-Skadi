import 'package:flutter/foundation.dart' as foundation;
import '../models/dashboard_data.dart';
import '../services/hybrid_data_service.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';

class DashboardViewModel extends foundation.ChangeNotifier {
  HybridDataService dataService;
  AuthService authService;
  
  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _error;

  /// UID del último usuario autenticado para detectar cambios de sesión
  String? lastUserId;

  DashboardViewModel(this.dataService, this.authService);

  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Devuelve un mapa con el nombre de la categoría y la cantidad de productos en cada una
  Map<String, int> get categoryCounts {
    if (_dashboardData == null || _dashboardData!.products.isEmpty) return {};
    final Map<String, int> counts = {};
    // Crear un mapa de id de categoría a nombre
    final categoryIdToName = {for (var c in _dashboardData!.categories) c.id: c.name};
    for (final product in _dashboardData!.products) {
      final categoryName = categoryIdToName[product.categoryId] ?? 'Sin categoría';
      counts[categoryName] = (counts[categoryName] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> loadDashboardData() async {
    // Evitar múltiples llamadas simultáneas
    if (_isLoading) {
      print('⚠️  loadDashboardData ya está en ejecución, ignorando llamada');
      return;
    }
    
    // Evitar llamadas si ya hay datos y el usuario no cambió
    final user = authService.currentUser;
    if (_dashboardData != null && user?.uid == lastUserId && !_isLoading) {
      print('⚠️  Ya hay datos cargados para el mismo usuario, ignorando llamada');
      return;
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
      
      print('🔄 Llamando a dataService.getDashboardData()...');
      final dashboardMap = await dataService.getDashboardData();
      print('✅ getDashboardData completado');
      print('📦 dashboardMap recibido: ${dashboardMap.length} elementos');
      
      print('🔄 Llamando a dataService.getAllProducts()...');
      final products = await dataService.getAllProducts();
      print('✅ getAllProducts completado: ${products.length} productos');
      
      print('🔄 Llamando a dataService.getAllSales()...');
      final sales = await dataService.getAllSales();
      print('✅ getAllSales completado: ${sales.length} ventas');
      
      print('🔄 Llamando a dataService.getAllCategories()...');
      final categories = await dataService.getAllCategories();
      print('✅ getAllCategories completado: ${categories.length} categorías');
      
      print('🔄 Llamando a dataService.getAllMovements()...');
      final movements = await dataService.getAllMovements();
      print('✅ getAllMovements completado: ${movements.length} movimientos');
      
      print('📊 Datos cargados:');
      print('  - Productos: ${products.length}');
      print('  - Ventas: ${sales.length}');
      print('  - Categorías: ${categories.length}');
      print('  - Movimientos: ${movements.length}');
      
      // Mostrar detalles de categorías
      for (var category in categories) {
        print('    - Categoría: ${category.name} (ID: ${category.id})');
      }
      
      print('🔄 Calculando movimientos recientes...');
      // Calcular movimientos recientes (última semana)
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      final recentMovements = movements.where((movement) => 
        movement.date.isAfter(lastWeek)
      ).toList();
      print('✅ Movimientos recientes calculados: ${recentMovements.length}');
      
      print('🔄 Calculando ingresos totales...');
      // Calcular ingresos totales de todas las ventas
      final totalRevenue = sales.fold<double>(0.0, (sum, sale) => sum + sale.amount);
      print('✅ Ingresos totales calculados: \$${totalRevenue.toStringAsFixed(2)}');
      
      print('🔄 Creando DashboardData...');
      _dashboardData = DashboardData(
        totalProducts: dashboardMap['totalProducts'] ?? products.length,
        totalSales: dashboardMap['totalSales'] ?? sales.length,
        totalRevenue: totalRevenue,
        totalCategories: categories.length,
        recentMovements: recentMovements,
        products: products,
        sales: sales,
        categories: categories,
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
    print('✅ Datos limpiados');
    print('🔄 Notificando listeners...');
    notifyListeners();
    print('✅ Listeners notificados');
    print('🗑️  === FIN clearData ===');
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
        .fold(0.0, (sum, sale) => sum + sale.amount);
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
} 