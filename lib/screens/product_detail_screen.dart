import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/movement.dart';
import '../models/category.dart';
import '../viewmodels/product_viewmodel.dart';
import '../viewmodels/movement_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';
import '../widgets/custom_snackbar.dart';
import '../utils/error_handler.dart';
import 'edit_product_screen.dart';
import '../widgets/responsive_form.dart';
import '../theme/responsive.dart';
import '../router/app_router.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  String? _categoryName;
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  MovementType _selectedType = MovementType.entry;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _loadCategory();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      setState(() {
        _isLoading = true;
        _isError = false;
      });

      final productViewModel = context.read<ProductViewModel>();
      final product = await productViewModel.getProductById(widget.productId);
      
      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCategory() async {
    try {
      final categoryViewModel = context.read<CategoryViewModel>();
      await categoryViewModel.loadCategories();
      
      // Buscar la categoría del producto
      if (_product?.categoryId != null && _product!.categoryId.isNotEmpty) {
        try {
          final category = categoryViewModel.categories.firstWhere(
            (c) => c.id == _product!.categoryId,
            orElse: () => Category(
              id: '',
              name: 'Sin categoría',
              description: 'Categoría no encontrada',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          
          if (mounted) {
            setState(() {
              _categoryName = category.name;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _categoryName = 'Sin categoría';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _categoryName = 'Sin categoría';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoryName = 'Sin categoría';
        });
      }
    }
  }

  Future<void> _addMovement() async {
    if (_quantityController.text.isEmpty) {
      context.showError('Por favor ingresa una cantidad');
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      context.showError('La cantidad debe ser un número positivo');
      return;
    }

    if (_selectedType == MovementType.exit && quantity > _product!.stock) {
      context.showError('No hay suficiente stock disponible');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final movement = Movement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: _product!.id,
        productName: _product!.name,
        quantity: quantity,
        type: _selectedType,
        date: DateTime.now(),
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      await context.read<MovementViewModel>().addMovement(movement);
      await context.read<ProductViewModel>().loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movimiento registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _quantityController.clear();
        _noteController.clear();
      }
    } catch (e) {
      if (mounted) {
        context.showError(e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct() async {
    if (_product == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el producto "${_product!.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final productViewModel = context.read<ProductViewModel>();
        await productViewModel.deleteProduct(_product!.id);
        
        if (mounted) {
          CustomSnackBar.showSuccess(
            context: context,
            message: 'Producto eliminado exitosamente',
          );
          context.goToProducts();
        }
      } catch (e) {
        if (mounted) {
          context.showError(e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_product?.name ?? 'Detalles del Producto'),
        actions: [
          if (_product != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.goToEditProduct(_product!.id),
              tooltip: 'Editar Producto',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteProduct,
              tooltip: 'Eliminar Producto',
            ),
          ],
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el producto',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProduct,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_product == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Producto no encontrado',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'El producto que buscas no existe o ha sido eliminado.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.goToProducts(),
              child: const Text('Volver a Productos'),
            ),
          ],
        ),
      );
    }

    return _buildProductDetails(theme);
  }

  Widget _buildProductDetails(ThemeData theme) {
    final product = _product!;
    
    return Responsive.isMobile(context)
        ? _buildMobileLayout(theme, product)
        : Responsive.isTablet(context)
            ? _buildTabletLayout(theme, product)
            : _buildDesktopLayout(theme, product);
  }

  Widget _buildMobileLayout(ThemeData theme, Product product) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(theme, product),
          const SizedBox(height: 24),
          _buildProductInfo(theme, product),
          const SizedBox(height: 24),
          _buildProductActions(theme),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(ThemeData theme, Product product) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductHeader(theme, product),
                const SizedBox(height: 32),
                _buildProductInfo(theme, product),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: _buildProductActions(theme),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(ThemeData theme, Product product) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductHeader(theme, product),
                const SizedBox(height: 40),
                _buildProductInfo(theme, product),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: _buildProductActions(theme),
          ),
        ),
      ],
    );
  }

  Widget _buildProductHeader(ThemeData theme, Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStockColor(theme, product.stock),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Stock: ${product.stock}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Código: ${product.barcode ?? product.sku ?? 'N/A'}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        if (product.categoryId.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Categoría ID: ${product.categoryId}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductInfo(ThemeData theme, Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información del Producto',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(theme, [
          _buildInfoRow('Precio', '\$${product.price.toStringAsFixed(2)}'),
          _buildInfoRow('Stock Mínimo', product.minStock.toString()),
          _buildInfoRow('Stock Máximo', product.maxStock.toString()),
          if (product.description.isNotEmpty)
            _buildInfoRow('Descripción', product.description),
        ]),
        const SizedBox(height: 24),
        Text(
          'Historial de Movimientos',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildMovementsCard(theme),
      ],
    );
  }

  Widget _buildInfoCard(ThemeData theme, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Historial de Movimientos',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Funcionalidad en desarrollo',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Acciones',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveButtonRow(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.goToEditProduct(_product!.id),
                icon: const Icon(Icons.edit),
                label: const Text('Editar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.goToAddSale(),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Vender'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _deleteProduct,
          icon: const Icon(Icons.delete),
          label: const Text('Eliminar Producto'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Información Adicional',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildAdditionalInfo(theme),
      ],
    );
  }

  Widget _buildAdditionalInfo(ThemeData theme) {
    final product = _product!;
    
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('Creado', _formatDate(product.createdAt)),
            _buildInfoRow('Última Actualización', _formatDate(product.updatedAt)),
            _buildInfoRow('ID', product.id),
          ],
        ),
      ),
    );
  }

  Color _getStockColor(ThemeData theme, int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 