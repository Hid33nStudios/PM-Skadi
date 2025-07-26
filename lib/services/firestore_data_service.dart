import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/sale.dart';
import '../models/movement.dart';
import '../config/performance_config.dart';

class FirestoreDataService {
  final FirestoreService _firestoreService;
  final FirebaseAuth _auth;
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  
  // Cache inteligente para evitar llamadas duplicadas
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = PerformanceConfig.cacheExpiration;
  
  // Control de llamadas en progreso
  final Map<String, Completer<dynamic>> _pendingCalls = {};

  FirebaseFirestore get _firestore => _firestoreService.firestore;
  String get _userId => _firestoreService.userId;

  FirestoreDataService({
    required FirestoreService firestoreService,
    required FirebaseAuth auth,
  }) : _firestoreService = firestoreService,
       _auth = auth {
    _initializeConnectivity();
  }

  /// Inicializar el servicio
  Future<void> initialize() async {
    // No necesitamos inicializar nada más que conectividad
  }

  /// Inicializar monitoreo de conectividad
  void _initializeConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        // Volvimos a estar online, limpiar cache
        _clearCache();
      }
    });
  }

  /// Detener el servicio
  void dispose() {
    _connectivitySubscription?.cancel();
    _cache.clear();
    _cacheTimestamps.clear();
    _pendingCalls.clear();
  }
  
  /// Verificar si el cache está válido
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiration;
  }
  
  /// Obtener del cache si está válido
  T? _getFromCache<T>(String key) {
    if (_isCacheValid(key)) {
      return _cache[key] as T?;
    }
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    return null;
  }
  
  /// Guardar en cache
  void _saveToCache(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }
  
  /// Limpiar cache
  void _clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
  
  /// Ejecutar llamada con cache y control de duplicados
  Future<T> _executeWithCache<T>(String cacheKey, Future<T> Function() operation) async {
    // Verificar cache primero
    final cached = _getFromCache<T>(cacheKey);
    if (cached != null) {
      print('📦 FirestoreDataService: Usando cache para $cacheKey');
      return cached;
    }
    
    // Verificar si ya hay una llamada en progreso
    if (_pendingCalls.containsKey(cacheKey)) {
      print('⏳ FirestoreDataService: Esperando llamada en progreso para $cacheKey');
      return await _pendingCalls[cacheKey]!.future as T;
    }
    
    // Crear nueva llamada
    final completer = Completer<T>();
    _pendingCalls[cacheKey] = completer;
    
    try {
      print('🔄 FirestoreDataService: Ejecutando operación para $cacheKey');
      final result = await operation();
      _saveToCache(cacheKey, result);
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingCalls.remove(cacheKey);
    }
  }

  // ===== PRODUCTOS =====

  /// Obtener todos los productos
  Future<List<Product>> getAllProducts({int offset = 0, int limit = 100}) async {
    final cacheKey = 'products_${offset}_$limit';
    
    return _executeWithCache<List<Product>>(cacheKey, () async {
      try {
        print('🔄 FirestoreDataService: Obteniendo productos...');
        final products = await _firestoreService.getProducts();
        print('📊 FirestoreDataService: Productos obtenidos: ${products.length}');
        
        final start = products.length - offset - limit;
        final end = products.length - offset;
        if (start < 0) {
          return products.sublist(0, end);
        } else {
          return products.sublist(start, end);
        }
      } catch (e) {
        print('❌ FirestoreDataService: Error obteniendo productos: $e');
        rethrow;
      }
    });
  }

  /// Obtener producto por ID
  Future<Product?> getProductById(String id) async {
    final cacheKey = 'product_$id';
    
    return _executeWithCache<Product?>(cacheKey, () async {
      try {
        final products = await _firestoreService.getProducts();
        return products.where((p) => p.id == id).firstOrNull;
      } catch (e) {
        print('❌ FirestoreDataService: Error obteniendo producto por ID: $e');
        rethrow;
      }
    });
  }

  /// Obtener producto por código de barras
  Future<Product?> getProductByBarcode(String barcode) async {
    final cacheKey = 'product_barcode_$barcode';
    
    return _executeWithCache<Product?>(cacheKey, () async {
      try {
        final products = await _firestoreService.getProducts();
        return products.where((p) => p.barcode == barcode).firstOrNull;
      } catch (e) {
        print('❌ FirestoreDataService: Error obteniendo producto por barcode: $e');
        rethrow;
      }
    });
  }

  /// Crear producto
  Future<void> createProduct(Product product) async {
    try {
      print('🔄 FirestoreDataService: Creando producto: ${product.name}');
      await _firestoreService.addProduct(product);
      print('✅ FirestoreDataService: Producto creado exitosamente');
      
      // Invalidar cache de productos
      _invalidateCache('products');
    } catch (e) {
      print('❌ FirestoreDataService: Error creando producto: $e');
      rethrow;
    }
  }

  /// Actualizar producto
  Future<void> updateProduct(Product product) async {
    try {
      print('🔄 FirestoreDataService: Actualizando producto: ${product.name}');
      await _firestoreService.updateProduct(product.id, product);
      print('✅ FirestoreDataService: Producto actualizado exitosamente');
      
      // Invalidar cache de productos
      _invalidateCache('products');
    } catch (e) {
      print('❌ FirestoreDataService: Error actualizando producto: $e');
      rethrow;
    }
  }

  /// Eliminar producto
  Future<void> deleteProduct(String id) async {
    try {
      print('🔄 FirestoreDataService: Eliminando producto con ID: $id');
      await _firestoreService.deleteProduct(id);
      print('✅ FirestoreDataService: Producto eliminado exitosamente');
      
      // Invalidar cache de productos
      _invalidateCache('products');
    } catch (e) {
      print('❌ FirestoreDataService: Error eliminando producto: $e');
      rethrow;
    }
  }

  // ===== CATEGORÍAS =====

  /// Obtener todas las categorías
  Future<List<Category>> getAllCategories({int offset = 0, int limit = 1000}) async {
    final cacheKey = 'categories_${offset}_$limit';
    
    return _executeWithCache<List<Category>>(cacheKey, () async {
      try {
        print('🔄 FirestoreDataService: Obteniendo categorías...');
        final categories = await _firestoreService.getCategories();
        print('📊 FirestoreDataService: Categorías obtenidas: ${categories.length}');
        
        // Si el límite es muy alto, devolver todas las categorías
        if (limit >= 1000) {
          return categories;
        }
        
        final start = categories.length - offset - limit;
        final end = categories.length - offset;
        if (start < 0) {
          return categories.sublist(0, end);
        } else {
          return categories.sublist(start, end);
        }
      } catch (e) {
        print('❌ FirestoreDataService: Error obteniendo categorías: $e');
        rethrow;
      }
    });
  }

  /// Crear categoría
  Future<void> createCategory(Category category) async {
    try {
      print('🔄 FirestoreDataService: Creando categoría: ${category.name}');
      await _firestoreService.addCategory(category);
      print('✅ FirestoreDataService: Categoría creada exitosamente');
      
      // Invalidar cache de categorías
      _invalidateCache('categories');
    } catch (e) {
      print('❌ FirestoreDataService: Error creando categoría: $e');
      rethrow;
    }
  }

  /// Actualizar categoría
  Future<void> updateCategory(Category category) async {
    try {
      print('🔄 FirestoreDataService: Actualizando categoría: ${category.name}');
      await _firestoreService.updateCategory(category.id, category);
      print('✅ FirestoreDataService: Categoría actualizada exitosamente');
      
      // Invalidar cache de categorías
      _invalidateCache('categories');
    } catch (e) {
      print('❌ FirestoreDataService: Error actualizando categoría: $e');
      rethrow;
    }
  }

  /// Eliminar categoría
  Future<void> deleteCategory(String id) async {
    try {
      print('🔄 FirestoreDataService: Eliminando categoría con ID: $id');
      await _firestoreService.deleteCategory(id);
      print('✅ FirestoreDataService: Categoría eliminada exitosamente');
      
      // Invalidar cache de categorías
      _invalidateCache('categories');
    } catch (e) {
      print('❌ FirestoreDataService: Error eliminando categoría: $e');
      rethrow;
    }
  }

  // ===== VENTAS =====

  /// Obtener todas las ventas
  Future<List<Sale>> getAllSales({int offset = 0, int limit = 100, VoidCallback? onMigrate}) async {
    final cacheKey = 'sales_${offset}_$limit';
    
    return _executeWithCache<List<Sale>>(cacheKey, () async {
      try {
        print('🔄 FirestoreDataService: Obteniendo ventas...');
        final sales = await _firestoreService.getAllSales(onMigrate: onMigrate);
        print('📊 FirestoreDataService: Ventas obtenidas: ${sales.length}');
        
        final start = sales.length - offset - limit;
        final end = sales.length - offset;
        if (start < 0) {
          return sales.sublist(0, end);
        } else {
          return sales.sublist(start, end);
        }
      } catch (e) {
        print('❌ FirestoreDataService: Error obteniendo ventas: $e');
        rethrow;
      }
    });
  }

  /// Crear venta
  Future<void> createSale(Sale sale) async {
    try {
      print('🔄 FirestoreDataService: Creando venta MULTIPRODUCTO...');
      // Validar que haya items
      if (sale.items.isEmpty) {
        throw Exception('La venta no contiene productos.');
      }
      // Validar stock de todos los productos
      final List<Product> productsToUpdate = [];
      for (final item in sale.items) {
        final product = await getProductById(item.productId);
        if (product == null) {
          throw Exception('Producto no encontrado: ${item.productId}');
        }
        if (product.stock < item.quantity) {
          throw Exception('Stock insuficiente para "${product.name}". Disponible: ${product.stock}, Solicitado: ${item.quantity}');
        }
        productsToUpdate.add(product);
      }
      // Actualizar stock de todos los productos y guardar la venta en una transacción
      final userProductsRef = _firestore.collection('pm').doc(_userId).collection('products');
      final userSalesRef = _firestore.collection('pm').doc(_userId).collection('sales');
      await _firestore.runTransaction((transaction) async {
        // Actualizar stock
        for (int i = 0; i < sale.items.length; i++) {
          final item = sale.items[i];
          final product = productsToUpdate[i];
          final newStock = product.stock - item.quantity;
          final productRef = userProductsRef.doc(product.id);
          transaction.update(productRef, {
            'stock': newStock,
            'updatedAt': DateTime.now(),
          });
        }
        // Guardar la venta
        final saleRef = userSalesRef.doc(sale.id);
        transaction.set(saleRef, sale.toMap());
      });
      print('✅ FirestoreDataService: Venta multiproducto creada exitosamente');
      // Invalidar cache de ventas y productos
      _invalidateCache('sales');
      _invalidateCache('products');
      _invalidateCache('dashboard');
    } catch (e) {
      print('❌ FirestoreDataService: Error creando venta multiproducto: $e');
      rethrow;
    }
  }

  /// Eliminar venta
  Future<void> deleteSale(String id) async {
    try {
      print('🔄 FirestoreDataService: Eliminando venta con ID: $id');
      await _firestoreService.deleteSale(id);
      print('✅ FirestoreDataService: Venta eliminada exitosamente');
      
      // Invalidar cache de ventas
      _invalidateCache('sales');
    } catch (e) {
      print('❌ FirestoreDataService: Error eliminando venta: $e');
      rethrow;
    }
  }

  // ===== MOVIMIENTOS =====

  /// Obtener todos los movimientos
  Future<List<Movement>> getAllMovements({int offset = 0, int limit = 100}) async {
    final cacheKey = 'movements_${offset}_$limit';
    
    return _executeWithCache<List<Movement>>(cacheKey, () async {
      try {
        print('🔄 FirestoreDataService: Obteniendo movimientos...');
        final movements = await _firestoreService.getMovements();
        print('📊 FirestoreDataService: Movimientos obtenidos: ${movements.length}');
        
        final start = movements.length - offset - limit;
        final end = movements.length - offset;
        if (start < 0) {
          return movements.sublist(0, end);
        } else {
          return movements.sublist(start, end);
        }
      } catch (e) {
        print('❌ FirestoreDataService: Error obteniendo movimientos: $e');
        rethrow;
      }
    });
  }

  /// Crear movimiento
  Future<void> createMovement(Movement movement) async {
    try {
      print('🔄 FirestoreDataService: Creando movimiento...');
      await _firestoreService.addMovement(movement);
      print('✅ FirestoreDataService: Movimiento creado exitosamente');
      
      // Invalidar cache de movimientos
      _invalidateCache('movements');
    } catch (e) {
      print('❌ FirestoreDataService: Error creando movimiento: $e');
      rethrow;
    }
  }

  /// Eliminar movimiento
  Future<void> deleteMovement(String id) async {
    try {
      print('🔄 FirestoreDataService: Eliminando movimiento con ID: $id');
      await _firestoreService.deleteMovement(id);
      print('✅ FirestoreDataService: Movimiento eliminado exitosamente');
      
      // Invalidar cache de movimientos
      _invalidateCache('movements');
    } catch (e) {
      print('❌ FirestoreDataService: Error eliminando movimiento: $e');
      rethrow;
    }
  }

  // ===== DASHBOARD =====

  /// Obtener datos del dashboard
  Future<Map<String, dynamic>> getDashboardData() async {
    final cacheKey = 'dashboard_data';
    
    return _executeWithCache<Map<String, dynamic>>(cacheKey, () async {
      try {
        print('🔄 FirestoreDataService: Obteniendo datos del dashboard...');
        final data = await _firestoreService.getDashboardData();
        print('✅ FirestoreDataService: Datos del dashboard obtenidos');
        return data;
      } catch (e) {
        print('❌ FirestoreDataService: Error obteniendo datos del dashboard: $e');
        rethrow;
      }
    });
  }

  // ===== UTILIDADES =====

  /// Invalidar cache por tipo
  void _invalidateCache(String type) {
    final keysToRemove = _cache.keys.where((key) => key.startsWith(type)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
    print('🗑️ FirestoreDataService: Cache invalidado para $type (${keysToRemove.length} entradas)');
  }

  /// Buscar productos
  Future<List<Product>> searchProducts(String query) async {
    final cacheKey = 'search_products_$query';
    
    return _executeWithCache<List<Product>>(cacheKey, () async {
      try {
        print('🔄 FirestoreDataService: Buscando productos con query: $query');
        final products = await _firestoreService.getProducts();
        final filtered = products.where((product) {
          final searchLower = query.toLowerCase();
          return product.name.toLowerCase().contains(searchLower) ||
                 (product.barcode?.toLowerCase().contains(searchLower) ?? false) ||
                 (product.description?.toLowerCase().contains(searchLower) ?? false);
        }).toList();
        print('📊 FirestoreDataService: Productos encontrados: ${filtered.length}');
        return filtered;
      } catch (e) {
        print('❌ FirestoreDataService: Error buscando productos: $e');
        rethrow;
      }
    });
  }

  /// Obtener productos con stock bajo
  Future<List<Product>> getLowStockProducts() async {
    final cacheKey = 'low_stock_products';
    
    return _executeWithCache<List<Product>>(cacheKey, () async {
      try {
        print('🔄 FirestoreDataService: Obteniendo productos con stock bajo...');
        final products = await _firestoreService.getProducts();
        final lowStockProducts = products.where((product) => product.stock <= 10).toList();
        print('📊 FirestoreDataService: Productos con stock bajo: ${lowStockProducts.length}');
        return lowStockProducts;
      } catch (e) {
        print('❌ FirestoreDataService: Error obteniendo productos con stock bajo: $e');
        rethrow;
      }
    });
  }

  /// Obtener estado de sincronización
  Map<String, dynamic> getSyncStatus() {
    return {
      'isOnline': _isOnline,
      'isSyncing': false, // FirestoreDataService no sincroniza
      'lastSync': null, // No hay sincronización local
      'pendingOperations': 0, // No hay operaciones pendientes
    };
  }

  /// Obtener estadísticas
  Future<Map<String, dynamic>> getStats() async {
    try {
      final products = await getAllProducts();
      final categories = await getAllCategories();
      final sales = await getAllSales();
      final movements = await getAllMovements();
      
      return {
        'local': {
          'products': products.length,
          'categories': categories.length,
          'sales': sales.length,
          'movements': movements.length,
        },
        'sync': getSyncStatus(),
      };
    } catch (e) {
      return {
        'local': {
          'products': 0,
          'categories': 0,
          'sales': 0,
          'movements': 0,
        },
        'sync': getSyncStatus(),
      };
    }
  }

  /// Forzar sincronización (no aplica para FirestoreDataService)
  Future<void> forceSync() async {
    // No hay sincronización local, solo limpiar cache
    _clearCache();
    print('🔄 FirestoreDataService: Cache limpiado (forceSync)');
  }

  /// Limpiar datos locales (no aplica para FirestoreDataService)
  Future<void> clearLocalData() async {
    // No hay datos locales, solo limpiar cache
    _clearCache();
    print('🔄 FirestoreDataService: Cache limpiado (clearLocalData)');
  }

  /// Obtener estadísticas del servicio
  Map<String, dynamic> getServiceStats() {
    return {
      'cacheSize': _cache.length,
      'pendingCalls': _pendingCalls.length,
      'isOnline': _isOnline,
    };
  }
} 