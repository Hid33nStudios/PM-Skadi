import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/sale_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../models/sale.dart';
import '../models/dashboard_data.dart';
import '../utils/error_handler.dart';
import '../widgets/responsive_form.dart';
import '../theme/responsive.dart';
import '../router/app_router.dart';
import '../utils/error_cases.dart';
import '../utils/validators.dart';
import 'package:intl/intl.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchType = 'all'; // 'all', 'name', 'date', 'amount'
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  
  // Variables de paginación
  int _currentPage = 0;
  static const int _itemsPerPage = 6;
  int _totalPages = 0;
  List<Sale> _filteredSales = [];

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar llamar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSales();
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    await context.read<SaleViewModel>().loadSales();
  }

  Future<void> _loadDashboardData() async {
    await context.read<DashboardViewModel>().loadDashboardData();
  }

  Future<void> _deleteSale(Sale sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Venta'),
        content: Text('¿Estás seguro de que deseas eliminar la venta de "${sale.customerName.isNotEmpty ? sale.customerName : 'Sin especificar'}" por un total de ${sale.formattedTotal}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await context.read<SaleViewModel>().deleteSale(sale.id);
        if (success) {
          // Recargar dashboard inmediatamente
          context.read<DashboardViewModel>().loadDashboardData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Venta eliminada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          final saleViewModel = context.read<SaleViewModel>();
          final errorType = saleViewModel.errorType ?? AppErrorType.desconocido;
          showAppError(context, errorType);
        }
      }
    }
  }

  void _showSaleDetails(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de Venta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cliente: ${sale.customerName.isNotEmpty ? sale.customerName : 'Sin especificar'}'),
              const SizedBox(height: 8),
              Text('Total: ${sale.formattedTotal}'),
              const SizedBox(height: 12),
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
                        child: Text(' [${formatPrice(item.unitPrice)}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(' [${formatPrice(item.subtotal)}'),
                      ),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Text('Fecha: ${sale.formattedDate}'),
              if (sale.notes != null && sale.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Notas: ${sale.notes!}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _editSale(Sale sale) {
    // Por ahora, mostrar un mensaje informativo
    // En el futuro se puede implementar una pantalla de edición completa
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Venta'),
        content: const Text(
          'La funcionalidad de edición de ventas está en desarrollo. '
          'Por ahora, puedes eliminar la venta y crear una nueva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesStats() {
    return Consumer<DashboardViewModel>(
      builder: (context, dashboardVM, _) {
        if (dashboardVM.isLoading || dashboardVM.dashboardData == null) {
          return const SizedBox.shrink();
        }

        final data = dashboardVM.dashboardData!;
        final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
        
        // Calcular estadísticas adicionales
        final todaySales = _calculateTodaySales(data.sales);
        final weekSales = _calculateWeekSales(data.sales);
        final averageSale = data.totalSales > 0 ? data.totalRevenue / data.totalSales : 0.0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Responsive.isMobile(context)
                ? _buildMobileStats(data, currencyFormat, todaySales, weekSales, averageSale)
                : _buildDesktopStats(data, currencyFormat, todaySales, weekSales, averageSale),
          ),
        );
      },
    );
  }

  Widget _buildMobileStats(DashboardData data, NumberFormat currencyFormat, double todaySales, double weekSales, double averageSale) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total Ventas',
                '${data.totalSales}',
                Icons.receipt,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Ingresos',
                currencyFormat.format(data.totalRevenue),
                Icons.attach_money,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Hoy',
                currencyFormat.format(todaySales),
                Icons.today,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Semana',
                currencyFormat.format(weekSales),
                Icons.calendar_view_week,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatItem(
          'Promedio',
          currencyFormat.format(averageSale),
          Icons.analytics,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildDesktopStats(DashboardData data, NumberFormat currencyFormat, double todaySales, double weekSales, double averageSale) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Total Ventas',
            '${data.totalSales}',
            Icons.receipt,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            'Ingresos',
            currencyFormat.format(data.totalRevenue),
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            'Hoy',
            currencyFormat.format(todaySales),
            Icons.today,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            'Semana',
            currencyFormat.format(weekSales),
            Icons.calendar_view_week,
            Colors.purple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            'Promedio',
            currencyFormat.format(averageSale),
            Icons.analytics,
            Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primera fila: Botón y búsqueda
            Row(
              children: [
                // Botón para añadir venta
                IconButton(
                  onPressed: () => context.goToNewSale(),
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Agregar venta',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    foregroundColor: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                // Barra de búsqueda
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: _getSearchLabel(),
                      prefixIcon: Icon(Icons.search, color: Colors.blue[700]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 0; // Reiniciar a la primera página
                    });
                  },
                  ),
                ),
                const SizedBox(width: 12),
                // Botón de filtros
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (value) {
                    setState(() {
                      _searchType = value;
                      _searchController.clear();
                      _searchQuery = '';
                      _currentPage = 0; // Reiniciar a la primera página
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'all',
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 20),
                          SizedBox(width: 8),
                          Text('Buscar en todo'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'name',
                      child: Row(
                        children: [
                          Icon(Icons.inventory, size: 20),
                          SizedBox(width: 8),
                          Text('Por nombre de producto'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'date',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 20),
                          SizedBox(width: 8),
                          Text('Por fecha'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'amount',
                      child: Row(
                        children: [
                          Icon(Icons.attach_money, size: 20),
                          SizedBox(width: 8),
                          Text('Por monto'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Segunda fila: Filtros avanzados
            Row(
              children: [
                // Filtro de fecha
                if (_searchType == 'date') ...[
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _startDate != null 
                                  ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                  : 'Fecha inicial',
                              style: TextStyle(
                                color: _startDate != null ? Colors.black : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _endDate != null 
                                  ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                  : 'Fecha final',
                              style: TextStyle(
                                color: _endDate != null ? Colors.black : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                
                // Filtro de monto
                if (_searchType == 'amount') ...[
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Monto mínimo',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _minAmount = double.tryParse(value);
                          _currentPage = 0; // Reiniciar a la primera página
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Monto máximo',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _maxAmount = double.tryParse(value);
                          _currentPage = 0; // Reiniciar a la primera página
                        });
                      },
                    ),
                  ),
                ],
                
                // Botón limpiar filtros
                if (_searchType == 'date' || _searchType == 'amount') ...[
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _minAmount = null;
                        _maxAmount = null;
                        _searchController.clear();
                        _searchQuery = '';
                        _currentPage = 0; // Reiniciar a la primera página
                      });
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Limpiar'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSearchLabel() {
    switch (_searchType) {
      case 'name':
        return 'Buscar por nombre de producto';
      case 'date':
        return 'Buscar por fecha (dd/mm/yyyy)';
      case 'amount':
        return 'Buscar por monto';
      default:
        return 'Buscar en todo';
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _currentPage = 0; // Reiniciar a la primera página
      });
    }
  }

  double _calculateTodaySales(List<Sale> sales) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return sales
        .where((s) => s.date.isAfter(today))
        .fold(0.0, (sum, item) => sum + item.total);
  }

  double _calculateWeekSales(List<Sale> sales) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return sales
        .where((s) => s.date.isAfter(startOfWeek))
        .fold(0.0, (sum, item) => sum + item.total);
  }

  // Métodos de paginación
  void _updatePagination(List<Sale> sales) {
    _filteredSales = sales;
    _totalPages = (sales.length / _itemsPerPage).ceil();
    if (_currentPage >= _totalPages && _totalPages > 0) {
      _currentPage = _totalPages - 1;
    }
    if (_currentPage < 0) _currentPage = 0;
  }

  List<Sale> _getCurrentPageSales() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredSales.length);
    return _filteredSales.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Información de página centrada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              'Página ${_currentPage + 1} de $_totalPages • ${_filteredSales.length} ventas totales',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Controles de navegación centrados
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón primera página
              _buildPaginationButton(
                icon: Icons.first_page,
                onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
                tooltip: 'Primera página',
              ),
              
              const SizedBox(width: 8),
              
              // Botón página anterior
              _buildPaginationButton(
                icon: Icons.chevron_left,
                onPressed: _currentPage > 0 ? _previousPage : null,
                tooltip: 'Página anterior',
              ),
              
              const SizedBox(width: 16),
              
              // Números de página
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildPageNumbers(),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Botón página siguiente
              _buildPaginationButton(
                icon: Icons.chevron_right,
                onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
                tooltip: 'Página siguiente',
              ),
              
              const SizedBox(width: 8),
              
              // Botón última página
              _buildPaginationButton(
                icon: Icons.last_page,
                onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_totalPages - 1) : null,
                tooltip: 'Última página',
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final widgets = <Widget>[];
    final maxVisiblePages = 5;
    
    if (_totalPages <= maxVisiblePages) {
      // Mostrar todas las páginas si hay 5 o menos
      for (int i = 0; i < _totalPages; i++) {
        widgets.add(_buildPageButton(i));
      }
    } else {
      // Mostrar páginas con elipsis
      final startPage = (_currentPage - 2).clamp(0, _totalPages - maxVisiblePages);
      final endPage = (startPage + maxVisiblePages - 1).clamp(startPage, _totalPages - 1);
      
      for (int i = startPage; i <= endPage; i++) {
        if (i == startPage && startPage > 0) {
          widgets.add(_buildEllipsis());
        }
        widgets.add(_buildPageButton(i));
        if (i == endPage && endPage < _totalPages - 1) {
          widgets.add(_buildEllipsis());
        }
      }
    }
    
    return widgets;
  }

  Widget _buildPageButton(int page) {
    final isCurrentPage = page == _currentPage;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => _goToPage(page),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isCurrentPage ? Colors.blue.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isCurrentPage ? Colors.blue.shade600 : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Text(
            '${page + 1}',
            style: TextStyle(
              color: isCurrentPage ? Colors.white : Colors.grey[700],
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '...',
        style: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ventas',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Administra tus últimas ventas',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null ? Colors.blue.shade50 : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: onPressed != null ? Colors.blue.shade200 : Colors.grey[300]!,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null ? Colors.blue.shade700 : Colors.grey[400],
          size: 20,
        ),
        tooltip: tooltip,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }

  List<Sale> _filterSales(List<Sale> sales) {
    final filtered = sales.where((sale) {
      // Filtro por tipo de búsqueda
      switch (_searchType) {
        case 'name':
          return _searchQuery.isEmpty || 
                 sale.items.any((item) => item.productName.toLowerCase().contains(_searchQuery.toLowerCase())) ||
                 (sale.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        
        case 'date':
          if (_searchQuery.isNotEmpty) {
            // Buscar por texto de fecha
            final dateText = sale.formattedDate.toLowerCase();
            return dateText.contains(_searchQuery.toLowerCase());
          }
          // Filtro por rango de fechas
          final matchesDateRange = (_startDate == null || sale.date.isAfter(_startDate!.subtract(const Duration(days: 1)))) &&
                                  (_endDate == null || sale.date.isBefore(_endDate!.add(const Duration(days: 1))));
          return matchesDateRange;
        
        case 'amount':
          if (_searchQuery.isNotEmpty) {
            // Buscar por texto de monto
            final amountText = sale.formattedTotal.toLowerCase();
            return amountText.contains(_searchQuery.toLowerCase());
          }
          // Filtro por rango de montos
          final matchesAmountRange = (_minAmount == null || sale.total >= _minAmount!) &&
                                   (_maxAmount == null || sale.total <= _maxAmount!);
          return matchesAmountRange;
        
        default:
          // Búsqueda general
          return _searchQuery.isEmpty ||
                 sale.items.any((item) => item.productName.toLowerCase().contains(_searchQuery.toLowerCase())) ||
                 sale.formattedDate.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 sale.formattedTotal.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 (sale.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }
    }).toList();
    
    // Actualizar paginación cuando cambien los filtros
    _updatePagination(filtered);
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final saleVM = context.watch<SaleViewModel>();
    final sales = List<Sale>.from(saleVM.sales)
      ..sort((a, b) => b.date.compareTo(a.date)); // Ordenar por fecha más reciente
    final filteredSales = _filterSales(sales);
    final currentPageSales = _getCurrentPageSales();

    return Scaffold(
      body: _buildResponsiveBody(currentPageSales),
    );
  }

  /// Cuerpo principal responsive
  Widget _buildResponsiveBody(List<Sale> sales) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la página
          _buildPageTitle(),
          
          const SizedBox(height: 24),
          
          // Estadísticas de ventas
          _buildSalesStats(),
          
          // Buscador y filtros
          _buildSearchAndFilters(),
          
          Expanded(
            child: Responsive.isMobile(context)
              ? _buildMobileList(sales)
              : _buildDesktopTable(sales),
          ),
          
          // Controles de paginación
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<Sale> sales) {
    if (sales.isEmpty) return const Center(child: Text('No hay ventas.'));
    return ListView.builder(
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: const Icon(Icons.receipt),
            title: Text('Cliente: ${sale.customerName.isNotEmpty ? sale.customerName : 'Sin especificar'}'),
            subtitle: Text('${sale.formattedTotal} - ${sale.formattedDate}'),
            children: [
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
                        child: Text(' [${formatPrice(item.unitPrice)}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(' [${formatPrice(item.subtotal)}'),
                      ),
                    ],
                  )),
                ],
              ),
              if (sale.notes != null && sale.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Notas: ${sale.notes!}'),
                ),
              ButtonBar(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    tooltip: 'Ver detalles',
                    onPressed: () => _showSaleDetails(sale),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Editar',
                    onPressed: () => _handleMenuAction('edit', sale),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Eliminar',
                    onPressed: () => _handleMenuAction('delete', sale),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(List<Sale> sales) {
    if (sales.isEmpty) return const Center(child: Text('No hay ventas.'));
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: 32,
              headingRowHeight: 48,
              dataRowHeight: 56,
              columns: const [
                DataColumn(label: Text('Cliente')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Fecha')),
                DataColumn(label: Text('Productos vendidos')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: sales.map((sale) {
                return DataRow(cells: [
                  DataCell(Text(sale.customerName.isNotEmpty ? sale.customerName : 'Sin especificar')),
                  DataCell(Text(sale.formattedTotal)),
                  DataCell(Text(sale.formattedDate)),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...sale.items.map((item) => Text(
                          '${item.productName} x${formatNumber(item.quantity)} - [${formatPrice(item.subtotal)}',
                          style: const TextStyle(fontSize: 13),
                        )),
                      ],
                    ),
                  ),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        tooltip: 'Ver detalles',
                        onPressed: () => _showSaleDetails(sale),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Editar',
                        onPressed: () => _handleMenuAction('edit', sale),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Eliminar',
                        onPressed: () => _handleMenuAction('delete', sale),
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleMenuAction(String action, Sale sale) async {
    switch (action) {
      case 'view':
        _showSaleDetails(sale);
        break;
      case 'edit':
        _editSale(sale);
        break;
      case 'delete':
        await _deleteSale(sale);
        break;
    }
  }
} 