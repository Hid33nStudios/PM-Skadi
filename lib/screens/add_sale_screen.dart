import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../viewmodels/product_viewmodel.dart';
import '../viewmodels/sale_viewmodel.dart';
import '../services/auth_service.dart';
import '../widgets/responsive_form.dart';
import '../theme/responsive.dart';
import 'barcode_scanner_screen.dart';

class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({super.key});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _customerNameController = TextEditingController();
  final _noteController = TextEditingController();
  String _searchQuery = '';
  String? _selectedProductId;
  String? _selectedProductName;
  double? _selectedProductPrice;
  int _quantity = 1;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    await context.read<ProductViewModel>().loadProducts();
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
        // Producto encontrado - seleccionarlo automáticamente
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
          content: Text('Error al escanear: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedProductId = product.id;
      _selectedProductName = product.name;
      _selectedProductPrice = product.price;
      _quantity = 1;
    });
  }

  void _updateQuantity(int quantity) {
    if (quantity > 0) {
      setState(() {
        _quantity = quantity;
      });
    }
  }

  Future<void> _saveSale() async {
    print('🔄 [AddSaleScreen] Iniciando guardado de venta...');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ [AddSaleScreen] Validación del formulario falló');
      return;
    }
    
    if (_selectedProductId == null) {
      print('❌ [AddSaleScreen] No hay producto seleccionado');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('📦 [AddSaleScreen] Datos de la venta:');
    print('  - Producto ID: $_selectedProductId');
    print('  - Producto Nombre: $_selectedProductName');
    print('  - Precio: $_selectedProductPrice');
    print('  - Cantidad: $_quantity');
    print('  - Cliente: ${_customerNameController.text.trim()}');
    print('  - Notas: ${_noteController.text.trim()}');

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = context.read<AuthService>().currentUser?.uid;
      print('👤 [AddSaleScreen] User ID: $userId');
      
      if (userId == null) {
        print('❌ [AddSaleScreen] No hay usuario autenticado');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay usuario autenticado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final saleViewModel = context.read<SaleViewModel>();
      final sale = Sale(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        productId: _selectedProductId!,
        productName: _selectedProductName!,
        amount: _selectedProductPrice! * _quantity,
        quantity: _quantity,
        date: DateTime.now(),
        notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      print('📝 [AddSaleScreen] Venta a guardar: ${sale.toMap()}');
      final success = await saleViewModel.addSale(sale);
      print('✅ [AddSaleScreen] Resultado de addSale: $success');
      
      if (success) {
        print('✅ [AddSaleScreen] Venta guardada exitosamente');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Venta registrada correctamente - \$${sale.amount.toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          context.go('/sales');
        }
      } else {
        print('❌ [AddSaleScreen] Error al guardar venta: ${saleViewModel.error}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al registrar la venta: ${saleViewModel.error ?? 'Error desconocido'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [AddSaleScreen] Excepción al guardar venta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Sección de búsqueda y escaner responsive
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

  /// Sección del producto seleccionado
  Widget _buildSelectedProductSection() {
    return ResponsiveFormField(
      label: 'Producto Seleccionado',
      helperText: 'Verifica los detalles y ajusta la cantidad',
      prefix: Icon(Icons.shopping_cart, color: Colors.green),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(Responsive.getResponsiveSpacing(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del producto y botón de limpiar
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedProductName ?? '',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveFontSize(context, 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedProductId = null;
                        _selectedProductName = null;
                        _selectedProductPrice = null;
                        _quantity = 1;
                      });
                    },
                    tooltip: 'Deseleccionar producto',
                  ),
                ],
              ),
              SizedBox(height: Responsive.getResponsiveSpacing(context) / 2),
              
              // Precio
              Text(
                'Precio: \$${_selectedProductPrice?.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(context, 16),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: Responsive.getResponsiveSpacing(context)),
              
              // Control de cantidad
              Row(
                children: [
                  Text(
                    'Cantidad: ',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _updateQuantity(_quantity - 1),
                    color: Colors.red[400],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.getResponsiveSpacing(context),
                      vertical: Responsive.getResponsiveSpacing(context) / 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_quantity',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveFontSize(context, 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _updateQuantity(_quantity + 1),
                    color: Colors.green[400],
                  ),
                ],
              ),
              SizedBox(height: Responsive.getResponsiveSpacing(context)),
              
              // Total
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(Responsive.getResponsiveSpacing(context)),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${(_selectedProductPrice! * _quantity).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveFontSize(context, 20),
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Lista de productos responsive
  Widget _buildProductListSection(ProductViewModel productVM) {
    return ResponsiveFormField(
      label: 'Seleccionar Producto',
      helperText: 'Toca un producto para seleccionarlo',
      prefix: Icon(Icons.inventory, color: Colors.blue),
      child: FutureBuilder<List<Product>>(
        future: productVM.searchProducts(_searchQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red[600]),
                ),
              ),
            );
          }
          
          final filteredProducts = snapshot.data ?? [];
          
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

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return Card(
                margin: EdgeInsets.only(
                  bottom: Responsive.getResponsiveSpacing(context),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child: Icon(
                      Icons.inventory_2,
                      color: Colors.blue[700],
                      size: Responsive.isMobile(context) ? 20 : 24,
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.getResponsiveFontSize(context, 16),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock: ${product.stock}',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(context, 14),
                          color: product.stock > 0 ? Colors.green[600] : Colors.red[600],
                        ),
                      ),
                      if (product.barcode != null)
                        Text(
                          'Código: ${product.barcode}',
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveFontSize(context, 12),
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  trailing: Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.getResponsiveFontSize(context, 16),
                      color: Colors.green[700],
                    ),
                  ),
                  onTap: product.stock > 0 ? () => _selectProduct(product) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Sección de información del cliente
  Widget _buildCustomerSection() {
    return Column(
      children: [
        ResponsiveFormField(
          label: 'Cliente',
          isRequired: true,
          helperText: 'Nombre del cliente que realiza la compra',
          prefix: Icon(Icons.person, color: Colors.purple),
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
        ),
        ResponsiveFormField(
          label: 'Notas Adicionales',
          helperText: 'Información adicional sobre la venta',
          prefix: Icon(Icons.note, color: Colors.grey[600]),
          child: TextFormField(
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

  /// Botón de guardar responsive
  Widget _buildSaveButton() {
    return ResponsiveButtonRow(
      children: [
        if (!Responsive.isMobile(context))
          OutlinedButton.icon(
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
        ElevatedButton.icon(
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
                        _selectedProductName ?? '',
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
                          _selectedProductId = null;
                          _selectedProductName = null;
                          _selectedProductPrice = null;
                          _quantity = 1;
                        });
                      },
                      tooltip: 'Deseleccionar producto',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Precio: \$${_selectedProductPrice?.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Cantidad: '),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => _updateQuantity(_quantity - 1),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _updateQuantity(_quantity + 1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                        '\$${(_selectedProductPrice! * _quantity).toStringAsFixed(2)}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/sales'),
        ),
      ),
      body: _buildResponsiveSaleForm(),
    );
  }

  /// Formulario de venta completamente responsive
  Widget _buildResponsiveSaleForm() {
    return Consumer<ProductViewModel>(
      builder: (context, productVM, child) {
        if (productVM.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ResponsiveForm(
          title: 'Nueva Venta',
          wrapInCard: false, // No usar card en la pantalla completa
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Sección de búsqueda y escaner
                  _buildSearchSection(),
                  
                  // Producto seleccionado
                  if (_selectedProductId != null)
                    _buildSelectedProductSection(),
                  
                  // Lista de productos
                  _buildProductListSection(productVM),
                  
                  // Información del cliente
                  _buildCustomerSection(),
                  
                  // Botón de guardar
                  if (_selectedProductId != null)
                    _buildSaveButton(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileLayout(ProductViewModel productVM) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Campo de búsqueda
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar productos',
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
                  const SizedBox(height: 12),
                  // Botón de escaneo solo en móvil
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _scanBarcode,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Escanear Código de Barras'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedProductId != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildSelectedProductDetails(),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<List<Product>>(
                future: productVM.searchProducts(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  
                  final filteredProducts = snapshot.data ?? [];
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(product.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Stock: ${product.stock}'),
                              if (product.barcode != null)
                                Text('Código: ${product.barcode}'),
                            ],
                          ),
                          trailing: Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () => _selectProduct(product),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Cliente',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el nombre del cliente';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Notas',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  if (_selectedProductId != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSale,
                        icon: _isSaving 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Guardando...' : 'Guardar Venta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(ProductViewModel productVM) {
    return Form(
      key: _formKey,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar productos',
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
                ),
                Expanded(
                  child: FutureBuilder<List<Product>>(
                    future: productVM.searchProducts(_searchQuery),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }
                      
                      final filteredProducts = snapshot.data ?? [];
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(product.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Stock: ${product.stock}'),
                                  if (product.barcode != null)
                                    Text('Código: ${product.barcode}'),
                                ],
                              ),
                              trailing: Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () => _selectProduct(product),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Cliente',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el nombre del cliente';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Notas',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  if (_selectedProductId != null) _buildSelectedProductDetails(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(ProductViewModel productVM) {
    return Form(
      key: _formKey,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar productos',
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
                ),
                Expanded(
                  child: FutureBuilder<List<Product>>(
                    future: productVM.searchProducts(_searchQuery),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }
                      
                      final filteredProducts = snapshot.data ?? [];
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(product.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Stock: ${product.stock}'),
                                  if (product.barcode != null)
                                    Text('Código: ${product.barcode}'),
                                ],
                              ),
                              trailing: Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () => _selectProduct(product),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Cliente',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el nombre del cliente';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Notas',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  if (_selectedProductId != null) _buildSelectedProductDetails(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 