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

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar el error de setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<ProductViewModel>().loadProducts();
      await context.read<CategoryViewModel>().loadCategories();
      
      if (mounted) {
        setState(() {
          _filteredProducts = context.read<ProductViewModel>().products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppError.fromException(e);
          _isLoading = false;
        });
        CustomSnackBar.showError(
          context: context,
          message: AppError.fromException(e).message,
        );
      }
    }
  }

  void _filterProducts(String query) {
    final products = context.read<ProductViewModel>().products;
    
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = products;
      } else {
        _filteredProducts = products.where((product) {
          final nameMatch = product.name.toLowerCase().contains(query.toLowerCase());
          final descriptionMatch = product.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
          return nameMatch || descriptionMatch;
        }).toList();
      }
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
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
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
    return Consumer<ProductViewModel>(
      builder: (context, productVM, child) {
        if (_isLoading || productVM.isLoading) {
          return _buildLoadingState();
        }

        if (_error != null || productVM.error != null) {
          return _buildErrorState();
        }

        if (_filteredProducts.isEmpty) {
          return _buildEmptyState();
        }

        // Layout responsive para la lista
        if (Responsive.isDesktop(context)) {
          return _buildGridLayout();
        } else {
          return _buildListLayout();
        }
      },
    );
  }

  /// Estado de carga
  Widget _buildLoadingState() {
    return const Center(
      child: ProductListSkeleton(itemCount: 8),
    );
  }

  /// Estado de error
  Widget _buildErrorState() {
    final error = _error ?? context.read<ProductViewModel>().error;
    
    return Center(
      child: Padding(
        padding: Responsive.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: Responsive.isMobile(context) ? 48 : 64,
              color: Colors.red[300],
            ),
            SizedBox(height: Responsive.getResponsiveSpacing(context)),
            Text(
              error?.toString() ?? 'Error desconocido',
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(context, 16),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.getResponsiveSpacing(context)),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Estado vacío
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: Responsive.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: Responsive.isMobile(context) ? 48 : 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: Responsive.getResponsiveSpacing(context)),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay productos registrados'
                  : 'No se encontraron productos',
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(context, 16),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isEmpty) ...[
              SizedBox(height: Responsive.getResponsiveSpacing(context)),
              Text(
                'Comienza agregando tu primer producto',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(context, 14),
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.getResponsiveSpacing(context) * 2),
              ElevatedButton.icon(
                onPressed: () async {
                  context.goToAddProduct();
                  _loadData();
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar Primer Producto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.getResponsiveSpacing(context) * 2,
                    vertical: Responsive.getResponsiveSpacing(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Layout en grid para desktop
  Widget _buildGridLayout() {
    final columns = Responsive.isLargeDesktop(context) ? 3 : 2;
    
    return GridView.builder(
      padding: Responsive.getResponsivePadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: Responsive.getResponsiveSpacing(context),
        crossAxisSpacing: Responsive.getResponsiveSpacing(context),
        childAspectRatio: 1.2,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product, isGrid: true);
      },
    );
  }

  /// Layout en lista para móvil/tablet
  Widget _buildListLayout() {
    return ListView.builder(
      padding: Responsive.getResponsivePadding(context),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return Container(
          margin: EdgeInsets.only(
            bottom: Responsive.getResponsiveSpacing(context),
          ),
          child: _buildProductCard(product, isGrid: false),
        );
      },
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
                