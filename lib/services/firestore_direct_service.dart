import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/sale.dart';
import '../models/movement.dart';
import '../utils/error_handler.dart';

class FirestoreDirectService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreDirectService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

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

  // ===== PRODUCTOS =====

  /// Obtener todos los productos
  Future<List<Product>> getAllProducts({int offset = 0, int limit = 100}) async {
    try {
      print('🔄 FirestoreDirectService: Obteniendo productos...');
      final snapshot = await _userProductsRef
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      print('✅ FirestoreDirectService: Productos obtenidos: ${products.length}');
      return products;
    } catch (e) {
      print('❌ FirestoreDirectService: Error obteniendo productos: $e');
      throw AppError.fromException(e);
    }
  }

  /// Obtener producto por ID
  Future<Product?> getProductById(String id) async {
    try {
      final doc = await _userProductsRef.doc(id).get();
      if (doc.exists) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Obtener producto por código de barras
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final snapshot = await _userProductsRef
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Crear producto
  Future<void> createProduct(Product product) async {
    try {
      print('🔄 FirestoreDirectService: Creando producto...');
      await _userProductsRef.add(product.toMap());
      print('✅ FirestoreDirectService: Producto creado exitosamente');
    } catch (e) {
      print('❌ FirestoreDirectService: Error creando producto: $e');
      throw AppError.fromException(e);
    }
  }

  /// Actualizar producto
  Future<void> updateProduct(Product product) async {
    try {
      await _userProductsRef.doc(product.id).update(product.toMap());
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Eliminar producto
  Future<void> deleteProduct(String id) async {
    try {
      await _userProductsRef.doc(id).delete();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Buscar productos
  Future<List<Product>> searchProducts(String query) async {
    try {
      final snapshot = await _userProductsRef.get();
      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      return products.where((product) =>
        product.name.toLowerCase().contains(query.toLowerCase()) ||
        product.description.toLowerCase().contains(query.toLowerCase()) ||
        (product.barcode?.toLowerCase().contains(query.toLowerCase()) ?? false)
      ).toList();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Obtener productos con stock bajo
  Future<List<Product>> getLowStockProducts() async {
    try {
      final snapshot = await _userProductsRef.get();
      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      return products.where((product) => product.stock <= product.minStock).toList();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===== CATEGORÍAS =====

  /// Obtener todas las categorías
  Future<List<Category>> getAllCategories({int offset = 0, int limit = 1000}) async {
    try {
      print('🔄 FirestoreDirectService: Obteniendo categorías...');
      
      // Si el límite es muy alto, obtener todas las categorías sin límite
      if (limit >= 1000) {
        final snapshot = await _userCategoriesRef
            .orderBy('createdAt', descending: true)
            .get();
        
        final categories = snapshot.docs
            .map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        
        print('✅ FirestoreDirectService: Todas las categorías obtenidas: ${categories.length}');
        return categories;
      } else {
        // Usar límite específico para paginación
        final snapshot = await _userCategoriesRef
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
        
        final categories = snapshot.docs
            .map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        
        print('✅ FirestoreDirectService: Categorías obtenidas con límite: ${categories.length}');
        return categories;
      }
    } catch (e) {
      print('❌ FirestoreDirectService: Error obteniendo categorías: $e');
      throw AppError.fromException(e);
    }
  }

  /// Obtener categoría por ID
  Future<Category?> getCategoryById(String id) async {
    try {
      final doc = await _userCategoriesRef.doc(id).get();
      if (doc.exists) {
        return Category.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Crear categoría
  Future<void> createCategory(Category category) async {
    try {
      await _userCategoriesRef.add(category.toMap());
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Actualizar categoría
  Future<void> updateCategory(Category category) async {
    try {
      await _userCategoriesRef.doc(category.id).update(category.toMap());
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Eliminar categoría
  Future<void> deleteCategory(String id) async {
    try {
      await _userCategoriesRef.doc(id).delete();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===== VENTAS =====

  /// Obtener todas las ventas
  Future<List<Sale>> getAllSales({int offset = 0, int limit = 100, void Function()? onMigrate}) async {
    try {
      print('🔄 FirestoreDirectService: Obteniendo ventas...');
      final snapshot = await _userSalesRef
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      bool huboMigracion = false;
      final List<Sale> sales = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        bool needsUpdate = false;
        final corrected = Map<String, dynamic>.from(data);
        if (corrected['notes'] == null) {
          corrected['notes'] = '';
          needsUpdate = true;
        }
        if (corrected['customerName'] == null) {
          corrected['customerName'] = 'Sin cliente';
          needsUpdate = true;
        }
        if (corrected['date'] == null) {
          corrected['date'] = DateTime.now().toIso8601String();
          needsUpdate = true;
        }
        if (corrected['total'] == null) {
          corrected['total'] = 0;
          needsUpdate = true;
        }
        if (corrected['userId'] == null) {
          corrected['userId'] = '<desconocido>';
          needsUpdate = true;
        }
        if (corrected['items'] == null) {
          corrected['items'] = [];
          needsUpdate = true;
        }
        if (needsUpdate) {
          await _userSalesRef.doc(doc.id).set(corrected);
        }
        sales.add(Sale.fromMap(corrected, doc.id));
      }
      if (huboMigracion && onMigrate != null) onMigrate();
      print('✅ FirestoreDirectService: Ventas obtenidas: ${sales.length}');
      return sales;
    } catch (e) {
      print('❌ FirestoreDirectService: Error obteniendo ventas: $e');
      throw AppError.fromException(e);
    }
  }

  /// Obtener venta por ID
  Future<Sale?> getSaleById(String id) async {
    try {
      final doc = await _userSalesRef.doc(id).get();
      if (doc.exists) {
        return Sale.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Crear venta multiproducto
  Future<void> createSale(Sale sale) async {
    try {
      print('🔄 FirestoreDirectService: Creando venta multiproducto...');

      if (sale.items == null || sale.items!.isEmpty) {
        throw Exception('La venta no contiene productos.');
      }

      await _firestore.runTransaction((transaction) async {
        // Map para almacenar productos actualizados
        final Map<String, Product> updatedProducts = {};
        final List<String> productosAfectados = [];

        // 1. Verificar stock de todos los productos y preparar actualizaciones
        for (final item in sale.items!) {
          final productDoc = _userProductsRef.doc(item.productId);
          final productSnap = await transaction.get(productDoc);
          if (!productSnap.exists) {
            throw Exception('Producto no encontrado: ${item.productId}');
          }
          final product = Product.fromMap(productSnap.data() as Map<String, dynamic>, productSnap.id);
          if (product.stock < item.quantity) {
            throw Exception('Stock insuficiente para ${product.name}. Disponible: ${product.stock}, Solicitado: ${item.quantity}');
          }
          updatedProducts[product.id] = product.copyWith(
            stock: product.stock - item.quantity,
            updatedAt: DateTime.now(),
          );
          productosAfectados.add(product.id);
        }

        // 2. Actualizar stock de todos los productos
        for (final product in updatedProducts.values) {
          final productDoc = _userProductsRef.doc(product.id);
          transaction.update(productDoc, product.toMap());
        }

        // 3. Crear la venta
        final saleDocRef = _userSalesRef.doc();
        transaction.set(saleDocRef, sale.toMap());
      });

      print('✅ FirestoreDirectService: Venta multiproducto creada exitosamente');
    } catch (e) {
      print('❌ FirestoreDirectService: Error creando venta multiproducto: $e');
      throw AppError.fromException(e);
    }
  }

  /// Eliminar venta
  Future<void> deleteSale(String id) async {
    try {
      await _userSalesRef.doc(id).delete();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===== MOVIMIENTOS =====

  /// Obtener todos los movimientos
  Future<List<Movement>> getAllMovements({int offset = 0, int limit = 100}) async {
    try {
      print('🔄 FirestoreDirectService: Obteniendo movimientos...');
      final snapshot = await _userMovementsRef
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      
      final movements = snapshot.docs
          .map((doc) => Movement.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      print('✅ FirestoreDirectService: Movimientos obtenidos: ${movements.length}');
      return movements;
    } catch (e) {
      print('❌ FirestoreDirectService: Error obteniendo movimientos: $e');
      throw AppError.fromException(e);
    }
  }

  /// Crear movimiento
  Future<void> createMovement(Movement movement) async {
    try {
      await _userMovementsRef.add(movement.toMap());
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Eliminar movimiento
  Future<void> deleteMovement(String id) async {
    try {
      await _userMovementsRef.doc(id).delete();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===== DASHBOARD =====

  /// Obtener datos del dashboard
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      print('🔄 FirestoreDirectService: Obteniendo datos del dashboard...');
      
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

      print('✅ FirestoreDirectService: Datos del dashboard obtenidos');
      return dashboardData;
    } catch (e) {
      print('❌ FirestoreDirectService: Error obteniendo datos del dashboard: $e');
      throw AppError.fromException(e);
    }
  }

  // ===== UTILIDADES =====

  /// Obtener estadísticas
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
          'pendingOperations': 0,
          'lastSync': DateTime.now().toIso8601String(),
        },
      };
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Obtener estado de sincronización
  Map<String, dynamic> getSyncStatus() {
    return {
      'isOnline': true,
      'pendingOperations': 0,
      'lastSync': DateTime.now().toIso8601String(),
    };
  }

  /// Forzar sincronización (no necesario en Firebase directo)
  Future<void> forceSync() async {
    // No es necesario sincronizar ya que todo es directo
    print('✅ FirestoreDirectService: No es necesario sincronizar (Firebase directo)');
  }

  /// Limpiar datos (solo para testing)
  Future<void> clearAllData() async {
    try {
      // Eliminar todos los documentos de todas las colecciones
      final productsSnapshot = await _userProductsRef.get();
      for (final doc in productsSnapshot.docs) {
        await doc.reference.delete();
      }

      final categoriesSnapshot = await _userCategoriesRef.get();
      for (final doc in categoriesSnapshot.docs) {
        await doc.reference.delete();
      }

      final salesSnapshot = await _userSalesRef.get();
      // Corregir campos nulos en todas las ventas
      for (final doc in salesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        bool needsUpdate = false;
        final corrected = Map<String, dynamic>.from(data);
        if (corrected['notes'] == null) {
          corrected['notes'] = '';
          needsUpdate = true;
        }
        if (corrected['customerName'] == null) {
          corrected['customerName'] = 'Sin cliente';
          needsUpdate = true;
        }
        if (corrected['date'] == null) {
          corrected['date'] = DateTime.now().toIso8601String();
          needsUpdate = true;
        }
        if (corrected['total'] == null) {
          corrected['total'] = 0;
          needsUpdate = true;
        }
        if (corrected['userId'] == null) {
          corrected['userId'] = '<desconocido>';
          needsUpdate = true;
        }
        if (corrected['items'] == null) {
          corrected['items'] = [];
          needsUpdate = true;
        }
        if (needsUpdate) {
          await _userSalesRef.doc(doc.id).set(corrected);
        }
      }
      // Eliminar duplicados estrictos tras migrar/corregir
      final Set<String> uniqueKeys = {};
      final List<String> idsToDelete = [];
      for (final doc in salesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final items = (data['items'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final key = '${data['userId']}_${data['date']}_${data['total']}_${items.join('|')}';
        if (uniqueKeys.contains(key)) {
          idsToDelete.add(doc.id);
        } else {
          uniqueKeys.add(key);
        }
      }
      for (final id in idsToDelete) {
        await _userSalesRef.doc(id).delete();
      }
      if (idsToDelete.isNotEmpty) {
        print('🗑️ Ventas duplicadas eliminadas: ${idsToDelete.length}');
      }
    } catch (e) {
      throw AppError.fromException(e);
    }
  }
} 