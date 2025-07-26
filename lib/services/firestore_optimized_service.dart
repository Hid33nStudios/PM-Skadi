import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/product.dart';
import '../models/category.dart';
import '../models/sale.dart';
import '../models/movement.dart';
import '../utils/error_handler.dart';
import '../config/firebase_optimization_config.dart';
import '../config/performance_config.dart';

class FirestoreOptimizedService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseOptimizationConfig _config;

  // Cache inteligente con TTL dinámico
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, int> _cacheHits = {};
  final Map<String, int> _cacheMisses = {};
  
  // Batch operations optimizadas
  WriteBatch? _currentBatch;
  Timer? _batchTimer;
  final List<Map<String, dynamic>> _batchOperations = [];
  
  // Métricas en tiempo real
  int _readCount = 0;
  int _writeCount = 0;
  int _batchWriteCount = 0;
  int _cacheHitCount = 0;
  int _cacheMissCount = 0;
  DateTime _lastMetricsReset = DateTime.now();
  
  // Streams para métricas en tiempo real
  final StreamController<Map<String, dynamic>> _metricsController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _performanceController = 
      StreamController<Map<String, dynamic>>.broadcast();

  FirestoreOptimizedService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseOptimizationConfig? config,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _config = config ?? FirebaseOptimizationConfig() {
    _initializeMetricsTimer();
  }

  String get _userId => _auth.currentUser?.uid ?? '';

  // Referencias a las subcolecciones
  CollectionReference get _userProductsRef => 
      _firestore.collection('pm').doc(_userId).collection('products');
  
  CollectionReference get _userCategoriesRef => 
      _firestore.collection('pm').doc(_userId).collection('categories');
  
  CollectionReference get _userSalesRef => 
      _firestore.collection('pm').doc(_userId).collection('sales');
  
  CollectionReference get _userMovementsRef => 
      _firestore.collection('pm').doc(_userId).collection('movements');

  // ===== INICIALIZACIÓN DE MÉTRICAS =====

  void _initializeMetricsTimer() {
    Timer.periodic(FirebaseOptimizationConfig.metricsUpdateInterval, (timer) {
      _emitMetrics();
    });
  }

  void _emitMetrics() {
    try {
      if (!_metricsController.isClosed) {
        final metrics = _getCurrentMetrics();
        _metricsController.add(metrics);
      }
      
      if (!_performanceController.isClosed) {
        final performance = _getPerformanceMetrics();
        _performanceController.add(performance);
      }
    } catch (e) {
      print('❌ FirestoreOptimizedService: Error emitiendo métricas: $e');
    }
  }

  // ===== CACHE INTELIGENTE =====

  /// Obtener datos del cache con TTL dinámico
  T? _getFromCache<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) {
      _cacheMisses[key] = (_cacheMisses[key] ?? 0) + 1;
      _cacheMissCount++;
      return null;
    }
    
    final ttl = _getCacheTTL(key);
    if (DateTime.now().difference(timestamp) > ttl) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      _cacheMisses[key] = (_cacheMisses[key] ?? 0) + 1;
      _cacheMissCount++;
      return null;
    }
    
    _cacheHits[key] = (_cacheHits[key] ?? 0) + 1;
    _cacheHitCount++;
    return _cache[key] as T?;
  }

  /// Obtener TTL dinámico basado en el tipo de dato y hardware
  Duration _getCacheTTL(String key) {
    // OPTIMIZACIÓN: Usar configuración de performance
    final baseTTL = PerformanceConfig.getCacheExpiration();
    
    if (key.startsWith('dashboard')) return FirebaseOptimizationConfig.dashboardCacheTTL;
    if (key.startsWith('products')) return FirebaseOptimizationConfig.productsCacheTTL;
    if (key.startsWith('categories')) return FirebaseOptimizationConfig.categoriesCacheTTL;
    if (key.startsWith('sales')) return FirebaseOptimizationConfig.salesCacheTTL;
    if (key.startsWith('movements')) return FirebaseOptimizationConfig.movementsCacheTTL;
    
    // OPTIMIZACIÓN: Ajustar TTL según hardware
    return baseTTL;
  }

  /// Guardar datos en cache con TTL dinámico
  void _setCache<T>(String key, T data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    
    // OPTIMIZACIÓN: Limpiar cache si excede el tamaño máximo (ajustado por hardware)
    final maxCacheSize = PerformanceConfig.getMaxCacheSize();
    if (_cache.length > maxCacheSize) {
      _cleanupCache();
    }
  }

  /// Limpiar cache inteligente
  void _cleanupCache() {
    final entries = _cacheTimestamps.entries.toList();
    entries.sort((a, b) => a.value.compareTo(b.value));
    
    // OPTIMIZACIÓN: Usar tamaño de cache ajustado por hardware
    final maxCacheSize = PerformanceConfig.getMaxCacheSize();
    final toRemove = entries.take(maxCacheSize ~/ 2);
    for (final entry in toRemove) {
      _cache.remove(entry.key);
      _cacheTimestamps.remove(entry.key);
      _cacheHits.remove(entry.key);
      _cacheMisses.remove(entry.key);
    }
    
    print('🗑️ FirestoreOptimizedService: Cache limpiado (${toRemove.length} entradas removidas)');
  }

  /// Limpiar cache completo
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _cacheHits.clear();
    _cacheMisses.clear();
    print('🗑️ FirestoreOptimizedService: Cache completamente limpiado');
  }

  /// Invalidar cache por tipo con estrategia inteligente
  void _invalidateCache(String type) {
    final keysToRemove = _cache.keys.where((key) => key.startsWith(type)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      _cacheHits.remove(key);
      _cacheMisses.remove(key);
    }
    print('🗑️ FirestoreOptimizedService: Cache invalidado para $type (${keysToRemove.length} entradas)');
  }

  // ===== BATCH OPERATIONS OPTIMIZADAS =====

  /// Iniciar batch de escritura con configuración dinámica
  WriteBatch _getBatch() {
    if (_currentBatch == null) {
      _currentBatch = _firestore.batch();
      _batchTimer?.cancel();
      _batchTimer = Timer(FirebaseOptimizationConfig.batchTimeout, () => _commitBatch());
    }
    return _currentBatch!;
  }

  /// Commit batch de escritura con métricas
  Future<void> _commitBatch() async {
    if (_currentBatch != null && _batchOperations.isNotEmpty) {
      try {
        await _currentBatch!.commit();
        _batchWriteCount++;
        
        final operationCount = _batchOperations.length;
        print('✅ FirestoreOptimizedService: Batch commit exitoso ($operationCount operaciones)');
        
        // Limpiar operaciones del batch
        _batchOperations.clear();
        
        // Emitir métricas de performance
        _emitPerformanceMetrics('batch_commit', operationCount);
      } catch (e) {
        print('❌ FirestoreOptimizedService: Error en batch commit: $e');
        _emitPerformanceMetrics('batch_error', 0, error: e.toString());
      } finally {
        _currentBatch = null;
        _batchTimer?.cancel();
        _batchTimer = null;
      }
    }
  }

  /// Agregar operación al batch con tracking
  void _addBatchOperation(String operation, Map<String, dynamic> data) {
    _batchOperations.add({
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now(),
    });
  }

  /// Forzar commit de batch
  Future<void> forceCommitBatch() async {
    await _commitBatch();
  }

  // ===== PRODUCTOS OPTIMIZADOS =====

  /// Obtener todos los productos con paginación real
  Future<Map<String, dynamic>> getAllProducts({int limit = 100, DocumentSnapshot? startAfter}) async {
    final query = _userProductsRef.orderBy('createdAt', descending: true).limit(limit);
    final paginatedQuery = startAfter != null ? query.startAfterDocument(startAfter) : query;
    final snapshot = await paginatedQuery.get();
    final products = snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    return {'products': products, 'lastDoc': lastDoc};
  }

  /// Obtener el total real de productos
  Future<int> getProductsCount() async {
    final snapshot = await _userProductsRef.count().get();
    return snapshot.count ?? 0;
  }

  /// Obtener producto por ID con cache optimizado
  Future<Product?> getProductById(String id) async {
    final cacheKey = 'product_$id';
    
    // Intentar obtener del cache
    final cached = _getFromCache<Product>(cacheKey);
    if (cached != null) {
      print('📦 FirestoreOptimizedService: Producto obtenido del cache: ${cached.name}');
      return cached;
    }

    try {
      final doc = await _userProductsRef.doc(id).get();
      _readCount++;
      
      if (doc.exists) {
        final product = Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        _setCache(cacheKey, product);
        print('✅ FirestoreOptimizedService: Producto obtenido: ${product.name} (petición #$_readCount)');
        return product;
      }
      return null;
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Crear producto con batch optimizado
  Future<void> createProduct(Product product) async {
    try {
      print('🔄 FirestoreOptimizedService: Creando producto...');
      
      final batch = _getBatch();
      final docRef = _userProductsRef.doc();
      batch.set(docRef, product.toMap());
      
      // Agregar operación al tracking
      _addBatchOperation('create_product', {
        'name': product.name,
        'price': product.price,
        'stock': product.stock,
      });
      
      // Invalidar cache de productos
      _invalidateCache('products');
      
      _writeCount++;
      print('✅ FirestoreOptimizedService: Producto agregado al batch: ${product.name} (escritura #$_writeCount)');
    } catch (e) {
      print('❌ FirestoreOptimizedService: Error creando producto: $e');
      throw AppError.fromException(e);
    }
  }

  /// Actualizar producto con batch optimizado
  Future<void> updateProduct(Product product) async {
    try {
      final batch = _getBatch();
      batch.update(_userProductsRef.doc(product.id), product.toMap());
      
      // Agregar operación al tracking
      _addBatchOperation('update_product', {
        'id': product.id,
        'name': product.name,
        'stock': product.stock,
      });
      
      // Invalidar cache específico
      _cache.remove('product_${product.id}');
      _invalidateCache('products');
      
      _writeCount++;
      print('✅ FirestoreOptimizedService: Producto actualizado en batch: ${product.name} (escritura #$_writeCount)');
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Eliminar producto con batch optimizado
  Future<void> deleteProduct(String id) async {
    try {
      final batch = _getBatch();
      batch.delete(_userProductsRef.doc(id));
      
      // Agregar operación al tracking
      _addBatchOperation('delete_product', {'id': id});
      
      // Invalidar cache
      _cache.remove('product_$id');
      _invalidateCache('products');
      
      _writeCount++;
      print('✅ FirestoreOptimizedService: Producto eliminado en batch: $id (escritura #$_writeCount)');
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Obtener productos con stock bajo optimizado
  Future<List<Product>> getLowStockProducts() async {
    try {
      final result = await getAllProducts();
      final products = result['products'] as List<Product>;
      return products.where((product) => product.stock <= product.minStock).toList();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Buscar productos por nombre, descripción o código de barras
  Future<List<Product>> searchProducts(String query) async {
    try {
      final result = await getAllProducts();
      final products = result['products'] as List<Product>;
      final lowerQuery = query.toLowerCase();
      return products.where((product) {
        final nameMatch = product.name.toLowerCase().contains(lowerQuery);
        final descriptionMatch = (product.description ?? '').toLowerCase().contains(lowerQuery);
        final barcodeMatch = (product.barcode ?? '').toLowerCase().contains(lowerQuery);
        return nameMatch || descriptionMatch || barcodeMatch;
      }).toList();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Buscar producto por código de barras
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final result = await getAllProducts();
      final products = result['products'] as List<Product>;
      for (final product in products) {
        if ((product.barcode ?? '').toLowerCase() == barcode.toLowerCase()) {
          return product;
        }
      }
      return null;
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===== CATEGORÍAS OPTIMIZADAS =====

  /// Obtener todas las categorías con paginación eficiente
  Future<List<Category>> getAllCategories({int limit = 100, DocumentSnapshot? startAfter}) async {
    try {
      print('🔄 FirestoreOptimizedService: Obteniendo categorías (límite: $limit)');
      var query = _userCategoriesRef.orderBy('createdAt', descending: true).limit(limit);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final snapshot = await query.get();
      final categories = snapshot.docs.map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      print('✅ FirestoreOptimizedService: Categorías obtenidas con paginación: ${categories.length}');
      return categories;
    } catch (e) {
      print('❌ FirestoreOptimizedService: Error obteniendo categorías: $e');
      throw AppError.fromException(e);
    }
  }

  /// Obtener DocumentSnapshot de una categoría por ID (para paginación)
  Future<DocumentSnapshot?> getCategoryDocumentSnapshot(String id) async {
    try {
      final doc = await _userCategoriesRef.doc(id).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print('❌ FirestoreOptimizedService: Error obteniendo DocumentSnapshot: $e');
      return null;
    }
  }

  /// Obtener el total real de categorías
  Future<int> getCategoriesCount() async {
    final snapshot = await _userCategoriesRef.count().get();
    return snapshot.count ?? 0;
  }

  /// Obtener el total de categorías de un usuario específico
  Future<int> getCategoriesCountByUserId(String userId) async {
    try {
      print('🔄 FirestoreOptimizedService: Contando categorías para usuario: $userId');
      
      final userCategoriesRef = _firestore.collection('pm').doc(userId).collection('categories');
      final snapshot = await userCategoriesRef.count().get();
      final count = snapshot.count ?? 0;
      
      print('✅ FirestoreOptimizedService: Usuario $userId tiene $count categorías');
      return count;
    } catch (e) {
      print('❌ FirestoreOptimizedService: Error contando categorías para usuario $userId: $e');
      throw AppError.fromException(e);
    }
  }

  /// Crear categoría con batch optimizado
  Future<void> createCategory(Category category) async {
    try {
      print('🔄 FirestoreOptimizedService: Iniciando creación de categoría: ${category.name}');
      
      // Si hay un batch pendiente, hacer commit primero
      if (_currentBatch != null && _batchOperations.isNotEmpty) {
        print('🔄 FirestoreOptimizedService: Commit de batch pendiente antes de crear categoría');
        await _commitBatch();
      }
      
      // Crear la categoría directamente (sin batch) para asegurar consistencia
      final docRef = _userCategoriesRef.doc();
      await docRef.set(category.toMap());
      
      // Agregar operación al tracking
      _addBatchOperation('create_category', {
        'name': category.name,
        'description': category.description,
      });
      
      // Invalidar cache de categorías después de confirmar la escritura
      _invalidateCache('categories');
      
      _writeCount++;
      print('✅ FirestoreOptimizedService: Categoría creada exitosamente: ${category.name} (escritura #$_writeCount)');
    } catch (e) {
      print('❌ FirestoreOptimizedService: Error creando categoría: $e');
      throw AppError.fromException(e);
    }
  }

  /// Actualizar categoría con batch optimizado
  Future<void> updateCategory(Category category) async {
    try {
      final batch = _getBatch();
      batch.update(_userCategoriesRef.doc(category.id), category.toMap());
      
      // Agregar operación al tracking
      _addBatchOperation('update_category', {
        'id': category.id,
        'name': category.name,
      });
      
      // Invalidar cache
      _cache.remove('category_${category.id}');
      _invalidateCache('categories');
      
      _writeCount++;
      print('✅ FirestoreOptimizedService: Categoría actualizada en batch: ${category.name} (escritura #$_writeCount)');
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Eliminar categoría con batch optimizado
  Future<void> deleteCategory(String id) async {
    try {
      final batch = _getBatch();
      batch.delete(_userCategoriesRef.doc(id));
      
      // Agregar operación al tracking
      _addBatchOperation('delete_category', {'id': id});
      
      // Invalidar cache
      _cache.remove('category_$id');
      _invalidateCache('categories');
      
      _writeCount++;
      print('✅ FirestoreOptimizedService: Categoría eliminada en batch: $id (escritura #$_writeCount)');
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===== VENTAS OPTIMIZADAS =====

  /// Obtener todas las ventas con cache optimizado
  Future<List<Sale>> getAllSales({int offset = 0, int limit = 100}) async {
    final cacheKey = 'sales_all_${offset}_$limit';
    
    // Intentar obtener del cache
    final cached = _getFromCache<List<Sale>>(cacheKey);
    if (cached != null) {
      print('📦 FirestoreOptimizedService: Ventas obtenidas del cache: ${cached.length}');
      return cached;
    }

    try {
      print('🔄 FirestoreOptimizedService: Obteniendo ventas de Firebase...');
      final snapshot = await _userSalesRef
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      
      final sales = snapshot.docs
          .map((doc) => Sale.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Guardar en cache
      _setCache(cacheKey, sales);
      _readCount++;
      
      print('✅ FirestoreOptimizedService: Ventas obtenidas: ${sales.length} (petición #$_readCount)');
      return sales;
    } catch (e) {
      print('❌ FirestoreOptimizedService: Error obteniendo ventas: $e');
      throw AppError.fromException(e);
    }
  }

  /// Crear venta multiproducto con batch optimizado y validación de stock
  Future<void> createSale(Sale sale) async {
    try {
      print('🔄 FirestoreOptimizedService: Creando venta multiproducto...');

      // Validar que la venta tenga items
      if (sale.items == null || sale.items!.isEmpty) {
        throw Exception('La venta no contiene productos.');
      }

      // Map para almacenar productos actualizados
      final Map<String, Product> updatedProducts = {};
      final List<String> productosAfectados = [];

      // 1. Verificar stock de todos los productos y preparar actualizaciones
      for (final item in sale.items!) {
        final product = await getProductById(item.productId);
        if (product == null) {
          throw Exception('Producto no encontrado: ${item.productId}');
        }
        if (product.stock < item.quantity) {
          throw Exception('Stock insuficiente para ${product.name}. Disponible: ${product.stock}, Solicitado: ${item.quantity}');
        }
        // Preparar producto actualizado
        updatedProducts[product.id] = product.copyWith(
          stock: product.stock - item.quantity,
          updatedAt: DateTime.now(),
        );
        productosAfectados.add(product.id);
      }

      // 2. Crear batch y agregar operaciones
      final batch = _getBatch();
      final saleDocRef = _userSalesRef.doc();
      batch.set(saleDocRef, sale.toMap());

      // 3. Actualizar stock de todos los productos
      for (final product in updatedProducts.values) {
        batch.update(_userProductsRef.doc(product.id), product.toMap());
      }

      // 4. Tracking de operación
      _addBatchOperation('create_sale', {
        'items': sale.items!.map((e) => {
          'productId': e.productId,
          'quantity': e.quantity,
          'unitPrice': e.unitPrice,
        }).toList(),
        'total': sale.total,
      });

      // 5. Invalidar caché de ventas y productos afectados
      _invalidateCache('sales');
      _invalidateCache('products');
      for (final id in productosAfectados) {
        _cache.remove('product_$id');
      }

      _writeCount += 1 + updatedProducts.length; // 1 venta + n productos
      print('✅ FirestoreOptimizedService: Venta multiproducto creada en batch: ${saleDocRef.id} (escrituras #$_writeCount)');
    } catch (e) {
      print('❌ FirestoreOptimizedService: Error creando venta multiproducto: $e');
      throw AppError.fromException(e);
    }
  }

  // ===== MOVIMIENTOS OPTIMIZADOS =====

  /// Obtener todos los movimientos con cache optimizado
  Future<List<Movement>> getAllMovements({int offset = 0, int limit = 100}) async {
    final cacheKey = 'movements_all_${offset}_$limit';
    
    // Intentar obtener del cache
    final cached = _getFromCache<List<Movement>>(cacheKey);
    if (cached != null) {
      print('📦 FirestoreOptimizedService: Movimientos obtenidos del cache: ${cached.length}');
      return cached;
    }

    try {
      print('🔄 FirestoreOptimizedService: Obteniendo movimientos de Firebase...');
      final snapshot = await _userMovementsRef
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      
      final movements = snapshot.docs
          .map((doc) => Movement.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Guardar en cache
      _setCache(cacheKey, movements);
      _readCount++;
      
      print('✅ FirestoreOptimizedService: Movimientos obtenidos: ${movements.length} (petición #$_readCount)');
      return movements;
    } catch (e) {
      print('❌ FirestoreOptimizedService: Error obteniendo movimientos: $e');
      throw AppError.fromException(e);
    }
  }

  /// Crear movimiento con batch optimizado
  Future<void> createMovement(Movement movement) async {
    try {
      final batch = _getBatch();
      final docRef = _userMovementsRef.doc();
      batch.set(docRef, movement.toMap());
      
      // Agregar operación al tracking
      _addBatchOperation('create_movement', {
        'type': movement.type,
        'quantity': movement.quantity,
        'productId': movement.productId,
      });
      
      // Invalidar cache de movimientos
      _invalidateCache('movements');
      
      _writeCount++;
      print('✅ FirestoreOptimizedService: Movimiento agregado al batch: ${movement.id} (escritura #$_writeCount)');
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===== DASHBOARD OPTIMIZADO =====

  /// Obtener datos del dashboard con cache optimizado
  Future<Map<String, dynamic>> getDashboardData() async {
    final cacheKey = 'dashboard_data';
    
    // Intentar obtener del cache
    final cached = _getFromCache<Map<String, dynamic>>(cacheKey);
    if (cached != null) {
      print('📦 FirestoreOptimizedService: Datos del dashboard obtenidos del cache');
      return cached;
    }

    try {
      print('🔄 FirestoreOptimizedService: Obteniendo datos del dashboard...');
      
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Obtener ventas del día
      final todaySalesSnapshot = await _userSalesRef
          .where('date', isGreaterThan: startOfDay)
          .get();
      
      final todaySales = todaySalesSnapshot.docs
          .map((doc) => Sale.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      final todayTotal = todaySales.fold<double>(0, (sum, sale) => sum + sale.total);

      // Obtener ventas de la semana
      final weekSalesSnapshot = await _userSalesRef
          .where('date', isGreaterThan: startOfWeek)
          .get();
      
      final weekSales = weekSalesSnapshot.docs
          .map((doc) => Sale.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      final weekTotal = weekSales.fold<double>(0, (sum, sale) => sum + sale.total);

      // Obtener ventas del mes
      final monthSalesSnapshot = await _userSalesRef
          .where('date', isGreaterThan: startOfMonth)
          .get();
      
      final monthSales = monthSalesSnapshot.docs
          .map((doc) => Sale.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      final monthTotal = monthSales.fold<double>(0, (sum, sale) => sum + sale.total);

      // Obtener productos con stock bajo
      final lowStockProducts = await getLowStockProducts();

      // Obtener total de productos con stock
      final productsSnapshot = await _userProductsRef.get();
      final totalProducts = productsSnapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((product) => product.stock > 0)
          .length;

      final dashboardData = {
        'todaySales': todayTotal,
        'weekSales': weekTotal,
        'monthSales': monthTotal,
        'lowStockCount': lowStockProducts.length,
        'totalProducts': totalProducts,
        'recentSales': todaySales.take(5).map((sale) => sale.toMap()).toList(),
      };

      // Guardar en cache
      _setCache(cacheKey, dashboardData);
      _readCount += 4; // 4 peticiones: ventas día, semana, mes, productos
      
      print('✅ FirestoreOptimizedService: Datos del dashboard obtenidos (peticiones #$_readCount)');
      return dashboardData;
    } catch (e) {
      print('❌ FirestoreOptimizedService: Error obteniendo datos del dashboard: $e');
      throw AppError.fromException(e);
    }
  }

  // ===== MÉTRICAS Y MONITOREO =====

  /// Obtener métricas actuales
  Map<String, dynamic> _getCurrentMetrics() {
    final now = DateTime.now();
    final uptime = now.difference(_lastMetricsReset);
    
    return {
      'timestamp': now.toIso8601String(),
      'uptime': uptime.inSeconds,
      'operations': {
        'readCount': _readCount,
        'writeCount': _writeCount,
        'batchWriteCount': _batchWriteCount,
      },
      'cache': {
        'size': _cache.length,
        'hitCount': _cacheHitCount,
        'missCount': _cacheMissCount,
        'hitRate': _cacheHitCount > 0 ? _cacheHitCount / (_cacheHitCount + _cacheMissCount) : 0.0,
      },
      'batch': {
        'pendingOperations': _batchOperations.length,
        'hasActiveBatch': _currentBatch != null,
      },
      'performance': {
        'averageReadTime': _calculateAverageReadTime(),
        'averageWriteTime': _calculateAverageWriteTime(),
      },
    };
  }

  /// Obtener métricas de performance
  Map<String, dynamic> _getPerformanceMetrics() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'cache': {
        'size': _cache.length,
        'hitRate': _cacheHitCount > 0 ? _cacheHitCount / (_cacheHitCount + _cacheMissCount) : 0.0,
        'efficiency': _calculateCacheEfficiency(),
      },
      'operations': {
        'total': _readCount + _writeCount,
        'reads': _readCount,
        'writes': _writeCount,
        'batches': _batchWriteCount,
      },
      'batch': {
        'pending': _batchOperations.length,
        'active': _currentBatch != null,
      },
    };
  }

  /// Emitir métricas de performance
  void _emitPerformanceMetrics(String event, int count, {String? error}) {
    try {
      if (!_performanceController.isClosed) {
        final metrics = {
          'event': event,
          'count': count,
          'timestamp': DateTime.now().toIso8601String(),
          'error': error,
        };
        _performanceController.add(metrics);
      }
    } catch (e) {
      print('❌ FirestoreOptimizedService: Error emitiendo métricas de performance: $e');
    }
  }

  /// Calcular tiempo promedio de lectura
  double _calculateAverageReadTime() {
    // Implementación simplificada - en una implementación real
    // se trackearían los tiempos individuales
    return _readCount > 0 ? 100.0 : 0.0; // ms promedio
  }

  /// Calcular tiempo promedio de escritura
  double _calculateAverageWriteTime() {
    return _writeCount > 0 ? 150.0 : 0.0; // ms promedio
  }

  /// Calcular eficiencia del cache
  double _calculateCacheEfficiency() {
    final totalRequests = _cacheHitCount + _cacheMissCount;
    if (totalRequests == 0) return 0.0;
    return _cacheHitCount / totalRequests;
  }

  // ===== STREAMS PARA MÉTRICAS =====

  /// Stream de métricas en tiempo real
  Stream<Map<String, dynamic>> get metricsStream => _metricsController.stream;

  /// Stream de performance en tiempo real
  Stream<Map<String, dynamic>> get performanceStream => _performanceController.stream;

  // ===== UTILIDADES =====

  /// Obtener estadísticas completas
  Future<Map<String, dynamic>> getStats() async {
    try {
      final productsSnapshot = await _userProductsRef.get();
      final categoriesSnapshot = await _userCategoriesRef.get();
      final salesSnapshot = await _userSalesRef.get();
      final movementsSnapshot = await _userMovementsRef.get();

      return {
        'local': {
          'products': productsSnapshot.docs.length,
          'categories': categoriesSnapshot.docs.length,
          'sales': salesSnapshot.docs.length,
          'movements': movementsSnapshot.docs.length,
        },
        'sync': {
          'isOnline': true,
          'pendingOperations': _batchOperations.length,
          'lastSync': DateTime.now().toIso8601String(),
        },
        'performance': _getCurrentMetrics(),
        'config': {
          'cacheTTL': FirebaseOptimizationConfig.defaultCacheTTL.inMinutes,
          'batchTimeout': FirebaseOptimizationConfig.batchTimeout.inSeconds,
          'maxCacheSize': FirebaseOptimizationConfig.maxCacheSize,
          'metricsUpdateInterval': FirebaseOptimizationConfig.metricsUpdateInterval.inSeconds,
        },
      };
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Obtener estado de sincronización optimizado
  Map<String, dynamic> getSyncStatus() {
    return {
      'isOnline': true,
      'pendingOperations': _batchOperations.length,
      'lastSync': DateTime.now().toIso8601String(),
      'performance': _getPerformanceMetrics(),
      'batch': {
        'active': _currentBatch != null,
        'pendingCount': _batchOperations.length,
        'lastCommit': _batchWriteCount > 0 ? DateTime.now().toIso8601String() : null,
      },
    };
  }

  /// Verificar consistencia de datos y forzar sincronización si es necesario
  Future<void> forceSync() async {
    try {
      print('🔄 FirestoreOptimizedService: Forzando sincronización...');
      
      // Limpiar todo el cache
      clearCache();
      
      // Commit de cualquier batch pendiente
      if (_currentBatch != null && _batchOperations.isNotEmpty) {
        print('🔄 FirestoreOptimizedService: Commit de batch pendiente...');
        await _commitBatch();
      }
      
      print('✅ FirestoreOptimizedService: Sincronización forzada completada');
    } catch (e) {
      print('❌ FirestoreOptimizedService: Error en sincronización forzada: $e');
      throw AppError.fromException(e);
    }
  }

  /// Verificar si los datos están sincronizados
  Future<bool> isDataConsistent() async {
    try {
      // Verificar que el cache no tenga datos obsoletos
      final cacheKeys = _cache.keys.where((key) => key.startsWith('categories')).toList();
      for (final key in cacheKeys) {
        final timestamp = _cacheTimestamps[key];
        if (timestamp != null) {
          final ttl = _getCacheTTL(key);
          if (DateTime.now().difference(timestamp) > ttl) {
            print('⚠️ FirestoreOptimizedService: Cache obsoleto detectado: $key');
            return false;
          }
        }
      }
      
      return true;
    } catch (e) {
      print('❌ FirestoreOptimizedService: Error verificando consistencia: $e');
      return false;
    }
  }

  /// Resetear métricas
  void resetMetrics() {
    _readCount = 0;
    _writeCount = 0;
    _batchWriteCount = 0;
    _cacheHitCount = 0;
    _cacheMissCount = 0;
    _lastMetricsReset = DateTime.now();
    print('🔄 FirestoreOptimizedService: Métricas reseteadas');
  }

  /// Limpiar recursos
  void dispose() {
    _batchTimer?.cancel();
    _commitBatch();
    clearCache();
    _metricsController.close();
    _performanceController.close();
    print('🧹 FirestoreOptimizedService: Recursos limpiados');
  }
} 