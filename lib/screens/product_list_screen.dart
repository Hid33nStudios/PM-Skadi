import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../viewmodels/product_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/responsive_form.dart';
import '../theme/responsive.dart';
import '../utils/error_handler.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../utils/error_cases.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  AppError? _error;

  // Lazy loading
  final int _pageSize = 20;
  int _currentMax = 20;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar datos cuando las dependencias cambien (por ejemplo, cuando se vuelve a mostrar la pantalla)
    final productViewModel = context.read<ProductViewModel>();
    if (productViewModel.products.isEmpty && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    } else {
      // Inicializar _filteredProducts con los productos actuales sin setState
      _filteredProducts = productViewModel.products;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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

  void _onScroll() {
    // Eliminado: la paginación ahora la maneja el ViewModel
  }

  void _filterProducts(String query) {
    final products = context.read<ProductViewModel>().products;
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List<Product>.from(products)..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      } else {
        _filteredProducts = products.where((product) {
          final nameMatch = product.name.toLowerCase().contains(query.toLowerCase());
          final descriptionMatch = product.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
          return nameMatch || descriptionMatch;
        }).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }
      _currentMax = _pageSize;
    });
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
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Producto eliminado correctamente'),
                    backgroundColor: Colors.green,
                  ),
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
    return Scaffold(
      body: _buildResponsiveBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// FloatingActionButton solo en móvil
  Widget? _buildFloatingActionButton() {
    if (!Responsive.isMobile(context)) return null;
    
    return FloatingActionButton(
      onPressed: () async {
        context.goToAddProduct();
        // Recargar datos cuando regrese
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadData();
        });
      },
      backgroundColor: Colors.green,
      child: const Icon(Icons.add),
    );
  }

  /// Cuerpo principal responsive
  Widget _buildResponsiveBody() {
    return Column(
      children: [
        // Sección de búsqueda responsive
        _buildSearchSection(),
        
        // Lista de productos responsive
        Expanded(
          child: _buildProductList(),
        ),
      ],
    );
  }

  /// Sección de búsqueda responsive
  Widget _buildSearchSection() {
    return Container(
      padding: Responsive.getResponsivePadding(context),
      child: ResponsiveFormField(
        label: 'Buscar Productos',
        helperText: 'Busca por nombre o descripción',
        prefix: Icon(Icons.search, color: Colors.blue),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar productos...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: Responsive.getResponsiveSpacing(context),
            ),
          ),
          onChanged: _filterProducts,
        ),
      ),
    );
  }

  /// Lista de productos responsive
  Widget _buildProductList() {
    final viewModel = context.watch<ProductViewModel>();
    final products = _filteredProducts;
    if (viewModel.isLoading && products.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    if (viewModel.error != null) {
      return Center(child: Text(viewModel.error!));
    }
    if (products.isEmpty) {
      return Center(child: Text('No hay productos registrados.'));
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product, isGrid: false);
            },
          ),
        ),
        if (viewModel.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton(
              onPressed: viewModel.isLoadingMore ? null : () => viewModel.loadMoreProducts(),
              child: viewModel.isLoadingMore
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Cargar más'),
            ),
          ),
      ],
    );
  }

  /// Card individual para producto
  Widget _buildProductCard(Product product, {required bool isGrid}) {
    final categoryViewModel = context.read<CategoryViewModel>();
    Category category;
    
    try {
      if (product.categoryId.isNotEmpty) {
        category = categoryViewModel.categories.firstWhere(
          (cat) => cat.id == product.categoryId,
          orElse: () => Category(
            id: '',
            name: 'Sin categoría',
            description: 'Categoría no encontrada',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        category = Category(
          id: '',
          name: 'Sin categoría',
          description: 'Categoría no encontrada',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      category = Category(
        id: '',
        name: 'Sin categoría',
        description: 'Categoría no encontrada',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleMenuAction('view', product),
        child: isGrid ? _buildGridCardContent(product, category) : _buildListCardContent(product, category),
      ),
    );
  }

  /// Contenido para card en grid (desktop)
  Widget _buildGridCardContent(Product product, category) {
    return Padding(
      padding: Responsive.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título y menú
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.getResponsiveFontSize(context, 16),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildProductMenu(product),
            ],
          ),
          
          SizedBox(height: Responsive.getResponsiveSpacing(context) / 2),
          
          // Descripción
          Expanded(
            child: Text(
              product.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: Responsive.getResponsiveFontSize(context, 14),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          SizedBox(height: Responsive.getResponsiveSpacing(context)),
          
          // Precio y stock
          Row(
            children: [
              _buildPriceChip(product.price),
              const Spacer(),
              _buildStockChip(product.stock, product.minStock),
            ],
          ),
          
          SizedBox(height: Responsive.getResponsiveSpacing(context) / 2),
          
          // Categoría
          _buildCategoryChip(category.name),
        ],
      ),
    );
  }

  /// Contenido para card en lista (móvil/tablet)
  Widget _buildListCardContent(Product product, category) {
    return Padding(
      padding: Responsive.getResponsivePadding(context),
      child: Row(
        children: [
          // Información principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.getResponsiveFontSize(context, 16),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: Responsive.getResponsiveSpacing(context) / 2),
                
                // Descripción
                Text(
                  product.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: Responsive.getResponsiveFontSize(context, 14),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: Responsive.getResponsiveSpacing(context)),
                
                // Chips de información
                Wrap(
                  spacing: Responsive.getResponsiveSpacing(context) / 2,
                  children: [
                    _buildPriceChip(product.price),
                    _buildStockChip(product.stock, product.minStock),
                    _buildCategoryChip(category.name),
                  ],
                ),
              ],
            ),
          ),
          
          // Menú de acciones
          _buildProductMenu(product),
        ],
      ),
    );
  }

  /// Menú de acciones del producto
  Widget _buildProductMenu(Product product) {
    return PopupMenuButton<String>(
      onSelected: (action) => _handleMenuAction(action, product),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: ListTile(
            leading: Icon(Icons.visibility),
            title: Text('Ver Detalles'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Editar'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Eliminar', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: Icon(
        Icons.more_vert,
        color: Colors.grey[600],
      ),
    );
  }

  /// Chip de precio
  Widget _buildPriceChip(double price) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.getResponsiveSpacing(context) / 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '\$${price.toStringAsFixed(2)}',
        style: TextStyle(
          color: Colors.green[700],
          fontWeight: FontWeight.bold,
          fontSize: Responsive.getResponsiveFontSize(context, 12),
        ),
      ),
    );
  }

  /// Chip de stock
  Widget _buildStockChip(int stock, int minStock) {
    Color color;
    if (stock <= 0) {
      color = Colors.red;
    } else if (stock <= minStock) {
      color = Colors.orange;
    } else {
      color = Colors.blue;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.getResponsiveSpacing(context) / 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Stock: $stock',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: Responsive.getResponsiveFontSize(context, 12),
        ),
      ),
    );
  }

  /// Chip de categoría
  Widget _buildCategoryChip(String categoryName) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.getResponsiveSpacing(context) / 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        categoryName,
        style: TextStyle(
          color: Colors.purple[700],
          fontWeight: FontWeight.bold,
          fontSize: Responsive.getResponsiveFontSize(context, 12),
        ),
      ),
    );
  }
}
                