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
              'Total: \$${sale.amount.toStringAsFixed(2)}',
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
                      'Detalles del Producto',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Producto', sale.productName),
                _buildDetailRow('Cantidad', '${sale.quantity} unidades'),
                _buildDetailRow('Precio Unitario', '\$${(sale.amount / sale.quantity).toStringAsFixed(2)}'),
                _buildDetailRow('Total', '\$${sale.amount.toStringAsFixed(2)}', isTotal: true),
                if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Notas', sale.notes!),
                ],
                const SizedBox(height: 8),
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