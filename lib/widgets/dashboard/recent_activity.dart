import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sale.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import 'dashboard_card.dart';
import '../../widgets/skeleton_loading.dart';
import '../../utils/validators.dart';

class RecentActivity extends StatefulWidget {
  final int? maxItems;
  final double? height;
  const RecentActivity({super.key, this.maxItems, this.height});

  @override
  State<RecentActivity> createState() => _RecentActivityState();
}

class _RecentActivityState extends State<RecentActivity> {
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<DashboardViewModel, List<Sale>>(
      selector: (_, vm) => vm.dashboardData?.sales ?? [],
      builder: (context, sales, _) {
        if (sales.isEmpty) {
          final isMobile = MediaQuery.of(context).size.width < 600;
          return Container(
            alignment: Alignment.center,
            height: isMobile ? 80 : 120,
            child: Text('No hay actividad reciente', style: TextStyle(color: Colors.grey)),
          );
        }
        final items = widget.maxItems != null ? sales.take(widget.maxItems!).toList() : sales;
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = MediaQuery.of(context).size.width < 600;
            if (isMobile) {
              return Container(
                width: double.infinity,
                height: 120,
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: items.map((sale) {
                    final totalProductos = sale.items.fold<int>(0, (sum, item) => sum + item.quantity);
                    final totalVenta = sale.total;
                    final cliente = (sale.customerName.isNotEmpty) ? sale.customerName : 'Venta';
                    final fecha = '${sale.date.day.toString().padLeft(2, '0')}/${sale.date.month.toString().padLeft(2, '0')}/${sale.date.year}';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                        title: Row(
                          children: [
                            Icon(Icons.receipt_long, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(cliente, style: const TextStyle(fontWeight: FontWeight.w600))),
                            const SizedBox(width: 8),
                            Text('Total: ' + formatPrice(totalVenta), style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(fecha, style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 16),
                            Icon(Icons.shopping_bag, size: 16, color: Colors.orange.shade400),
                            const SizedBox(width: 4),
                            Text('$totalProductos productos', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sale.items.map((item) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.check_circle_outline, color: Colors.teal),
                                title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: Text('Cantidad: ${item.quantity}'),
                                trailing: Text(formatPrice(item.subtotal), style: const TextStyle(color: Colors.blueGrey)),
                              )).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            } else {
              return SizedBox.expand(
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: items.map((sale) {
                    final totalProductos = sale.items.fold<int>(0, (sum, item) => sum + item.quantity);
                    final totalVenta = sale.total;
                    final cliente = (sale.customerName.isNotEmpty) ? sale.customerName : 'Venta';
                    final fecha = '${sale.date.day.toString().padLeft(2, '0')}/${sale.date.month.toString().padLeft(2, '0')}/${sale.date.year}';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                        title: Row(
                          children: [
                            Icon(Icons.receipt_long, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(cliente, style: const TextStyle(fontWeight: FontWeight.w600))),
                            const SizedBox(width: 8),
                            Text('Total: ' + formatPrice(totalVenta), style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(fecha, style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 16),
                            Icon(Icons.shopping_bag, size: 16, color: Colors.orange.shade400),
                            const SizedBox(width: 4),
                            Text('$totalProductos productos', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sale.items.map((item) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.check_circle_outline, color: Colors.teal),
                                title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: Text('Cantidad: ${item.quantity}'),
                                trailing: Text(formatPrice(item.subtotal), style: const TextStyle(color: Colors.blueGrey)),
                              )).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            }
          },
        );
      },
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

// Clase auxiliar para mostrar cada producto vendido en la actividad reciente
class _RecentProductSale {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final DateTime saleDate;
  final String saleId;
  _RecentProductSale({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.saleDate,
    required this.saleId,
  });
} 