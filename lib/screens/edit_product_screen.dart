import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../viewmodels/product_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';
import '../widgets/responsive_form.dart';
import '../widgets/custom_snackbar.dart';
import '../theme/responsive.dart';
import '../router/app_router.dart';
import '../utils/error_handler.dart';
import '../utils/error_cases.dart';
import '../viewmodels/dashboard_viewmodel.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;

  const EditProductScreen({
    super.key,
    required this.productId,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _skuController = TextEditingController();

  Product? _product;
  String? _selectedCategoryId;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
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
      
      if (mounted && product != null) {
        setState(() {
          _product = product;
          _selectedCategoryId = product.categoryId;
          _populateFields(product);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Producto no encontrado';
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
        final productViewModel = context.read<ProductViewModel>();
        final errorType = productViewModel.errorType ?? AppErrorType.desconocido;
        showAppError(context, errorType);
      }
    }
  }

  void _populateFields(Product product) {
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();
    _minStockController.text = product.minStock.toString();
    _maxStockController.text = product.maxStock.toString();
    _barcodeController.text = product.barcode ?? '';
    _skuController.text = product.sku ?? '';
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_product == null) return;

    setState(() => _isSaving = true);

    try {
      final productViewModel = context.read<ProductViewModel>();
      
      final updatedProduct = _product!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        minStock: int.parse(_minStockController.text),
        maxStock: int.parse(_maxStockController.text),
        categoryId: _selectedCategoryId ?? '',
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await productViewModel.updateProduct(updatedProduct);

      // Recargar dashboard inmediatamente
      context.read<DashboardViewModel>().loadDashboardData();

      if (mounted) {
        CustomSnackBar.showSuccess(
          context: context,
          message: 'Producto actualizado exitosamente',
        );
        context.goToProductDetail(_product!.id);
      }
    } catch (e) {
      if (mounted) {
        final productViewModel = context.read<ProductViewModel>();
        final errorType = productViewModel.errorType ?? AppErrorType.desconocido;
        showAppError(context, errorType);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_product?.name ?? 'Editar Producto'),
        actions: [
          if (_product != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveProduct,
              tooltip: 'Guardar Cambios',
            ),
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

    return _buildEditForm(theme);
  }

  Widget _buildEditForm(ThemeData theme) {
    return Responsive.isMobile(context)
        ? _buildMobileForm(theme)
        : Responsive.isTablet(context)
            ? _buildTabletForm(theme)
            : _buildDesktopForm(theme);
  }

  Widget _buildMobileForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBasicInfoSection(theme),
            const SizedBox(height: 24),
            _buildPricingSection(theme),
            const SizedBox(height: 24),
            _buildStockSection(theme),
            const SizedBox(height: 24),
            _buildAdditionalInfoSection(theme),
            const SizedBox(height: 32),
            _buildSaveButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBasicInfoSection(theme),
                  const SizedBox(height: 24),
                  _buildPricingSection(theme),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStockSection(theme),
                  const SizedBox(height: 24),
                  _buildAdditionalInfoSection(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBasicInfoSection(theme),
                  const SizedBox(height: 32),
                  _buildPricingSection(theme),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStockSection(theme),
                  const SizedBox(height: 32),
                  _buildAdditionalInfoSection(theme),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPreviewSection(theme),
                  const SizedBox(height: 32),
                  _buildSaveButton(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Básica',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ResponsiveFormField(
              label: 'Nombre del Producto',
              isRequired: true,
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Aceite de Motor 10W-30',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            ResponsiveFormField(
              label: 'Descripción',
              child: TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Descripción detallada del producto',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryDropdown(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(ThemeData theme) {
    return Consumer<CategoryViewModel>(
      builder: (context, categoryVM, child) {
        final categories = categoryVM.categories;
        
        return ResponsiveFormField(
          label: 'Categoría',
          child: DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            hint: const Text('Seleccionar categoría'),
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category.id,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildPricingSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Precio',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ResponsiveFormField(
              label: 'Precio de Venta',
              isRequired: true,
              prefix: const Icon(Icons.attach_money),
              child: TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El precio es requerido';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return 'Ingresa un precio válido';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de Stock',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ResponsiveFormField(
              label: 'Stock Actual',
              isRequired: true,
              prefix: const Icon(Icons.inventory),
              child: TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  hintText: '0',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El stock es requerido';
                  }
                  final stock = int.tryParse(value);
                  if (stock == null || stock < 0) {
                    return 'Ingresa un stock válido';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ResponsiveFormField(
                    label: 'Stock Mínimo',
                    isRequired: true,
                    child: TextFormField(
                      controller: _minStockController,
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Requerido';
                        }
                        final minStock = int.tryParse(value);
                        if (minStock == null || minStock < 0) {
                          return 'Inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ResponsiveFormField(
                    label: 'Stock Máximo',
                    isRequired: true,
                    child: TextFormField(
                      controller: _maxStockController,
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Requerido';
                        }
                        final maxStock = int.tryParse(value);
                        if (maxStock == null || maxStock < 0) {
                          return 'Inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Adicional',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ResponsiveFormField(
              label: 'Código de Barras',
              child: TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  hintText: 'Código de barras del producto',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ResponsiveFormField(
              label: 'SKU',
              child: TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(
                  hintText: 'Código SKU del producto',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vista Previa',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameController.text.isEmpty ? 'Nombre del Producto' : _nameController.text,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _descriptionController.text.isEmpty 
                        ? 'Descripción del producto' 
                        : _descriptionController.text,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Precio: \$${_priceController.text.isEmpty ? '0.00' : _priceController.text}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stock: ${_stockController.text.isEmpty ? '0' : _stockController.text}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return ResponsiveButtonRow(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveProduct,
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.goToProductDetail(_product!.id),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
} 