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

    // Validar que no exista un producto con el mismo nombre (case-insensitive)
    final productVM = context.read<ProductViewModel>();
    final name = _nameController.text.trim();
    final exists = productVM.products.any((p) => p.name.trim().toLowerCase() == name.toLowerCase());
    if (exists) {
      showAppError(context, AppErrorType.duplicado, detalle: 'Este producto ya existe');
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
    final isWide = MediaQuery.of(context).size.width > 900;
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y subtítulo arriba a la izquierda
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 40, right: 40, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('NEW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16, letterSpacing: 1)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Nuevo producto',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                              letterSpacing: -1,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Agrega un producto a tu inventario',
                    style: TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // El formulario ahora va sin Card, solo con maxWidth 700 y paddings ajustados
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  child: Consumer<ProductViewModel>(
                    builder: (context, productViewModel, child) {
                      return Form(
                        key: _formKey,
                        child: isWide
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Columna izquierda: info básica
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            const Text('Nombre', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                            const SizedBox(height: 4),
                                            TextFormField(
                                              controller: _nameController,
                                              decoration: InputDecoration(
                                                hintText: 'Ej: Aceite para Motor 20W-50',
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                                filled: true,
                                                fillColor: const Color(0xFFF8F8F8),
                                              ),
                                              validator: (value) {
                                                if (value == null || value.trim().isEmpty) {
                                                  return 'El nombre es requerido';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 20),
                                            const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                            const SizedBox(height: 4),
                                            TextFormField(
                                              controller: _descriptionController,
                                              decoration: InputDecoration(
                                                hintText: 'Describe el producto',
                                                prefixIcon: const Icon(Icons.edit_outlined, color: Colors.grey),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                                filled: true,
                                                fillColor: const Color(0xFFF8F8F8),
                                              ),
                                              maxLines: 2,
                                              validator: (value) {
                                                if (value == null || value.trim().isEmpty) {
                                                  return 'La descripción es requerida';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 20),
                                            const Text('Precio', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                            const SizedBox(height: 4),
                                            TextFormField(
                                              controller: _priceController,
                                              decoration: InputDecoration(
                                                hintText: '0.00',
                                                prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                                filled: true,
                                                fillColor: const Color(0xFFF8F8F8),
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
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 32),
                                      // Columna derecha: stock, categoría, código
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            const Text('Stock actual', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                            const SizedBox(height: 4),
                                            TextFormField(
                                              controller: _stockController,
                                              decoration: InputDecoration(
                                                hintText: '0',
                                                prefixIcon: const Icon(Icons.inventory_2_outlined, color: Colors.orange),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                                filled: true,
                                                fillColor: const Color(0xFFF8F8F8),
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
                                            const SizedBox(height: 20),
                                            const Text('Stock mínimo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                            const SizedBox(height: 4),
                                            TextFormField(
                                              controller: _minStockController,
                                              decoration: InputDecoration(
                                                hintText: '0',
                                                prefixIcon: const Icon(Icons.arrow_downward, color: Colors.redAccent),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                                filled: true,
                                                fillColor: const Color(0xFFF8F8F8),
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
                                            const SizedBox(height: 20),
                                            const Text('Stock máximo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                            const SizedBox(height: 4),
                                            TextFormField(
                                              controller: _maxStockController,
                                              decoration: InputDecoration(
                                                hintText: '0',
                                                prefixIcon: const Icon(Icons.arrow_upward, color: Colors.redAccent),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                                filled: true,
                                                fillColor: const Color(0xFFF8F8F8),
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
                                            const SizedBox(height: 20),
                                            const Text('Categoría', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                            const SizedBox(height: 4),
                                            DropdownButtonFormField<String>(
                                              decoration: InputDecoration(
                                                hintText: 'Selecciona una categoría',
                                                prefixIcon: const Icon(Icons.label_outline, color: Colors.blueGrey),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                                filled: true,
                                                fillColor: const Color(0xFFF8F8F8),
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
                                            const SizedBox(height: 20),
                                            const Text('Código de barras', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                            const SizedBox(height: 4),
                                            TextFormField(
                                              controller: _barcodeController,
                                              decoration: InputDecoration(
                                                hintText: 'Escanea o ingresa el código manualmente',
                                                prefixIcon: const Icon(Icons.qr_code, color: Colors.grey),
                                                suffixIcon: Icon(Icons.qr_code_scanner, color: Colors.blueGrey.shade300),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                                filled: true,
                                                fillColor: const Color(0xFFF8F8F8),
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Puedes escanear con un lector o escribir el código manualmente',
                                              style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 13, fontWeight: FontWeight.w400),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24), // Menos espacio
                                  // Botón guardar
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton.icon(
                                      onPressed: _saveProduct,
                                      icon: const Icon(Icons.save_alt, size: 22),
                                      label: const Text('Guardar producto', style: TextStyle(fontSize: 18)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Nombre', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      hintText: 'Ej: Aceite para Motor 20W-50',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F8F8),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'El nombre es requerido';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _descriptionController,
                                    decoration: InputDecoration(
                                      hintText: 'Describe el producto',
                                      prefixIcon: const Icon(Icons.edit_outlined, color: Colors.grey),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F8F8),
                                    ),
                                    maxLines: 2,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'La descripción es requerida';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  const Text('Precio', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _priceController,
                                    decoration: InputDecoration(
                                      hintText: '0.00',
                                      prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F8F8),
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
                                  const SizedBox(height: 20),
                                  const Text('Stock actual', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _stockController,
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      prefixIcon: const Icon(Icons.inventory_2_outlined, color: Colors.orange),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F8F8),
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
                                  const SizedBox(height: 20),
                                  const Text('Stock mínimo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _minStockController,
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      prefixIcon: const Icon(Icons.arrow_downward, color: Colors.redAccent),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F8F8),
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
                                  const SizedBox(height: 20),
                                  const Text('Stock máximo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _maxStockController,
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      prefixIcon: const Icon(Icons.arrow_upward, color: Colors.redAccent),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F8F8),
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
                                  const SizedBox(height: 20),
                                  const Text('Categoría', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      hintText: 'Selecciona una categoría',
                                      prefixIcon: const Icon(Icons.label_outline, color: Colors.blueGrey),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F8F8),
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
                                  const SizedBox(height: 20),
                                  const Text('Código de barras', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _barcodeController,
                                    decoration: InputDecoration(
                                      hintText: 'Ej: 7701234567890',
                                      prefixIcon: const Icon(Icons.qr_code, color: Colors.grey),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                      filled: true,
                                      fillColor: const Color(0xFFF8F8F8),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 36),
                                  // Botón guardar
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton.icon(
                                      onPressed: _saveProduct,
                                      icon: const Icon(Icons.save_alt, size: 22),
                                      label: const Text('Guardar producto', style: TextStyle(fontSize: 18)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 