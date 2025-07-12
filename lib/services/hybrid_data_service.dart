import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firestore_service.dart';
import 'hive_database_service.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/sale.dart';
import '../models/movement.dart';

class HybridDataService {
  final FirestoreService _firestoreService;
  final HiveDatabaseService _localDatabase;
  final FirebaseAuth _auth;
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  Timer? _syncTimer;
  
  // Cola de operaciones pendientes
  final List<Map<String, dynamic>> _pendingOperations = [];

  HybridDataService({
    required FirestoreService firestoreService,
    required HiveDatabaseService localDatabase,
    required FirebaseAuth auth,
  }) : _firestoreService = firestoreService,
       _localDatabase = localDatabase,
       _auth = auth {
    _initializeConnectivity();
    _startPeriodicSync();
  }

  /// Inicializar el servicio
  Future<void> initialize() async {
    await _localDatabase.initialize();
    await _syncPendingOperations();
  }

  /// Inicializar monitoreo de conectividad
  void _initializeConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        // Volvimos a estar online, sincronizar
        _syncPendingOperations();
      }
    });
  }

  /// Iniciar sincronización periódica
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline) {
        _syncPendingOperations();
      }
    });
  }

  /// Detener el servicio
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _localDatabase.close();
  }

  // ===== PRODUCTOS =====

  /// Obtener todos los productos
  Future<List<Product>> getAllProducts({int offset = 0, int limit = 100}) async {
    try {
      if (_isOnline) {
        // Intentar obtener de Firebase
        final products = await _firestoreService.getProducts();
        // Guardar en local
        for (final product in products) {
          await _localDatabase.insertProduct(product);
        }
        // Devolver lote paginado
        final start = products.length - offset - limit;
        final end = products.length - offset;
        if (start < 0) {
          return products.sublist(0, end);
        } else {
          return products.sublist(start, end);
        }
      } else {
        final products = await _localDatabase.getAllProducts();
        final start = products.length - offset - limit;
        final end = products.length - offset;
        if (start < 0) {
          return products.sublist(0, end);
        } else {
          return products.sublist(start, end);
        }
      }
    } catch (e) {
      final products = await _localDatabase.getAllProducts();
      final start = products.length - offset - limit;
      final end = products.length - offset;
      if (start < 0) {
        return products.sublist(0, end);
      } else {
        return products.sublist(start, end);
      }
    }
  }

  /// Obtener producto por ID
  Future<Product?> getProductById(String id) async {
    try {
      if (_isOnline) {
        // Buscar en la lista de productos
        final products = await _firestoreService.getProducts();
        final product = products.where((p) => p.id == id).firstOrNull;
        if (product != null) {
          await _localDatabase.insertProduct(product);
        }
        return product;
      } else {
        return await _localDatabase.getProductById(id);
      }
    } catch (e) {
      return await _localDatabase.getProductById(id);
    }
  }

  /// Obtener producto por código de barras
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      if (_isOnline) {
        // Buscar en la lista de productos
        final products = await _firestoreService.getProducts();
        final product = products.where((p) => p.barcode == barcode).firstOrNull;
        if (product != null) {
          await _localDatabase.insertProduct(product);
        }
        return product;
      } else {
        return await _localDatabase.getProductByBarcode(barcode);
      }
    } catch (e) {
      return await _localDatabase.getProductByBarcode(barcode);
    }
  }

  /// Crear producto
  Future<void> createProduct(Product product) async {
    // Guardar localmente primero
    await _localDatabase.insertProduct(product);
    
    if (_isOnline) {
      try {
        await _firestoreService.addProduct(product);
      } catch (e) {
        // Agregar a cola de operaciones pendientes
        _addPendingOperation('createProduct', product.toMap());
      }
    } else {
      _addPendingOperation('createProduct', product.toMap());
    }
  }

  /// Actualizar producto
  Future<void> updateProduct(Product product) async {
    // Actualizar localmente primero
    await _localDatabase.updateProduct(product);
    
    if (_isOnline) {
      try {
        await _firestoreService.updateProduct(product.id, product);
      } catch (e) {
        _addPendingOperation('updateProduct', product.toMap());
      }
    } else {
      _addPendingOperation('updateProduct', product.toMap());
    }
  }

  /// Eliminar producto
  Future<void> deleteProduct(String id) async {
    // Eliminar localmente primero
    await _localDatabase.deleteProduct(id);
    
    if (_isOnline) {
      try {
        await _firestoreService.deleteProduct(id);
      } catch (e) {
        _addPendingOperation('deleteProduct', {'id': id});
      }
    } else {
      _addPendingOperation('deleteProduct', {'id': id});
    }
  }

  /// Buscar productos
  Future<List<Product>> searchProducts(String query) async {
    try {
      if (_isOnline) {
        final products = await _firestoreService.getProducts();
        final filteredProducts = products.where((product) =>
          product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.description.toLowerCase().contains(query.toLowerCase()) ||
          (product.barcode?.toLowerCase().contains(query.toLowerCase()) ?? false)
        ).toList();
        
        // Guardar resultados en local
        for (final product in filteredProducts) {
          await _localDatabase.insertProduct(product);
        }
        return filteredProducts;
      } else {
        return await _localDatabase.searchProducts(query);
      }
    } catch (e) {
      return await _localDatabase.searchProducts(query);
    }
  }

  /// Obtener productos con stock bajo
  Future<List<Product>> getLowStockProducts() async {
    try {
      if (_isOnline) {
        final products = await _firestoreService.getLowStockProducts();
        // Actualizar en local
        for (final product in products) {
          await _localDatabase.updateProduct(product);
        }
        return products;
      } else {
        return await _localDatabase.getLowStockProducts();
      }
    } catch (e) {
      return await _localDatabase.getLowStockProducts();
    }
  }

  // ===== CATEGORÍAS =====

  /// Obtener todas las categorías
  Future<List<Category>> getAllCategories({int offset = 0, int limit = 100}) async {
    try {
      print('🔄 HybridDataService: Obteniendo categorías...');
      print('📊 HybridDataService: Estado online: $_isOnline');
      
      if (_isOnline) {
        print('🔄 HybridDataService: Intentando obtener de Firebase...');
        final categories = await _firestoreService.getCategories();
        print('📊 HybridDataService: Categorías obtenidas de Firebase: ${categories.length}');
        
        // Guardar en local
        for (final category in categories) {
          await _localDatabase.insertCategory(category);
        }
        print('✅ HybridDataService: Categorías guardadas en local');
        final start = categories.length - offset - limit;
        final end = categories.length - offset;
        if (start < 0) {
          return categories.sublist(0, end);
        } else {
          return categories.sublist(start, end);
        }
      } else {
        print('🔄 HybridDataService: Modo offline, obteniendo de local...');
        final categories = await _localDatabase.getAllCategories();
        print('📊 HybridDataService: Categorías obtenidas de local: ${categories.length}');
        final start = categories.length - offset - limit;
        final end = categories.length - offset;
        if (start < 0) {
          return categories.sublist(0, end);
        } else {
          return categories.sublist(start, end);
        }
      }
    } catch (e) {
      print('❌ HybridDataService: Error obteniendo categorías: $e');
      print('🔄 HybridDataService: Fallback a datos locales...');
      final categories = await _localDatabase.getAllCategories();
      print('📊 HybridDataService: Categorías de fallback: ${categories.length}');
      final start = categories.length - offset - limit;
      final end = categories.length - offset;
      if (start < 0) {
        return categories.sublist(0, end);
      } else {
        return categories.sublist(start, end);
      }
    }
  }

  /// Crear categoría
  Future<void> createCategory(Category category) async {
    await _localDatabase.insertCategory(category);
    
    if (_isOnline) {
      try {
        await _firestoreService.addCategory(category);
      } catch (e) {
        _addPendingOperation('createCategory', category.toMap());
      }
    } else {
      _addPendingOperation('createCategory', category.toMap());
    }
  }

  /// Actualizar categoría
  Future<void> updateCategory(Category category) async {
    await _localDatabase.updateCategory(category);
    
    if (_isOnline) {
      try {
        await _firestoreService.updateCategory(category.id, category);
      } catch (e) {
        _addPendingOperation('updateCategory', category.toMap());
      }
    } else {
      _addPendingOperation('updateCategory', category.toMap());
    }
  }

  /// Eliminar categoría
  Future<void> deleteCategory(String id) async {
    await _localDatabase.deleteCategory(id);
    
    if (_isOnline) {
      try {
        await _firestoreService.deleteCategory(id);
      } catch (e) {
        _addPendingOperation('deleteCategory', {'id': id});
      }
    } else {
      _addPendingOperation('deleteCategory', {'id': id});
    }
  }

  // ===== VENTAS =====

  /// Obtener todas las ventas
  Future<List<Sale>> getAllSales({int offset = 0, int limit = 100}) async {
    try {
      if (_isOnline) {
        final sales = await _firestoreService.getSales();
        // Guardar en local
        for (final sale in sales) {
          await _localDatabase.insertSale(sale);
        }
        final start = sales.length - offset - limit;
        final end = sales.length - offset;
        if (start < 0) {
          return sales.sublist(0, end);
        } else {
          return sales.sublist(start, end);
        }
      } else {
        final sales = await _localDatabase.getAllSales();
        final start = sales.length - offset - limit;
        final end = sales.length - offset;
        if (start < 0) {
          return sales.sublist(0, end);
        } else {
          return sales.sublist(start, end);
        }
      }
    } catch (e) {
      final sales = await _localDatabase.getAllSales();
      final start = sales.length - offset - limit;
      final end = sales.length - offset;
      if (start < 0) {
        return sales.sublist(0, end);
      } else {
        return sales.sublist(start, end);
      }
    }
  }

  /// Crear venta
  Future<void> createSale(Sale sale) async {
    try {
      print('🔄 HybridDataService: Iniciando createSale...');
      print('📝 HybridDataService: Datos de la venta: ${sale.toMap()}');
      
      // Obtener el producto para verificar stock disponible
      final product = await getProductById(sale.productId);
      if (product == null) {
        throw Exception('Producto no encontrado: ${sale.productId}');
      }
      
      // Verificar que hay suficiente stock
      if (product.stock < sale.quantity) {
        throw Exception('Stock insuficiente. Disponible: ${product.stock}, Solicitado: ${sale.quantity}');
      }
      
      // Calcular nuevo stock
      final newStock = product.stock - sale.quantity;
      print('📊 HybridDataService: Stock actual: ${product.stock}, Cantidad vendida: ${sale.quantity}, Nuevo stock: $newStock');
      
      // Actualizar el producto con el nuevo stock
      final updatedProduct = product.copyWith(
        stock: newStock,
        updatedAt: DateTime.now(),
      );
      
      print('🔄 HybridDataService: Actualizando stock del producto...');
      await updateProduct(updatedProduct);
      print('✅ HybridDataService: Stock actualizado exitosamente');
      
      print('🔄 HybridDataService: Guardando en base de datos local...');
      await _localDatabase.insertSale(sale);
      print('✅ HybridDataService: Venta guardada en local');
      
      print('📊 HybridDataService: Estado online: $_isOnline');
      
      if (_isOnline) {
        try {
          print('🔄 HybridDataService: Intentando guardar en Firebase...');
          await _firestoreService.addSale(sale);
          print('✅ HybridDataService: Venta guardada en Firebase');
        } catch (e) {
          print('❌ HybridDataService: Error al guardar en Firebase: $e');
          print('🔄 HybridDataService: Agregando a operaciones pendientes...');
          _addPendingOperation('createSale', sale.toMap());
          print('✅ HybridDataService: Operación agregada a pendientes');
        }
      } else {
        print('🔄 HybridDataService: Modo offline, agregando a operaciones pendientes...');
        _addPendingOperation('createSale', sale.toMap());
        print('✅ HybridDataService: Operación agregada a pendientes');
      }
      
      print('✅ HybridDataService: createSale completado exitosamente');
    } catch (e) {
      print('❌ HybridDataService: Error en createSale: $e');
      rethrow;
    }
  }

  /// Eliminar venta
  Future<void> deleteSale(String id) async {
    await _localDatabase.deleteSale(id);
    
    if (_isOnline) {
      try {
        await _firestoreService.deleteSale(id);
      } catch (e) {
        _addPendingOperation('deleteSale', {'id': id});
      }
    } else {
      _addPendingOperation('deleteSale', {'id': id});
    }
  }

  // ===== MOVIMIENTOS =====

  /// Obtener todos los movimientos
  Future<List<Movement>> getAllMovements({int offset = 0, int limit = 100}) async {
    try {
      if (_isOnline) {
        final movements = await _firestoreService.getMovements();
        // Guardar en local
        for (final movement in movements) {
          await _localDatabase.insertMovement(movement);
        }
        final start = movements.length - offset - limit;
        final end = movements.length - offset;
        if (start < 0) {
          return movements.sublist(0, end);
        } else {
          return movements.sublist(start, end);
        }
      } else {
        final movements = await _localDatabase.getAllMovements();
        final start = movements.length - offset - limit;
        final end = movements.length - offset;
        if (start < 0) {
          return movements.sublist(0, end);
        } else {
          return movements.sublist(start, end);
        }
      }
    } catch (e) {
      final movements = await _localDatabase.getAllMovements();
      final start = movements.length - offset - limit;
      final end = movements.length - offset;
      if (start < 0) {
        return movements.sublist(0, end);
      } else {
        return movements.sublist(start, end);
      }
    }
  }

  /// Crear movimiento
  Future<void> createMovement(Movement movement) async {
    await _localDatabase.insertMovement(movement);
    
    if (_isOnline) {
      try {
        await _firestoreService.addMovement(movement);
      } catch (e) {
        _addPendingOperation('createMovement', movement.toMap());
      }
    } else {
      _addPendingOperation('createMovement', movement.toMap());
    }
  }

  /// Eliminar movimiento
  Future<void> deleteMovement(String id) async {
    await _localDatabase.deleteMovement(id);
    
    if (_isOnline) {
      try {
        await _firestoreService.deleteMovement(id);
      } catch (e) {
        _addPendingOperation('deleteMovement', {'id': id});
      }
    } else {
      _addPendingOperation('deleteMovement', {'id': id});
    }
  }

  // ===== DASHBOARD =====

  /// Obtener datos del dashboard
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      if (_isOnline) {
        final data = await _firestoreService.getDashboardData();
        return data;
      } else {
        return await _localDatabase.getDashboardData();
      }
    } catch (e) {
      return await _localDatabase.getDashboardData();
    }
  }

  // ===== SINCRONIZACIÓN =====

  /// Agregar operación pendiente
  void _addPendingOperation(String operation, Map<String, dynamic> data) {
    _pendingOperations.add({
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Sincronizar operaciones pendientes
  Future<void> _syncPendingOperations() async {
    if (!_isOnline || _pendingOperations.isEmpty) return;

    final operationsToProcess = List<Map<String, dynamic>>.from(_pendingOperations);
    _pendingOperations.clear();

    for (final operation in operationsToProcess) {
      try {
        final opType = operation['operation'] as String;
        final data = operation['data'] as Map<String, dynamic>;

        switch (opType) {
          case 'createProduct':
            final product = Product.fromMap(data, data['id']);
            await _firestoreService.addProduct(product);
            break;
          case 'updateProduct':
            final product = Product.fromMap(data, data['id']);
            await _firestoreService.updateProduct(product.id, product);
            break;
          case 'deleteProduct':
            await _firestoreService.deleteProduct(data['id']);
            break;
          case 'createCategory':
            final category = Category.fromMap(data, data['id']);
            await _firestoreService.addCategory(category);
            break;
          case 'updateCategory':
            final category = Category.fromMap(data, data['id']);
            await _firestoreService.updateCategory(category.id, category);
            break;
          case 'deleteCategory':
            await _firestoreService.deleteCategory(data['id']);
            break;
          case 'createSale':
            final sale = Sale.fromMap(data, data['id']);
            await _firestoreService.addSale(sale);
            break;
          case 'deleteSale':
            await _firestoreService.deleteSale(data['id']);
            break;
          case 'createMovement':
            final movement = Movement.fromMap(data, data['id']);
            await _firestoreService.addMovement(movement);
            break;
          case 'deleteMovement':
            await _firestoreService.deleteMovement(data['id']);
            break;
        }
      } catch (e) {
        // Si falla, volver a agregar a la cola
        _pendingOperations.add(operation);
      }
    }
  }

  /// Forzar sincronización
  Future<void> forceSync() async {
    await _syncPendingOperations();
  }

  /// Obtener estado de sincronización
  Map<String, dynamic> getSyncStatus() {
    return {
      'isOnline': _isOnline,
      'pendingOperations': _pendingOperations.length,
      'lastSync': _pendingOperations.isNotEmpty 
          ? _pendingOperations.last['timestamp'] 
          : null,
    };
  }

  /// Limpiar datos locales
  Future<void> clearLocalData() async {
    await _localDatabase.clearAllData();
    _pendingOperations.clear();
  }

  /// Obtener estadísticas
  Future<Map<String, dynamic>> getStats() async {
    final localStats = await _localDatabase.getDatabaseStats();
    final syncStatus = getSyncStatus();
    
    return {
      'local': localStats,
      'sync': syncStatus,
    };
  }
} 