import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sale.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import 'dashboard_card.dart';
import '../../widgets/skeleton_loading.dart';

class RecentActivity extends StatelessWidget {
  final int? maxItems;
  const RecentActivity({super.key, this.maxItems});

  @override
  Widget build(BuildContext context) {
    return Selector<DashboardViewModel, List>(
      selector: (_, vm) => vm.recentSalesSummary,
      builder: (context, recentSales, _) {
        if (recentSales.isEmpty) {
          return Center(child: Text('No hay actividad reciente.'));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentSales.length,
          itemBuilder: (context, index) {
            final sale = recentSales[index];
            return ListTile(
              leading: Icon(Icons.shopping_cart, color: Colors.green),
              title: Text(sale.productName),
              subtitle: Text('Cantidad: ${sale.quantity} - Monto: \$${(sale.amount / sale.quantity).toStringAsFixed(2)}'),
              trailing: Text('${sale.date.day}/${sale.date.month}/${sale.date.year}'),
            );
          },
        );
      },
    );
  }

  /// Layout para desktop
  Widget _buildDesktopLayout(BuildContext context, List<Sale> recentSales) {
    int maxItems = 10;
    bool showAll = false;
    if (recentSales.length <= maxItems) showAll = true;
    List<Sale> visibleSales = showAll ? recentSales : recentSales.take(maxItems).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mejorado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  'Últimos 7 días',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Lista de actividades
          Expanded(
            child: visibleSales.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    itemCount: visibleSales.length,
                    itemBuilder: (context, index) {
                      final sale = visibleSales[index];
                      return _buildEnhancedActivityItem(context, sale, index);
                    },
                  ),
          ),
          if (!showAll)
            Center(
              child: ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Toda la actividad reciente'),
                    content: SizedBox(
                      width: 400,
                      height: 400,
                      child: ListView.builder(
                        itemCount: recentSales.length,
                        itemBuilder: (context, index) {
                          final sale = recentSales[index];
                          return _buildEnhancedActivityItem(context, sale, index);
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
                child: const Text('Ver más'),
              ),
            ),
        ],
      ),
    );
  }

  /// Item de actividad mejorado para web
  Widget _buildEnhancedActivityItem(BuildContext context, Sale sale, int index) {
    final isEven = index % 2 == 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Icono con color dinámico
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart,
              color: Colors.green,
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
                        sale.productName,
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
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'VENTA',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Text(
                      'Cantidad: ${sale.quantity}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Precio: \$${(sale.amount / sale.quantity).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sale.formattedDate,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Text(
                      sale.formattedTotal,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay actividad reciente',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las ventas aparecerán aquí',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
} 