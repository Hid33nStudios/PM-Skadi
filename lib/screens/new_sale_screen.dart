import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart' show AutomaticKeepAliveClientMixin;
import '../models/product.dart';
import '../models/sale.dart';
import '../viewmodels/product_viewmodel.dart';
import '../viewmodels/sale_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';
import '../services/auth_service.dart';
import '../widgets/responsive_form.dart';
import '../theme/responsive.dart';
import 'barcode_scanner_screen.dart';
import '../utils/error_cases.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import 'edit_product_screen.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

// Modelo interno para el carrito
class _CartItem {
  final Product product;
  final int quantity;
  _CartItem({required this.product, required this.quantity});
  _CartItem copyWith({Product? product, int? quantity}) => _CartItem(
    product: product ?? this.product,
    quantity: quantity ?? this.quantity,
  );
}

class _NewSaleScreenState extends State<NewSaleScreen> 
    with AutomaticKeepAliveClientMixin {
  final _customerNameController = TextEditingController();
  final _noteController = TextEditingController();
  String _searchQuery = '';
  // String? _selectedProductId;
  // String? _selectedProductName;
  // double? _selectedProductPrice;
  // int _quantity = 1;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();
  bool _productsLoaded = false;

  // Carrito: lista de productos seleccionados con cantidad
  List<_CartItem> _cart = [];
  Product? _selectedProduct;
  int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    // Elimino la carga de productos aquí para evitar problemas de contexto nulo
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_productsLoaded) {
      _productsLoaded = true;
      // OPTIMIZACIÓN: Cargar productos y categorías solo si es necesario
      Future.microtask(() {
        final productVM = context.read<ProductViewModel>();
        final categoryVM = context.read<CategoryViewModel>();
        
        if (productVM.products.isEmpty) {
          print('🔄 NewSaleScreen: Cargando productos iniciales...');
          productVM.loadInitialProducts();
        } else {
          print('📦 NewSaleScreen: Ya hay productos cargados (${productVM.products.length}), usando datos existentes');
        }
        
        if (categoryVM.categories.isEmpty) {
          print('🔄 NewSaleScreen: Cargando categorías iniciales...');
          categoryVM.loadInitialCategories();
        } else {
          print('📦 NewSaleScreen: Ya hay categorías cargadas (${categoryVM.categories.length}), usando datos existentes');
        }
      });
    }
  }

  @override
  bool get wantKeepAlive => true; // Mantener el widget vivo entre navegaciones

  @override
  void dispose() {
    _customerNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    await context.read<ProductViewModel>().loadInitialProducts();
  }

  @override
  void _selectProduct(Product product) {
    // Al hacer clic, agregar al carrito si no está
    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
    if (existingIndex == -1) {
      setState(() {
        _cart.add(_CartItem(product: product, quantity: 1));
      });
    }
    // No seleccionamos producto para edición, solo agregamos al carrito
  }

  void _updateSelectedQuantity(int quantity) {
    if (quantity > 0 && _selectedProduct != null && quantity <= _selectedProduct!.stock) {
      setState(() {
        _selectedQuantity = quantity;
      });
    }
  }

  void _addToCart() {
    print('[NewSaleScreen][_addToCart] Intentando agregar producto al carrito...');
    if (_selectedProduct == null) {
      print('[NewSaleScreen][_addToCart][ERROR] _selectedProduct es null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un producto antes de agregar'), backgroundColor: Colors.red),
      );
      return;
    }
    print('[NewSaleScreen][_addToCart] Producto: ${_selectedProduct!.toString()}');
    print('[NewSaleScreen][_addToCart] Cantidad seleccionada: $_selectedQuantity');
    final existingIndex = _cart.indexWhere((item) => item.product.id == _selectedProduct!.id);
    if (existingIndex != -1) {
      setState(() {
        final newQty = _cart[existingIndex].quantity + _selectedQuantity;
        _cart[existingIndex] = _cart[existingIndex].copyWith(
          quantity: newQty > _selectedProduct!.stock ? _selectedProduct!.stock : newQty,
        );
      });
      print('[NewSaleScreen][_addToCart] Producto ya estaba en el carrito, cantidad actualizada.');
    } else {
      setState(() {
        _cart.add(_CartItem(product: _selectedProduct!, quantity: _selectedQuantity));
      });
      print('[NewSaleScreen][_addToCart] Producto agregado al carrito.');
    }
    setState(() {
      _selectedProduct = null;
      _selectedQuantity = 1;
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      _cart.removeWhere((item) => item.product.id == productId);
    });
  }

  void _editCartQuantity(String productId, int newQuantity) {
    setState(() {
      final idx = _cart.indexWhere((item) => item.product.id == productId);
      if (idx != -1 && newQuantity > 0 && newQuantity <= _cart[idx].product.stock) {
        _cart[idx] = _cart[idx].copyWith(quantity: newQuantity);
      }
    });
  }

  double get _cartTotal => _cart.fold(0.0, (sum, item) => sum + item.product.price * item.quantity);

  Future<void> _saveSale() async {
    print('[TRACE] Entrando a _saveSale');
    try {
      print('[TRACE] Validando formulario');
      if (_formKey.currentState == null) {
        print('[TRACE][ERROR] _formKey.currentState es null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error interno: el formulario no está listo'), backgroundColor: Colors.red),
        );
        return;
      }
      if (!_formKey.currentState!.validate()) {
        print('[TRACE] Formulario inválido');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor complete todos los campos obligatorios'), backgroundColor: Colors.red),
        );
        return;
      }
      print('[TRACE] Validando carrito');
      if (_cart.isEmpty) {
        print('[TRACE] Carrito vacío');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agregue al menos un producto al carrito'), backgroundColor: Colors.red),
        );
        return;
      }
      print('[TRACE] Obteniendo nombre de cliente y notas');
      final customerName = _customerNameController.text.trim();
      final notes = _noteController.text.trim();
      print('[TRACE] Nombre cliente: "$customerName" | Notas: "$notes"');
      print('[TRACE] Validando productos en carrito');
      for (final item in _cart) {
        final p = item.product;
        print('[TRACE] Producto: ${p.toString()} | Cantidad: ${item.quantity}');
        if (p.id.isEmpty || p.name.isEmpty) {
          print('[TRACE][ERROR] Producto con id o nombre vacío: $p');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Producto inválido en el carrito: ${p.name}'), backgroundColor: Colors.red),
          );
          return;
        }
        if (p.price.isNaN || p.price <= 0) {
          print('[TRACE][ERROR] Producto con precio inválido: $p');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Producto con precio inválido: ${p.name}'), backgroundColor: Colors.red),
          );
          return;
        }
        if (item.quantity > p.stock) {
          print('[TRACE][ERROR] Stock insuficiente para producto: ${p.name}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stock insuficiente para ${p.name}'), backgroundColor: Colors.red),
          );
          return;
        }
      }
      print('[TRACE] Seteando _isSaving = true');
      setState(() { _isSaving = true; });
      print('[TRACE] Obteniendo userId');
      final userId = context.read<AuthService>().currentUser?.uid;
      print('[TRACE] userId: $userId');
      if (userId == null) {
        print('[TRACE][ERROR] Usuario no autenticado');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
        return;
      }
      print('[TRACE] Construyendo SaleItems');
      final items = _cart.map((item) {
        final p = item.product;
        print('[TRACE] SaleItem: productId=${p.id}, productName=${p.name}, quantity=${item.quantity}, unitPrice=${p.price}, subtotal=${p.price * item.quantity}');
        return SaleItem(
          productId: p.id,
          productName: p.name,
          quantity: item.quantity,
          unitPrice: p.price,
          subtotal: p.price * item.quantity,
        );
      }).toList();
      print('[TRACE] SaleItems construidos: ${items.length}');
      if (items.isEmpty || items.any((i) => i.productId.isEmpty || i.productName.isEmpty || i.unitPrice.isNaN || i.quantity <= 0)) {
        print('[TRACE][ERROR] SaleItem inválido detectado en la lista. items: $items');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error interno: producto inválido en la venta'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
        return;
      }
      final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);
      print('[TRACE] Total calculado: $total');
      print('[TRACE] Creando objeto Sale');
      final sale = Sale(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        customerName: customerName,
        total: total,
        items: items,
        date: DateTime.now(),
        notes: notes.isEmpty ? null : notes,
      );
      print('[TRACE] Sale creado: ${sale.toMap()}');
      final saleViewModel = context.read<SaleViewModel>();
      final success = await saleViewModel.addSale(sale);
      print('[NewSaleScreen] Resultado de guardar venta: $success');
      if (success) {
        final dashboardViewModel = context.read<DashboardViewModel>();
        dashboardViewModel.clearData();
        await dashboardViewModel.loadDashboardData();
        await saleViewModel.loadSales();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Venta registrada correctamente - \$${_cartTotal % 1 == 0 ? _cartTotal.toStringAsFixed(0) : _cartTotal.toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          print('[NewSaleScreen] Venta registrada correctamente. Redirigiendo a home.');
          context.go('/');
        }
      } else {
        final errorType = saleViewModel.errorType ?? AppErrorType.desconocido;
        final errorMsg = saleViewModel.error ?? 'Error desconocido';
        print('[NewSaleScreen][ERROR] Error al guardar la venta. Tipo de error: $errorType | Mensaje: $errorMsg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la venta: $errorType\n$errorMsg'), backgroundColor: Colors.red),
        );
      }
    } catch (e, st) {
      print('[NewSaleScreen][EXCEPTION] Excepción al guardar venta: $e');
      print(st);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excepción inesperada: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
      print('[NewSaleScreen] Guardado de venta finalizado.');
    }
  }

  Future<void> _scanBarcode() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(),
        ),
      );
      if (result != null && result is Product) {
        _selectProduct(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto "${result.name}" seleccionado desde escáner'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al escanear: \$${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSearchSection() {
    return ResponsiveFormField(
      label: 'Búsqueda de Productos',
      helperText: 'Busca por nombre o código de barras',
      prefix: Icon(Icons.search, color: Colors.blue),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          SizedBox(height: Responsive.getResponsiveSpacing(context)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _scanBarcode,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(Responsive.isMobile(context) 
                  ? 'Escanear' 
                  : 'Escanear Código de Barras'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.isMobile(context) ? 14 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListSection(ProductViewModel productVM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Seleccionar Producto',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Builder(
          builder: (context) {
            final products = productVM.products;
            final categoryVM = context.read<CategoryViewModel>();
            
            // Función para obtener el nombre de la categoría
            String getCategoryName(String categoryId) {
              try {
                final category = categoryVM.categories.firstWhere((cat) => cat.id == categoryId);
                return category.name;
              } catch (e) {
                return 'Sin categoría';
              }
            }
            
            final filteredProducts = _searchQuery.isEmpty
                ? products
                : products.where((p) {
                    final categoryName = getCategoryName(p.categoryId);
                    return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           (p.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                           categoryName.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();
            
            if (productVM.isLoading && products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (productVM.error != null) {
              return Center(child: Text(productVM.error!));
            }
            if (filteredProducts.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: Responsive.isMobile(context) ? 48 : 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: Responsive.getResponsiveSpacing(context)),
                      Text(
                        _searchQuery.isEmpty 
                            ? 'No hay productos disponibles'
                            : 'No se encontraron productos',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(context, 16),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.6, // 60% de la altura de la pantalla
              child: ListView.separated(
                itemCount: filteredProducts.length,
                separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.7),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final selected = _selectedProduct?.id == product.id;
                  return ListTile(
                    selected: selected,
                    selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      child: Icon(
                        Icons.inventory_2,
                        color: Colors.blue[700],
                        size: Responsive.isMobile(context) ? 20 : 24,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.getResponsiveFontSize(context, 16),
                            ),
                          ),
                        ),
                        Text(
                          product.price % 1 == 0
                            ? '\$${product.price.toStringAsFixed(0)}'
                            : '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.getResponsiveFontSize(context, 16),
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Stock: ${product.stock}',
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveFontSize(context, 14),
                                color: product.stock > 0 ? Colors.green[600] : Colors.red[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                getCategoryName(product.categoryId),
                                style: TextStyle(
                                  fontSize: Responsive.getResponsiveFontSize(context, 12),
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (product.barcode != null && product.barcode!.isNotEmpty)
                          Text(
                            'Código: ${product.barcode}',
                            style: TextStyle(
                              fontSize: Responsive.getResponsiveFontSize(context, 12),
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Editar producto',
                          child: IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            splashRadius: 18,
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProductScreen(productId: product.id),
                                ),
                              );
                              if (result == true) {
                                // Recargar productos después de editar
                                await context.read<ProductViewModel>().forceReloadProducts();
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    onTap: product.stock > 0 ? () => _selectProduct(product) : null,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectedProductSection({int? stock, bool withTooltip = false}) {
    if (_selectedProduct == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: withTooltip
                ? Tooltip(
                    message: 'Nombre del producto seleccionado',
                    child: Text(
                      _selectedProduct!.name,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveFontSize(context, 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text(
                    _selectedProduct!.name,
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(context, 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
            withTooltip
              ? Tooltip(
                  message: 'Deseleccionar producto',
                  child: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedProduct = null;
                        _selectedQuantity = 1;
                      });
                    },
                    tooltip: 'Deseleccionar producto',
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedProduct = null;
                      _selectedQuantity = 1;
                    });
                  },
                  tooltip: 'Deseleccionar producto',
                ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2.0, bottom: 8.0),
          child: withTooltip
            ? Tooltip(
                message: 'Precio unitario del producto',
                child: Text(
                  'Precio: ' +
                    (_selectedProduct!.price % 1 == 0
                      ? '\$${_selectedProduct!.price.toStringAsFixed(0)}'
                      : '\$${_selectedProduct!.price.toStringAsFixed(2)}'),
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(context, 15),
                    color: Colors.grey[600],
                  ),
                ),
              )
            : Text(
                'Precio: ' +
                  (_selectedProduct!.price % 1 == 0
                    ? '\$${_selectedProduct!.price.toStringAsFixed(0)}'
                    : '\$${_selectedProduct!.price.toStringAsFixed(2)}'),
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(context, 15),
                  color: Colors.grey[600],
                ),
              ),
        ),
        if (stock != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: withTooltip
              ? Tooltip(
                  message: 'Stock disponible de este producto',
                  child: Text(
                    'Stock disponible: $stock',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(context, 13),
                      color: stock > 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                )
              : Text(
                  'Stock disponible: $stock',
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(context, 13),
                    color: stock > 0 ? Colors.green[700] : Colors.red[700],
                  ),
                ),
          ),
        Row(
          children: [
            withTooltip
              ? Tooltip(
                  message: 'Cantidad a vender',
                  child: const Text('Cantidad:', style: TextStyle(fontWeight: FontWeight.w500)),
                )
              : const Text('Cantidad:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 10),
            withTooltip
              ? Tooltip(
                  message: 'Disminuir cantidad',
                  child: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    splashRadius: 18,
                    onPressed: _selectedQuantity > 1 ? () => _updateSelectedQuantity(_selectedQuantity - 1) : null,
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  splashRadius: 18,
                  onPressed: _selectedQuantity > 1 ? () => _updateSelectedQuantity(_selectedQuantity - 1) : null,
                ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: withTooltip
                ? Tooltip(
                    message: 'Cantidad seleccionada',
                    child: Text('$_selectedQuantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  )
                : Text('$_selectedQuantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            withTooltip
              ? Tooltip(
                  message: 'Aumentar cantidad',
                  child: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    splashRadius: 18,
                    onPressed: (stock != null && _selectedQuantity < stock) ? () => _updateSelectedQuantity(_selectedQuantity + 1) : null,
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  splashRadius: 18,
                  onPressed: (stock != null && _selectedQuantity < stock) ? () => _updateSelectedQuantity(_selectedQuantity + 1) : null,
                ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              withTooltip
                ? Tooltip(
                    message: 'Subtotal de este producto',
                    child: const Text(
                      'Subtotal:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const Text(
                    'Subtotal:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              withTooltip
                ? Tooltip(
                    message: 'Subtotal de este producto',
                    child: Text(
                      (_selectedProduct!.price * _selectedQuantity) % 1 == 0
                        ? '\$${(_selectedProduct!.price * _selectedQuantity).toStringAsFixed(0)}'
                        : '\$${(_selectedProduct!.price * _selectedQuantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  )
                : Text(
                    (_selectedProduct!.price * _selectedQuantity) % 1 == 0
                      ? '\$${(_selectedProduct!.price * _selectedQuantity).toStringAsFixed(0)}'
                      : '\$${(_selectedProduct!.price * _selectedQuantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _addToCart(),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Agregar a la venta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 28, thickness: 0.7),
      ],
    );
  }

  Widget _buildCustomerSection({bool withTooltip = false}) {
    return Column(
      children: [
        ResponsiveFormField(
          label: 'Cliente',
          isRequired: true,
          helperText: 'Nombre del cliente que realiza la compra',
          prefix: Icon(Icons.person, color: Colors.purple),
          child: withTooltip
            ? Tooltip(
                message: 'Nombre del cliente',
                child: TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    hintText: 'Nombre del cliente',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el nombre del cliente';
                    }
                    return null;
                  },
                ),
              )
            : TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  hintText: 'Nombre del cliente',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre del cliente';
                  }
                  return null;
                },
              ),
        ),
        ResponsiveFormField(
          label: 'Notas Adicionales',
          helperText: 'Información adicional sobre la venta',
          prefix: Icon(Icons.note, color: Colors.grey),
          child: withTooltip
            ? Tooltip(
                message: 'Notas adicionales para la venta',
                child: TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Notas opcionales...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: Responsive.isMobile(context) ? 2 : 3,
                ),
              )
            : TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: 'Notas opcionales...',
                  border: OutlineInputBorder(),
                ),
                maxLines: Responsive.isMobile(context) ? 2 : 3,
              ),
        ),
      ],
    );
  }

  Widget _buildSaveButton({bool withTooltip = false}) {
    return ResponsiveButtonRow(
      children: [
        if (!Responsive.isMobile(context))
          withTooltip
            ? Tooltip(
                message: 'Cancelar y volver',
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              )
            : OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
        withTooltip
          ? Tooltip(
              message: 'Guardar venta',
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSale,
                icon: _isSaving 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving 
                    ? 'Guardando...' 
                    : Responsive.isMobile(context) 
                        ? 'Guardar Venta' 
                        : 'Completar Venta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.isMobile(context) ? 32 : 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSale,
              icon: _isSaving 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving 
                  ? 'Guardando...' 
                  : Responsive.isMobile(context) 
                      ? 'Guardar Venta' 
                      : 'Completar Venta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.isMobile(context) ? 32 : 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildSelectedProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Producto Seleccionado',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedProduct!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedProduct = null;
                          _selectedQuantity = 1;
                        });
                      },
                      tooltip: 'Deseleccionar producto',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Precio: \$${_selectedProduct!.price.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${(_selectedProduct!.price * _selectedQuantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartSection() {
    if (_cart.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text('Productos en la venta', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cart.length,
          separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.7),
          itemBuilder: (context, index) {
            final item = _cart[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.2),
                child: Icon(Icons.inventory_2, color: Colors.blue[700]),
              ),
              title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Stock: ${item.product.stock}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stepper para cantidad
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Disminuir cantidad',
                    onPressed: item.quantity > 1
                        ? () => _editCartQuantity(item.product.id, item.quantity - 1)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Aumentar cantidad',
                    onPressed: item.quantity < item.product.stock
                        ? () => _editCartQuantity(item.product.id, item.quantity + 1)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (item.product.price % 1 == 0
                      ? '\$${item.product.price.toStringAsFixed(0)}'
                      : '\$${item.product.price.toStringAsFixed(2)}') +
                    ' x ${item.quantity} = ' +
                    ((item.product.price * item.quantity) % 1 == 0
                      ? '\$${(item.product.price * item.quantity).toStringAsFixed(0)}'
                      : '\$${(item.product.price * item.quantity).toStringAsFixed(2)}'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Eliminar producto',
                    onPressed: () => _removeFromCart(item.product.id),
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Total: ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                _cartTotal % 1 == 0
                  ? '\$${_cartTotal.toStringAsFixed(0)}'
                  : '\$${_cartTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18),
              ),
            ],
          ),
        ),
        const Divider(height: 28, thickness: 0.7),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido para AutomaticKeepAliveClientMixin
    final isMobile = Responsive.isMobile(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return Scaffold(
          body: SafeArea(
            child: Selector<ProductViewModel, bool>(
              selector: (context, productVM) => productVM.isLoading,
              builder: (context, isLoading, child) {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Consumer2<ProductViewModel, CategoryViewModel>(
                  builder: (context, productVM, categoryVM, child) {
                    final selectedProduct = _selectedProduct;
                Widget header = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nueva Venta',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registra una nueva venta',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                );
                Widget searchRow = Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 24),
                  child: Row(
                    children: [
                      isMobile
                        ? IconButton(
                            onPressed: _scanBarcode,
                            icon: const Icon(Icons.qr_code_scanner),
                            tooltip: 'Escanear código de barras',
                          )
                        : Tooltip(
                            message: 'Escanear código de barras',
                            child: IconButton(
                              onPressed: _scanBarcode,
                              icon: const Icon(Icons.qr_code_scanner),
                            ),
                          ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: isMobile
                          ? TextField(
                              decoration: InputDecoration(
                                labelText: 'Buscar producto',
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
                              },
                            )
                          : Tooltip(
                              message: 'Buscar producto por nombre o código',
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Buscar producto',
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
                                },
                              ),
                            ),
                      ),
                    ],
                  ),
                );
                Widget productList = Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildProductListSection(productVM),
                );
                Widget selectedProductSection = Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildSelectedProductSection(
                    stock: selectedProduct?.stock,
                    withTooltip: !isMobile,
                  ),
                );
                Widget cartSection = Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildCartSection(),
                );
                Widget customerSection = Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildCustomerSection(withTooltip: !isMobile),
                );
                Widget saveButton = Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildSaveButton(withTooltip: !isMobile),
                );
                Widget customerAndSaveSection = Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      customerSection,
                      saveButton,
                    ],
                  ),
                );
                if (isWide) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              header,
                              searchRow,
                              productList,
                            ],
                          ),
                        ),
                        SizedBox(width: 40),
                        Container(
                          width: 420,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              selectedProductSection,
                              cartSection,
                              customerAndSaveSection,
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        searchRow,
                        productList,
                        selectedProductSection,
                        cartSection,
                        customerAndSaveSection,
                      ],
                    ),
                  );
                }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
} 