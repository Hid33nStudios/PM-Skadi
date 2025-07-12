import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../viewmodels/product_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';
import '../widgets/responsive_form.dart';
import '../theme/responsive.dart';
import 'barcode_scanner_screen.dart';
import '../utils/error_cases.dart';
import '../viewmodels/dashboard_viewmodel.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();
  final _barcodeController = TextEditingController();
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar el error de setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
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
    super.dispose();
  }

  Future<void> _loadCategories() async {
    await context.read<CategoryViewModel>().loadCategories();
    setState(() {
      _categories = context.read<CategoryViewModel>().categories.map((e) => e.name).toList();
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first;
      }
    });
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
        // Producto encontrado o creado desde el escáner
        setState(() {
          _nameController.text = result.name;
          _descriptionController.text = result.description;
          _priceController.text = result.price.toString();
          _stockController.text = result.stock.toString();
          _minStockController.text = result.minStock.toString();
          _maxStockController.text = result.maxStock.toString();
          _barcodeController.text = result.barcode ?? '';
          
          // Buscar y seleccionar la categoría del producto
          final category = context.read<CategoryViewModel>().categories
              .firstWhere((c) => c.id == result.categoryId, 
                         orElse: () => context.read<CategoryViewModel>().categories.first);
          _selectedCategory = category.name;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto "${result.name}" cargado desde escáner'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final productViewModel = context.read<ProductViewModel>();
      final errorType = productViewModel.errorType ?? AppErrorType.errorAlDescargarDatos;
      showAppError(context, errorType);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione una categoría'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('🔄 [AddProductScreen] Iniciando guardado de producto...');
      final now = DateTime.now();
      final category = context.read<CategoryViewModel>().categories.firstWhere(
            (c) => c.name == _selectedCategory,
          );

      print('📦 [AddProductScreen] Categoría seleccionada: ${category.name} (ID: ${category.id})');
      print('📦 [AddProductScreen] Datos del producto:');
      print('  - Nombre: ${_nameController.text.trim()}');
      print('  - Descripción: ${_descriptionController.text.trim()}');
      print('  - Precio: ${_priceController.text}');
      print('  - Stock: ${_stockController.text}');
      print('  - MinStock: ${_minStockController.text}');
      print('  - MaxStock: ${_maxStockController.text}');
      print('  - Barcode: ${_barcodeController.text.trim()}');

      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        minStock: int.parse(_minStockController.text),
        maxStock: int.parse(_maxStockController.text),
        categoryId: category.id,
        createdAt: now,
        updatedAt: now,
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      );

      print('📝 [AddProductScreen] Producto a guardar: ${product.toMap()}');
      final success = await context.read<ProductViewModel>().addProduct(product);
      print('✅ [AddProductScreen] Resultado de addProduct: $success');
      if (success && mounted) {
        // Recargar dashboard inmediatamente
        context.read<DashboardViewModel>().loadDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/products');
      }
    } catch (e) {
      print('❌ [AddProductScreen] Error al guardar producto: $e');
      if (mounted) {
        final productViewModel = context.read<ProductViewModel>();
        final errorType = productViewModel.errorType ?? AppErrorType.desconocido;
        showAppError(context, errorType);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Producto'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products'),
        ),
      ),
      body: _buildResponsiveForm(),
    );
  }

  /// Construye un formulario responsive que se adapta a diferentes tamaños de pantalla
  Widget _buildResponsiveForm() {
    return Consumer<ProductViewModel>(
      builder: (context, productViewModel, child) {
        return ResponsiveForm(
          title: 'Agregar Nuevo Producto',
          maxWidth: 900, // Ancho máximo en desktop
          children: [
            // Botón de escaneo responsive - más prominente en móvil
            _buildScanButton(),
            
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Información básica del producto
                  _buildBasicInfoSection(),
                  
                  // Información de stock - layout responsive
                  _buildStockSection(),
                  
                  // Categoría y código de barras
                  _buildCategoryAndBarcodeSection(),
                  
                  // Botones de acción responsive
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Botón de escaneo que se adapta al dispositivo
  Widget _buildScanButton() {
    return ResponsiveFormField(
      label: 'Escaneo Rápido',
      helperText: 'Escanea un código de barras para autocompletar campos',
      prefix: Icon(Icons.qr_code_scanner, color: Colors.orange),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _scanBarcode,
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(Responsive.isMobile(context) 
              ? 'Escanear Código' 
              : 'Escanear Código de Barras'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              vertical: Responsive.isMobile(context) ? 16 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  /// Información básica del producto (nombre, descripción, precio)
  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        ResponsiveFormField(
          label: 'Nombre del Producto',
          isRequired: true,
          helperText: 'Nombre descriptivo del producto',
          child: TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Ej: Aceite para Motor 20W-50',
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
        
        ResponsiveFormField(
          label: 'Descripción',
          isRequired: true,
          helperText: 'Descripción detallada del producto',
          child: TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'Describe las características principales del producto',
              border: OutlineInputBorder(),
            ),
            maxLines: Responsive.isMobile(context) ? 2 : 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La descripción es requerida';
              }
              return null;
            },
          ),
        ),
        
        ResponsiveFormField(
          label: 'Precio de Venta',
          isRequired: true,
          helperText: 'Precio en pesos colombianos',
          prefix: Icon(Icons.attach_money, color: Colors.green),
          child: TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              hintText: '0.00',
              border: OutlineInputBorder(),
              prefixText: '\$ ',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El precio es requerido';
              }
              if (double.tryParse(value) == null) {
                return 'Ingresa un precio válido';
              }
              if (double.parse(value) <= 0) {
                return 'El precio debe ser mayor a 0';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  /// Sección de información de stock - responsive layout
  Widget _buildStockSection() {
    if (Responsive.isMobile(context)) {
      // En móvil: campos apilados uno sobre otro
      return Column(
        children: [
          ResponsiveFormField(
            label: 'Stock Actual',
            isRequired: true,
            helperText: 'Cantidad disponible actualmente',
            prefix: Icon(Icons.inventory, color: Colors.blue),
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
                if (int.tryParse(value) == null) {
                  return 'Ingresa un número válido';
                }
                if (int.parse(value) < 0) {
                  return 'El stock no puede ser negativo';
                }
                return null;
              },
            ),
          ),
          ResponsiveFormField(
            label: 'Stock Mínimo',
            isRequired: true,
            helperText: 'Alerta cuando el stock baje de este número',
            child: TextFormField(
              controller: _minStockController,
              decoration: const InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El stock mínimo es requerido';
                }
                if (int.tryParse(value) == null) {
                  return 'Ingresa un número válido';
                }
                if (int.parse(value) < 0) {
                  return 'El stock mínimo no puede ser negativo';
                }
                return null;
              },
            ),
          ),
          ResponsiveFormField(
            label: 'Stock Máximo',
            isRequired: true,
            helperText: 'Capacidad máxima de almacenamiento',
            child: TextFormField(
              controller: _maxStockController,
              decoration: const InputDecoration(
                hintText: '0',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El stock máximo es requerido';
                }
                if (int.tryParse(value) == null) {
                  return 'Ingresa un número válido';
                }
                if (int.parse(value) < 0) {
                  return 'El stock máximo no puede ser negativo';
                }
                return null;
              },
            ),
          ),
        ],
      );
    } else {
      // En tablet/desktop: campos en fila
      return ResponsiveFormField(
        label: 'Gestión de Stock',
        isRequired: true,
        helperText: 'Configura los niveles de inventario',
        prefix: Icon(Icons.inventory_2, color: Colors.blue),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Actual',
                  hintText: '0',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Requerido';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Número inválido';
                  }
                  if (int.parse(value) < 0) {
                    return 'No puede ser negativo';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: Responsive.getResponsiveSpacing(context)),
            Expanded(
              child: TextFormField(
                controller: _minStockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Mínimo',
                  hintText: '0',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Requerido';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Número inválido';
                  }
                  if (int.parse(value) < 0) {
                    return 'No puede ser negativo';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: Responsive.getResponsiveSpacing(context)),
            Expanded(
              child: TextFormField(
                controller: _maxStockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Máximo',
                  hintText: '0',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Requerido';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Número inválido';
                  }
                  if (int.parse(value) < 0) {
                    return 'No puede ser negativo';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Sección de categoría y código de barras
  Widget _buildCategoryAndBarcodeSection() {
    return Column(
      children: [
        ResponsiveFormField(
          label: 'Categoría',
          isRequired: true,
          helperText: 'Selecciona la categoría del producto',
          prefix: Icon(Icons.category, color: Colors.amber),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              hintText: 'Selecciona una categoría',
              border: OutlineInputBorder(),
            ),
            value: _selectedCategory,
            items: _categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor seleccione una categoría';
              }
              return null;
            },
          ),
        ),
        
        ResponsiveFormField(
          label: 'Código de Barras',
          helperText: 'Opcional - puedes ingresarlo manualmente o escanearlo',
          prefix: Icon(Icons.qr_code, color: Colors.grey[600]),
          child: TextFormField(
            controller: _barcodeController,
            decoration: const InputDecoration(
              hintText: 'Ej: 7701234567890',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  /// Botones de acción responsive
  Widget _buildActionButtons() {
    return ResponsiveButtonRow(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _saveProduct,
          icon: const Icon(Icons.save),
          label: Text(Responsive.isMobile(context) 
              ? 'Guardar' 
              : 'Guardar Producto'),
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
} 