import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../models/category.dart';
import 'dashboard_card.dart';
import '../../widgets/skeleton_loading.dart';

class StockStatus extends StatefulWidget {
  final int? maxItems;
  const StockStatus({super.key, this.maxItems});

  @override
  State<StockStatus> createState() => _StockStatusState();
}

class _StockStatusState extends State<StockStatus> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<DashboardViewModel, List>(
      selector: (_, vm) => vm.lowStockProductsSummary,
      builder: (context, lowStockProducts, _) {
        final limitedLowStockProducts = widget.maxItems != null
            ? lowStockProducts.take(widget.maxItems!).toList()
            : lowStockProducts;
        final isMobile = MediaQuery.of(context).size.width < 600;
        if (isMobile) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Productos con bajo stock', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Total:  lowStockProducts.length}', style: const TextStyle(fontSize: 18, color: Colors.red)),
              ],
            ),
          );
        }
        if (limitedLowStockProducts.isEmpty) {
          final isMobile = MediaQuery.of(context).size.width < 600;
          return Container(
            width: double.infinity,
            height: isMobile ? 80 : 120,
            alignment: Alignment.center,
            child: Text('No hay productos con bajo stock', style: TextStyle(color: Colors.grey)),
          );
        }
        // Desktop/tablet: expandir
        return SizedBox.expand(
          child: _buildDesktopLayout(context, limitedLowStockProducts),
        );
      },
    );
  }

  /// Layout para desktop
  Widget _buildDesktopLayout(BuildContext context, List<dynamic> lowStockProducts) {
    // Limitar a los primeros 10 productos
    int maxItems = 10;
    bool showAll = false;
    if (lowStockProducts.length <= maxItems) showAll = true;
    List<dynamic> visibleProducts = showAll ? lowStockProducts : lowStockProducts.take(maxItems).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SizedBox(
        height: 120,
        child: visibleProducts.isEmpty
            ? _buildEmptyState(context)
            : Scrollbar(
                thumbVisibility: true,
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: List.generate(
                      visibleProducts.length,
                      (index) {
                        final product = visibleProducts[index];
                        final isCritical = product.stock <= 5;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCritical ? Icons.warning : Icons.inventory,
                                color: isCritical ? Colors.red : Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'x${product.stock}',
                                style: TextStyle(
                                  color: isCritical ? Colors.red : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCritical ? Colors.red.withOpacity(0.08) : Colors.orange.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
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
                        );
                      },
                    ),
                  ),
                ),
              ),
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
        color: isEven 
          ? Colors.white
          : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical ? Colors.red.shade200 : Colors.orange.shade200,
          width: 1,
        ),
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
                        Expanded(
                          child: Text(
                            'Stock: ${product.stock}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                    Expanded(
                      child: Text(
                        'Categoría: ${_getCategoryName(context, product.categoryId)}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
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