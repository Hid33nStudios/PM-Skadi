import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/sale_viewmodel.dart';
import '../theme/responsive.dart';
import '../widgets/responsive_form.dart';
import '../models/sale.dart';
import '../utils/error_cases.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  late int _pageSize;
  late int _currentMax;
  late ScrollController _scrollController;
  late bool _isLoadingMore;

  @override
  void initState() {
    super.initState();
    _pageSize = 10;
    _currentMax = 0;
    _scrollController = ScrollController();
    _isLoadingMore = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSales();
    });
  }

  Future<void> _loadSales() async {
    await context.read<SaleViewModel>().loadSales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildResponsiveAppBar(),
      body: _buildLazyLoadingSalesList(),
    );
  }

  /// AppBar responsive
  AppBar _buildResponsiveAppBar() {
    return AppBar(
      title: Text(
        'Historial de Ventas',
        style: TextStyle(
          fontSize: Responsive.getResponsiveFontSize(context, 20),
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: Responsive.getResponsiveSpacing(context)),
          child: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
            tooltip: 'Actualizar',
            iconSize: Responsive.isMobile(context) ? 24 : 28,
          ),
        ),
      ],
    );
  }

  Widget _buildLazyLoadingSalesList() {
    final viewModel = context.watch<SaleViewModel>();
    final sales = viewModel.sales;
    if (viewModel.isLoading && sales.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    if (viewModel.error != null) {
      final errorType = viewModel.errorType ?? AppErrorType.desconocido;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showAppError(context, errorType);
      });
      return const SizedBox.shrink();
    }
    if (sales.isEmpty) {
      return Center(child: Text('No hay ventas registradas.'));
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return _buildSaleItem(sale);
            },
          ),
        ),
        if (viewModel.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton(
              onPressed: viewModel.isLoadingMore ? null : () => viewModel.loadMoreSales(),
              child: viewModel.isLoadingMore
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Cargar más'),
            ),
          ),
      ],
    );
  }

  Widget _buildSaleItem(Sale sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.shopping_cart,
            color: Colors.green,
          ),
        ),
        title: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(sale.date),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cliente: ${sale.customerName.isNotEmpty ? sale.customerName : 'Sin especificar'}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            Text(
              'Total: \$${sale.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
            if (sale.notes != null && sale.notes!.isNotEmpty)
              Text(
                sale.notes!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Productos vendidos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tabla de productos
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[200]),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Cant.', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('P. Unit.', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...sale.items.map((item) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(item.productName),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('${item.quantity}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('\$${item.unitPrice % 1 == 0 ? item.unitPrice.toStringAsFixed(0) : item.unitPrice.toStringAsFixed(2)}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('\$${item.subtotal % 1 == 0 ? item.subtotal.toStringAsFixed(0) : item.subtotal.toStringAsFixed(2)}'),
                        ),
                      ],
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Vendido el ${DateFormat('dd/MM/yyyy').format(sale.date)} a las ${DateFormat('HH:mm').format(sale.date)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Notas', sale.notes!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.green : Colors.black87,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}