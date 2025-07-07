import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../models/category.dart';
import 'dashboard_card.dart';

class StockStatus extends StatelessWidget {
  final int? maxItems;
  const StockStatus({super.key, this.maxItems});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, dashboardVM, child) {
        if (dashboardVM.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (dashboardVM.error != null) {
          return const Center(child: Text('Error al cargar los productos'));
        }

        final data = dashboardVM.dashboardData;
        if (data == null) {
          return const Center(child: Text('No hay datos disponibles'));
        }

        final totalProducts = data.products.length;
        final lowStockProducts = data.products.where((p) => p.stock <= 10).toList();
        final outOfStockProducts = data.products.where((p) => p.stock == 0).length;
        final totalStock = data.products.fold<int>(0, (sum, p) => sum + p.stock);

        final limitedLowStockProducts = maxItems != null
            ? lowStockProducts.take(maxItems!).toList()
            : lowStockProducts;

        return Container(
          padding: const EdgeInsets.all(16),
          child: _buildDesktopLayout(context, limitedLowStockProducts),
        );
      },
    );
  }

  /// Layout para desktop
  Widget _buildDesktopLayout(BuildContext context, List<dynamic> lowStockProducts) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // Lista de productos
          Expanded(
            child: lowStockProducts.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    itemCount: lowStockProducts.length,
                    itemBuilder: (context, index) {
                      final product = lowStockProducts[index];
                      return _buildEnhancedStockItem(context, product, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Item de stock mejorado para web
  Widget _buildEnhancedStockItem(BuildContext context, dynamic product, int index) {
    final isEven = index % 2 == 0;
    final stockPercentage = (product.stock / 100) * 100; // Asumiendo 100 como stock máximo
    final isCritical = product.stock <= 5;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEven 
            ? [Colors.white, Colors.grey.shade50]
            : [Colors.grey.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical ? Colors.red.shade200 : Colors.orange.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono con color dinámico
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCritical 
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCritical ? Icons.warning : Icons.inventory,
              color: isCritical ? Colors.red : Colors.orange,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCritical 
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isCritical ? 'CRÍTICO' : 'BAJO',
                        style: TextStyle(
                          color: isCritical ? Colors.red : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Barra de progreso de stock
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stock: ${product.stock}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${stockPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: isCritical ? Colors.red : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: stockPercentage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCritical 
                                ? [Colors.red, Colors.red.shade400]
                                : [Colors.orange, Colors.orange.shade400],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categoría: ${_getCategoryName(context, product.categoryId)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Precio: \$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Estado vacío mejorado
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 48,
              color: Colors.green.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '¡Excelente!',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todos los productos tienen stock suficiente',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Obtiene el nombre de la categoría por ID
  String _getCategoryName(BuildContext context, String categoryId) {
    try {
      final dashboardVM = Provider.of<DashboardViewModel>(context, listen: false);
      final data = dashboardVM.dashboardData;
      if (data == null || categoryId.isEmpty) {
        return 'Sin categoría';
      }
      
      final category = data.categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => Category(id: '', name: 'Sin categoría', description: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      return category.name;
    } catch (e) {
      return 'Sin categoría';
    }
  }
} 