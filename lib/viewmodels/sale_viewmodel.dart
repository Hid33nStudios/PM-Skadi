import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../services/hybrid_data_service.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';

class SaleViewModel extends foundation.ChangeNotifier {
  final HybridDataService _dataService;
  final AuthService _authService;
  
  List<Sale> _sales = [];
  Sale? _selectedSale;
  Map<String, dynamic> _saleStats = {};
  bool _isLoading = false;
  String? _error;
  
  // Callback para notificar cambios al dashboard
  VoidCallback? _onSaleAdded;

  SaleViewModel(this._dataService, this._authService);

  List<Sale> get sales => _sales;
  Sale? get selectedSale => _selectedSale;
  Map<String, dynamic> get saleStats => _saleStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Método para registrar el callback
  void setOnSaleAddedCallback(VoidCallback callback) {
    _onSaleAdded = callback;
  }

  // Método para limpiar el callback
  void clearOnSaleAddedCallback() {
    _onSaleAdded = null;
  }

  Future<void> loadSales() async {
    try {
      print('🔄 [PRODUCCION] Iniciando carga de ventas...');
      print('🔄 [PRODUCCION] Usuario autenticado: ${_authService.currentUser?.uid ?? 'NO AUTENTICADO'}');
      print('🔄 [PRODUCCION] Estado inicial - isLoading: $_isLoading');
      
      _isLoading = true;
      _error = null;
      print('🔄 [PRODUCCION] Estado después de setear isLoading=true: $_isLoading');
      notifyListeners();
      print('🔄 [PRODUCCION] notifyListeners() llamado');

      _sales = await _dataService.getAllSales();
      print('✅ [PRODUCCION] Ventas cargadas: ${_sales.length}');
      for (var sale in _sales) {
        print('  - Venta ${sale.id}: ${sale.amount} - ${sale.quantity} items');
      }
      
      await _loadSaleStats();
      print('🔄 [PRODUCCION] Estadísticas cargadas');
      
      _isLoading = false;
      print('🔄 [PRODUCCION] Estado después de setear isLoading=false: $_isLoading');
      notifyListeners();
      print('✅ [PRODUCCION] notifyListeners() final llamado - Carga completada');
    } catch (e, stackTrace) {
      print('❌ [PRODUCCION] Error al cargar ventas: $e');
      print('❌ [PRODUCCION] Stack: $stackTrace');
      _error = AppError.fromException(e, stackTrace).message;
      _isLoading = false;
      print('🔄 [PRODUCCION] Estado después de error - isLoading: $_isLoading');
      notifyListeners();
      print('❌ [PRODUCCION] notifyListeners() de error llamado');
    }
  }

  Future<void> loadSale(String saleId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _selectedSale = _sales.firstWhere((sale) => sale.id == saleId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace).message;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSale(Sale sale) async {
    try {
      print('🔄 SaleViewModel: Agregando venta: ${sale.amount}');
      print('📝 SaleViewModel: Datos de la venta: ${sale.toMap()}');
      
      print('🔄 SaleViewModel: Llamando a _dataService.createSale...');
      await _dataService.createSale(sale);
      print('✅ SaleViewModel: _dataService.createSale completado');
      
      print('🔄 SaleViewModel: Recargando ventas...');
      await loadSales();
      print('✅ SaleViewModel: Venta agregada exitosamente');
      
      // Notificar al dashboard que se agregó una venta
      if (_onSaleAdded != null) {
        print('🔄 SaleViewModel: Notificando al dashboard...');
        _onSaleAdded!();
      }
      
      return true;
    } catch (e, stackTrace) {
      print('❌ SaleViewModel: Error al agregar venta: $e');
      print('❌ SaleViewModel: Stack trace: $stackTrace');
      _error = AppError.fromException(e, stackTrace).message;
      print('❌ SaleViewModel: Error procesado: $_error');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSale(String id) async {
    try {
      print('🔄 SaleViewModel: Eliminando venta con ID: $id');
      
      await _dataService.deleteSale(id);
      await loadSales();
      print('✅ SaleViewModel: Venta eliminada exitosamente');
      return true;
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace).message;
      notifyListeners();
      return false;
    }
  }

  List<Sale> searchSales(String query) {
    if (query.isEmpty) return _sales;
    
    return _sales.where((sale) {
      return sale.id.toLowerCase().contains(query.toLowerCase()) ||
             sale.productName.toLowerCase().contains(query.toLowerCase()) ||
             (sale.notes?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  List<Sale> getSalesByDateRange(DateTime startDate, DateTime endDate) {
    return _sales.where((sale) {
      return sale.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
             sale.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  Sale? getSaleById(String id) {
    try {
      return _sales.firstWhere((sale) => sale.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadSaleStats() async {
    try {
      if (_sales.isEmpty) {
        _saleStats = {
          'totalSales': 0,
          'totalRevenue': 0.0,
          'averageSaleValue': 0.0,
          'totalItemsSold': 0,
        };
        return;
      }

      double totalRevenue = 0.0;
      int totalItemsSold = 0;

      for (var sale in _sales) {
        totalRevenue += sale.amount;
        totalItemsSold += sale.quantity;
      }

      _saleStats = {
        'totalSales': _sales.length,
        'totalRevenue': totalRevenue,
        'averageSaleValue': totalRevenue / _sales.length,
        'totalItemsSold': totalItemsSold,
      };
    } catch (e, stackTrace) {
      print('❌ Error cargando estadísticas de ventas: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelectedSale() {
    _selectedSale = null;
    notifyListeners();
  }
} 