import 'package:flutter/foundation.dart' as foundation;
import '../models/dashboard_data.dart';
import '../services/hybrid_data_service.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';

class DashboardViewModel extends foundation.ChangeNotifier {
  final HybridDataService _dataService;
  final AuthService _authService;
  
  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _error;

  DashboardViewModel(this._dataService, this._authService);

  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboardData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔄 Cargando datos del dashboard');
      
      // Usar el método getDashboardData del servicio híbrido
      final dashboardMap = await _dataService.getDashboardData();
      
      // Cargar datos adicionales para el DashboardData
      print('🔄 DashboardViewModel: Cargando productos...');
      final products = await _dataService.getAllProducts();
      
      print('🔄 DashboardViewModel: Cargando ventas...');
      final sales = await _dataService.getAllSales();
      
      print('🔄 DashboardViewModel: Cargando categorías...');
      final categories = await _dataService.getAllCategories();
      
      print('🔄 DashboardViewModel: Cargando movimientos...');
      final movements = await _dataService.getAllMovements();
      
      print('📊 DashboardViewModel: Datos cargados:');
      print('  - Productos: ${products.length}');
      print('  - Ventas: ${sales.length}');
      print('  - Categorías: ${categories.length}');
      print('  - Movimientos: ${movements.length}');
      
      // Mostrar detalles de categorías
      for (var category in categories) {
        print('    - Categoría: ${category.name} (ID: ${category.id})');
      }
      
      // Calcular movimientos recientes (última semana)
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      final recentMovements = movements.where((movement) => 
        movement.date.isAfter(lastWeek)
      ).toList();
      
      // Calcular ingresos totales de todas las ventas
      final totalRevenue = sales.fold<double>(0.0, (sum, sale) => sum + sale.amount);
      
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
      
      print('📊 DashboardViewModel: DashboardData creado:');
      print('  - Total productos: ${_dashboardData!.totalProducts}');
      print('  - Total ventas: ${_dashboardData!.totalSales}');
      print('  - Total categorías: ${_dashboardData!.totalCategories}');
      print('  - Categorías en datos: ${_dashboardData!.categories.length}');
      
      print('✅ Dashboard data cargado exitosamente');
      print('  - Productos: ${_dashboardData!.totalProducts}');
      print('  - Ventas: ${_dashboardData!.totalSales}');
      print('  - Ingresos: \$${_dashboardData!.totalRevenue.toStringAsFixed(2)}');
      print('  - Movimientos: ${recentMovements.length}');
      
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace).message;
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _dashboardData = null;
    notifyListeners();
  }
} 