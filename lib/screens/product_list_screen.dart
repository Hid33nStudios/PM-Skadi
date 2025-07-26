import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart' show AutomaticKeepAliveClientMixin;
import '../models/product.dart';
import '../models/category.dart';
import '../viewmodels/product_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/responsive_form.dart';
import '../theme/responsive.dart';
import '../utils/error_handler.dart';
import '../router/app_router.dart';
import '../utils/error_cases.dart';
import '../utils/notification_service.dart';
import 'package:intl/intl.dart';
import '../utils/validators.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> 
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  AppError? _error;

  // Variables de paginación
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  int _totalPages = 0;

  String? _selectedCategoryId;
  String _searchQuery = '';

  // Selección múltiple
  final Set<String> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _checkForCategoryParameter();
    });
  }

  void _checkForCategoryParameter() {
    try {
      final uri = Uri.parse(GoRouterState.of(context).uri.toString());
      final categoryParam = uri.queryParameters['category'];
      
      if (categoryParam != null && categoryParam.isNotEmpty) {
        print('🔄 ProductListScreen: Detectado parámetro category=$categoryParam');
        setState(() {
          _selectedCategoryId = categoryParam;
        });
        // Aplicar el filtro después de que los datos se carguen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _filterProducts();
        });
      }
    } catch (e) {
      print('⚠️ Error al verificar parámetro category: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar datos cuando las dependencias cambien
    final productViewModel = context.read<ProductViewModel>();
    if (productViewModel.products.isEmpty && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    } else {
      // Inicializar _filteredProducts con los productos actuales
      _filteredProducts = productViewModel.products;
      // No reiniciar paginación en didChangeDependencies
      _filterProducts(resetPagination: false);
    }
  }

  @override
  bool get wantKeepAlive => true; // Mantener el widget vivo entre navegaciones

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<ProductViewModel>().loadInitialProducts();
      await context.read<CategoryViewModel>().loadCategories();
      
      if (mounted) {
        final products = context.read<ProductViewModel>().products;
        products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        setState(() {
          _filteredProducts = List<Product>.from(products);
          _isLoading = false;
        });
        // Reiniciar paginación cuando se cargan datos iniciales
        _filterProducts(resetPagination: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppError.fromException(e);
          _isLoading = false;
        });
        final errorType = context.read<ProductViewModel>().errorType ?? AppErrorType.desconocido;
        showAppError(context, errorType);
      }
    }
  }

  void _filterProducts({bool resetPagination = true}) {
    final products = context.read<ProductViewModel>().products;
    List<Product> filtered = products;
    
    // OPTIMIZACIÓN: Filtrar por categoría solo si es necesario
    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
      filtered = filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
    }
    
    // OPTIMIZACIÓN: Filtrar por búsqueda con debounce
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(query) ||
               (product.description?.toLowerCase().contains(query) ?? false) ||
               (product.barcode?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // OPTIMIZACIÓN: Ordenar solo si la lista ha cambiado
    if (filtered != _filteredProducts) {
      filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      
      setState(() {
        _filteredProducts = filtered;
        // Solo reiniciar paginación si se solicitó explícitamente o si cambió la búsqueda/filtro
        if (resetPagination) {
          _currentPage = 0;
        }
      });
      
      _updatePagination();
    }
  }

  // Métodos de paginación
  void _updatePagination() {
    _totalPages = (_filteredProducts.length / _itemsPerPage).ceil();
    if (_currentPage >= _totalPages && _totalPages > 0) {
      _currentPage = _totalPages - 1;
    }
    if (_currentPage < 0) _currentPage = 0;
  }

  List<Product> _getCurrentPageProducts() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredProducts.length);
    return _filteredProducts.sublist(startIndex, endIndex);
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

  Future<void> _handleMenuAction(String action, Product product) async {
    switch (action) {
      case 'edit':
        context.goToEditProduct(product.id);
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar Producto'),
            content: Text('¿Estás seguro de que deseas eliminar "${product.name}"?'),
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
            final success = await context.read<ProductViewModel>().deleteProduct(product.id);
            if (success) {
              await _loadData();
              await context.read<DashboardViewModel>().loadDashboardData();
              if (mounted) {
                NotificationService.showSuccess(
                  context,
                  'Producto eliminado correctamente',
                );
              }
            } else {
              if (mounted) {
                final errorType = context.read<ProductViewModel>().errorType ?? AppErrorType.desconocido;
                showAppError(context, errorType);
              }
            }
          } catch (e) {
            if (mounted) {
              final errorType = context.read<ProductViewModel>().errorType ?? AppErrorType.desconocido;
              showAppError(context, errorType);
            }
          }
        }
        break;
      case 'view':
        context.goToProductDetail(product.id);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido para AutomaticKeepAliveClientMixin
    return Scaffold(
      body: _buildResponsiveBody(),
    );
  }

  /// Cuerpo principal responsive
  Widget _buildResponsiveBody() {
    return Consumer<ProductViewModel>(
      builder: (context, productVM, child) {
        // OPTIMIZACIÓN: Usar productos directamente sin copiar y ordenar
        final products = productVM.products;
        
        // OPTIMIZACIÓN: Solo actualizar si la lista ha cambiado significativamente
        if (!_areListsEqual(_filteredProducts, products)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _filteredProducts = List<Product>.from(products);
            });
            // No reiniciar paginación cuando solo se actualizan los datos
            _filterProducts(resetPagination: false);
          });
        }
        
        final currentPageProducts = _getCurrentPageProducts();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la página
              Padding(
                padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                child: _buildPageTitle(),
              ),
              const SizedBox(height: 16),
              // Estadísticas de productos en 4 tarjetas (2x2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildProductStatsGrid(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      children: [
                        // Botón para añadir producto
                        Tooltip(
                          message: 'Agregar nuevo producto al inventario',
                          child: IconButton(
                            onPressed: () async {
                              print('🔄 ProductListScreen: Botón agregar producto presionado');
                              final result = await context.push('/products/add');
                              if (result == true) {
                                print('✅ ProductListScreen: Producto agregado, iniciando refresh');
                                // Recargar datos inmediatamente
                                await _refreshDataAfterAdd();
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green.shade50,
                              foregroundColor: Colors.green.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Barra de búsqueda
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Buscar productos',
                              prefixIcon: Icon(Icons.search, color: Colors.blue[700]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                              // Reiniciar paginación cuando cambia la búsqueda
                              _filterProducts(resetPagination: true);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Filtro de categoría
                        Expanded(
                          child: _buildCategoryFilter(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  height: 600, // Altura máxima para la lista/tablas
                  child: Responsive.isMobile(context)
                    ? _buildMobileList(currentPageProducts)
                    : _buildDesktopTable(currentPageProducts),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildLoadMoreButton(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildPaginationControls(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Comparar si dos listas de productos son iguales
  bool _areListsEqual(List<Product> list1, List<Product> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  /// Método mejorado para refrescar datos después de agregar un producto
  Future<void> _refreshDataAfterAdd() async {
    try {
      print('🔄 ProductListScreen: Iniciando refresh después de agregar producto');
      
      // OPTIMIZACIÓN: Usar recarga forzada para asegurar datos frescos
      await context.read<ProductViewModel>().forceReloadProducts();
      
      // Recargar categorías si es necesario
      await context.read<CategoryViewModel>().loadCategories();
      
      // Recargar dashboard
      await context.read<DashboardViewModel>().loadDashboardData();
      
      print('✅ ProductListScreen: Refresh completado');
      
      if (mounted) {
        NotificationService.showSuccess(
          context,
          'Producto agregado correctamente',
        );
        print('✅ ProductListScreen: Notificación mostrada');
      }
    } catch (e) {
      print('❌ ProductListScreen: Error en _refreshDataAfterAdd: $e');
      if (mounted) {
        final errorType = context.read<ProductViewModel>().errorType ?? AppErrorType.desconocido;
        showAppError(context, errorType);
      }
    }
  }

  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productos',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gestiona tu inventario de productos',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildProductStatsGrid() {
    return Consumer<ProductViewModel>(
      builder: (context, productVM, _) {
        final products = productVM.products;
        final totalProducts = products.length;
        
        // Calcular estadísticas
        final productsWithStock = products.where((p) => p.stock > 0).length;
        final productsWithoutStock = products.where((p) => p.stock == 0).length;
        final averagePrice = products.isNotEmpty 
            ? products.map((p) => p.price).reduce((a, b) => a + b) / products.length 
            : 0.0;
        
        return Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.inventory,
                value: '$totalProducts',
                label: 'Total Productos',
                color: Colors.blue,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey.shade300),
            Expanded(
              child: _buildStatItem(
                icon: Icons.check_circle,
                value: '$productsWithStock',
                label: 'Con Stock',
                color: Colors.green,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey.shade300),
            Expanded(
              child: _buildStatItem(
                icon: Icons.warning,
                value: '$productsWithoutStock',
                label: 'Sin Stock',
                color: Colors.orange,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey.shade300),
            Expanded(
              child: _buildStatItem(
                icon: Icons.attach_money,
                value: '\$${averagePrice.toStringAsFixed(2)}',
                label: 'Precio Promedio',
                color: Colors.purple,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    final productVM = context.watch<ProductViewModel>();
    if (!productVM.hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Tooltip(
        message: 'Cargar más productos',
        child: ElevatedButton.icon(
          onPressed: productVM.isLoadingMore ? null : () => productVM.loadMoreProducts(),
          icon: productVM.isLoadingMore 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.expand_more),
          label: Text(productVM.isLoadingMore ? 'Cargando...' : 'Cargar más'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade50,
            foregroundColor: Colors.blue.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categoryVM = context.watch<CategoryViewModel>();
    final categories = List<Category>.from(categoryVM.categories)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    
    // Encontrar la categoría seleccionada para mostrar su nombre
    final selectedCategory = _selectedCategoryId != null 
        ? categories.firstWhere(
            (cat) => cat.id == _selectedCategoryId,
            orElse: () => Category(id: '', name: 'Categoría no encontrada', description: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
          )
        : null;
    
    return DropdownButton<String>(
      value: _selectedCategoryId,
      hint: Text(selectedCategory != null ? 'Filtrado: ${selectedCategory.name}' : 'Filtrar por categoría'),
      items: [
        const DropdownMenuItem(value: null, child: Text('Todas las categorías')),
        ...categories.map((cat) => DropdownMenuItem(
          value: cat.id,
          child: Text(cat.name),
        ))
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
        // Reiniciar paginación cuando cambia el filtro de categoría
        _filterProducts(resetPagination: true);
      },
      isExpanded: true,
    );
  }

  Widget _buildMobileList(List<Product> products) {
    if (products.isEmpty) return const Center(child: Text('No hay productos.'));
    return Container(
      width: double.infinity,
      child: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final categoryVM = context.read<CategoryViewModel>();
          Category category;
          
          try {
            category = categoryVM.categories.firstWhere(
              (cat) => cat.id == product.categoryId,
              orElse: () => Category(
                id: '',
                name: 'Sin categoría',
                description: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
          } catch (e) {
            category = Category(
              id: '',
              name: 'Sin categoría',
              description: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.description.isNotEmpty)
                    Text(
                      product.description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        category.name,
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.inventory, size: 16, color: Colors.orange[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${product.stock}',
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.attach_money, size: 16, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatPrice(product.price),
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: Icon(
                  Icons.inventory,
                  color: Colors.green.shade700,
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (action) => _handleMenuAction(action, product),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('Ver')),
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopTable(List<Product> products) {
    if (products.isEmpty) return const Center(child: Text('No hay productos.'));
    final categoryVM = context.read<CategoryViewModel>();
    final categories = List<Category>.from(categoryVM.categories)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final allSelected = _selectedProductIds.length == products.length && products.isNotEmpty;
    return Stack(
      children: [
        Positioned.fill(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              columnSpacing: 32,
              headingRowHeight: 48,
              dataRowHeight: 56,
              columns: [
                DataColumn(
                  label: Checkbox(
                    value: allSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedProductIds.addAll(products.map((p) => p.id));
                        } else {
                          _selectedProductIds.clear();
                        }
                      });
                    },
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const DataColumn(label: Text('Nombre')),
                const DataColumn(label: Text('Categoría')),
                const DataColumn(label: Text('Stock')),
                const DataColumn(label: Text('Precio')),
                const DataColumn(label: Text('Acciones')),
              ],
              rows: products.map((product) {
                final category = categories.firstWhere(
                  (cat) => cat.id == product.categoryId,
                  orElse: () => Category(
                    id: '',
                    name: 'Sin categoría',
                    description: '',
                    createdAt: DateTime(2000),
                    updatedAt: DateTime(2000),
                  ),
                );
                final selected = _selectedProductIds.contains(product.id);
                return DataRow(
                  cells: [
                    DataCell(
                      Checkbox(
                        value: selected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedProductIds.add(product.id);
                            } else {
                              _selectedProductIds.remove(product.id);
                            }
                          });
                        },
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    DataCell(Text(product.name)),
                    DataCell(Text(category.name)),
                    DataCell(Text(product.stock.toString())),
                    DataCell(Text(_formatPrice(product.price))),
                    DataCell(Row(
                      children: [
                        Tooltip(
                          message: 'Ver detalles del producto',
                          child: IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => _handleMenuAction('view', product),
                          ),
                        ),
                        Tooltip(
                          message: 'Editar producto',
                          child: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _handleMenuAction('edit', product),
                          ),
                        ),
                        Tooltip(
                          message: 'Eliminar producto',
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _handleMenuAction('delete', product),
                          ),
                        ),
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        if (_selectedProductIds.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildBulkActionsBar(),
          ),
      ],
    );
  }

  Widget _buildBulkActionsBar() {
    return Material(
      elevation: 4,
      color: Colors.red.shade700,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(8),
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.delete, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              '${_selectedProductIds.length} seleccionados',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red.shade700,
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Eliminar seleccionados'),
              onPressed: _selectedProductIds.isEmpty ? null : _confirmBulkDelete,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBulkDelete() async {
    final count = _selectedProductIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar productos'),
        content: Text('¿Seguro que deseas eliminar $count productos seleccionados? Esta acción no se puede deshacer.'),
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
      await _deleteSelectedProducts();
    }
  }

  Future<void> _deleteSelectedProducts() async {
    final ids = List<String>.from(_selectedProductIds);
    for (final id in ids) {
      try {
        await context.read<ProductViewModel>().deleteProduct(id);
      } catch (e) {
        // Manejar error individual si es necesario
      }
    }
    setState(() {
      _selectedProductIds.clear();
    });
    await _loadData();
    await context.read<DashboardViewModel>().loadDashboardData();
    if (mounted) {
      NotificationService.showSuccess(
        context,
        'Productos eliminados correctamente',
      );
    }
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botón anterior
            _buildPaginationButton(
              icon: Icons.chevron_left,
              onPressed: _currentPage > 0 ? _previousPage : null,
              tooltip: 'Página anterior',
            ),
            const SizedBox(width: 16),
            
            // Números de página
            ..._buildPageNumbers(),
            
            const SizedBox(width: 16),
            
            // Botón siguiente
            _buildPaginationButton(
              icon: Icons.chevron_right,
              onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
              tooltip: 'Página siguiente',
            ),
          ],
        ),
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

  String _formatPrice(num price) {
    return formatPrice(price);
  }


}
                