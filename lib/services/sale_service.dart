import '../models/sale.dart';
import '../utils/error_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SaleService {
  final FirebaseFirestore _firestore;

  SaleService([FirebaseFirestore? firestore]) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Obtener todas las ventas
  Future<List<Sale>> getSales() async {
    try {
      final querySnapshot = await _firestore
          .collection('sales')
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Sale.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Obtener venta por ID
  Future<Sale?> getSale(String id) async {
    try {
      final doc = await _firestore.collection('sales').doc(id).get();
      if (doc.exists) {
        return Sale.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Agregar venta
  Future<String> addSale(Sale sale) async {
    try {
      final docRef = await _firestore.collection('sales').add(sale.toMap());
      return docRef.id;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Actualizar venta
  Future<void> updateSale(String id, Sale sale) async {
    try {
      await _firestore.collection('sales').doc(id).update(sale.toMap());
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Eliminar venta
  Future<void> deleteSale(String id) async {
    try {
      final sale = await getSale(id);
      if (sale != null) {
        await _firestore.collection('sales').doc(id).delete();
      }
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Obtener ventas por rango de fechas
  Future<List<Sale>> getSalesByDateRange(
    DateTime startDate,
    DateTime endDate
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('sales')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Sale.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Obtener ventas por producto
  Future<List<Sale>> getSalesByProduct(String productId) async {
    try {
      final sales = await getSales();
      // Filtrar ventas donde algún item tiene ese productId
      return sales.where((sale) => sale.items.any((item) => item.productId == productId)).toList();
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Obtener estadísticas de ventas
  Future<Map<String, dynamic>> getSalesStats() async {
    try {
      final sales = await getSales();
      final totalSales = sales.length;
      final totalRevenue = sales.fold<double>(0, (sum, sale) => sum + sale.total);
      final averageSale = totalSales > 0 ? totalRevenue / totalSales : 0;
      // Calcular ventas por mes (últimos 12 meses)
      final now = DateTime.now();
      final monthlyStats = <String, double>{};
      for (int i = 0; i < 12; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        final monthSales = sales.where((sale) => 
          sale.date.year == month.year && sale.date.month == month.month
        ).toList();
        monthlyStats[monthKey] = monthSales.fold<double>(0, (sum, sale) => sum + sale.total);
      }
      return {
        'totalSales': totalSales,
        'totalRevenue': totalRevenue,
        'averageSale': averageSale,
        'monthlyStats': monthlyStats,
      };
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Obtener productos más vendidos
  Future<List<Map<String, dynamic>>> getTopSellingProducts() async {
    try {
      final sales = await getSales();
      final productSales = <String, Map<String, dynamic>>{};
      for (final sale in sales) {
        for (final item in sale.items) {
          if (!productSales.containsKey(item.productId)) {
            productSales[item.productId] = {
              'productId': item.productId,
              'productName': item.productName,
              'quantity': 0,
              'total': 0.0,
            };
          }
          productSales[item.productId]!['quantity'] += item.quantity;
          productSales[item.productId]!['total'] += item.subtotal;
        }
      }
      final sortedProducts = productSales.values.toList()
        ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
      return sortedProducts.take(10).toList();
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }
} 