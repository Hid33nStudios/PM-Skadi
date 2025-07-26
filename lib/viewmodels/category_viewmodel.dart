import 'package:flutter/foundation.dart' as foundation;
import '../models/category.dart';
import '../services/firestore_data_service.dart';
import '../services/firestore_optimized_service.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';
import '../utils/error_cases.dart';
import 'package:uuid/uuid.dart';
import 'base_viewmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryViewModel extends BaseViewModel {
  final dynamic _dataService;
  final AuthService _authService;
  
  List<Category> _categories = [];
  Category? _selectedCategory;
  Map<String, dynamic> _categoryStats = {};
  bool _isLoading = false;
  String? _error;
  AppErrorType? _errorType;
  AppErrorType? get errorType => _errorType;
  int _offset = 0;
  final int _limit = 100;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _totalCategories = 0;
  DocumentSnapshot? _lastCategoryDoc;
  int get totalCategories => _totalCategories;
  Map<String, int> get categoryCounts => {};
  int get totalProducts => 0;
  Map<int, DocumentSnapshot?> _pageStartAfter = {};

  CategoryViewModel(this._dataService, this._authService);

  List<Category> get categories => _categories
      .where((c) => c.id.isNotEmpty)
      .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  Category? get selectedCategory => _selectedCategory;
  Map<String, dynamic> get categoryStats => _categoryStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadCategories() async {
    // OPTIMIZACIÓN: No recargar si ya tenemos datos
    if (_categories.isNotEmpty) {
      print('📦 CategoryViewModel: Ya hay categorías cargadas (${_categories.length}), usando datos existentes');
      return;
    }
    
    if (_isLoading) {
      print('⚠️ CategoryViewModel: Ya está cargando categorías, ignorando llamada');
      return; // Evitar múltiples llamadas simultáneas
    }
    
    try {
      _isLoading = true;
      _error = null;
      _errorType = null;
      notifyListeners();

      print('🔄 CategoryViewModel: Cargando categorías con paginación real');
      print('📊 CategoryViewModel: Usando servicio: ${_dataService.runtimeType}');
      
      // Verificar consistencia de datos si es posible
      if (_dataService is FirestoreOptimizedService) {
        final optimizedService = _dataService as FirestoreOptimizedService;
        final isConsistent = await optimizedService.isDataConsistent();
        if (!isConsistent) {
          print('⚠️ CategoryViewModel: Datos inconsistentes detectados, forzando sincronización');
          await optimizedService.forceSync();
        }
      }
      
      // Obtener el total real de categorías para la paginación
      if (_dataService is FirestoreOptimizedService) {
        _totalCategories = await (_dataService as FirestoreOptimizedService).getCategoriesCount();
        print('📊 CategoryViewModel: Total de categorías en la base de datos: $_totalCategories');
      }
      
      // Cargar solo la primera página de categorías
      _categories = await _dataService.getAllCategories(limit: _limit);
      _hasMore = _categories.length >= _limit;
      _lastCategoryDoc = _categories.isNotEmpty ? 
          await _getLastDocumentSnapshot(_categories.last) : null;
      
      print('📊 CategoryViewModel: Primera página cargada: ${_categories.length} categorías');
      print('📊 CategoryViewModel: ¿Hay más páginas? $_hasMore');
      
      if (_categories.isEmpty) {
        print('⚠️  No se encontraron categorías');
      } else {
        for (var category in _categories) {
          print('  - ${category.name} (ID: ${category.id})');
        }
      }
      
      await _loadCategoryStats();
      
      // SOLO EN DESARROLLO: Ejecutar limpieza automática después de cargar
      if (foundation.kDebugMode && _categories.isNotEmpty) {
        print('🔧 DESARROLLO: Ejecutando limpieza automática después de cargar categorías...');
        await _cleanAllDuplicateCategories();
      }
    } catch (e, stackTrace) {
      print('❌ CategoryViewModel: Error cargando categorías: $e');
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtener el DocumentSnapshot del último elemento para la paginación
  Future<DocumentSnapshot?> _getLastDocumentSnapshot(Category category) async {
    try {
      if (_dataService is FirestoreOptimizedService) {
        final firestoreService = _dataService as FirestoreOptimizedService;
        // Obtener el documento de la categoría para usarlo como startAfter
        return await firestoreService.getCategoryDocumentSnapshot(category.id);
      }
      return null;
    } catch (e) {
      print('❌ CategoryViewModel: Error obteniendo DocumentSnapshot: $e');
      return null;
    }
  }

  Future<void> loadCategory(String categoryId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _selectedCategory = _categories.firstWhere((c) => c.id == categoryId);
      
      if (_selectedCategory == null) {
        _error = 'Categoría no encontrada';
      }
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace).message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(Category category) async {
    try {
      print('🔄 CategoryViewModel: Agregando categoría: ${category.name}');
      print('📝 CategoryViewModel: Datos de la categoría: ${category.toMap()}');
      
      // Generar un UUID si el id está vacío
      final String newId = category.id.isEmpty ? const Uuid().v4() : category.id;
      final newCategory = category.copyWith(id: newId);
      
      // OPTIMIZACIÓN: Agregar inmediatamente a la lista local para UI instantánea
      _categories.add(newCategory); // Agregar al final, el getter se encargará del ordenamiento
      _totalCategories++;
      notifyListeners(); // Actualizar UI inmediatamente
      
      print('✅ CategoryViewModel: Categoría agregada localmente para UI instantánea');
      
      // Sincronizar con Firestore en background (sin bloquear la UI)
      _syncCategoryToFirestore(newCategory);
      
      _errorType = null;
      return true;
    } catch (e, stackTrace) {
      print('❌ CategoryViewModel: Error al agregar categoría: $e');
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      notifyListeners();
      return false;
    }
  }

  /// Sincronizar categoría con Firestore en background
  Future<void> _syncCategoryToFirestore(Category category) async {
    try {
      print('🔄 CategoryViewModel: Sincronizando categoría con Firestore en background');
      
      // Crear la categoría en Firestore
      await _dataService.createCategory(category);
      print('✅ CategoryViewModel: Categoría sincronizada con Firestore');
      
      // Limpiar cache del servicio para forzar recarga en otros ViewModels
      if (_dataService is FirestoreOptimizedService) {
        (_dataService as FirestoreOptimizedService).clearCache();
        print('🗑️ CategoryViewModel: Cache limpiado para forzar recarga');
      }
      
    } catch (e) {
      print('❌ CategoryViewModel: Error sincronizando con Firestore: $e');
      // Si falla la sincronización, mantener la categoría local pero marcar como error
      _error = 'Categoría agregada localmente pero no se pudo sincronizar con el servidor';
      _errorType = AppErrorType.sincronizacion;
      notifyListeners();
    }
  }

  /// Actualizar contador del dashboard instantáneamente
  void _updateDashboardCounter() {
    // Notificar al dashboard sobre el cambio en el contador
    // Esto se puede hacer a través de un callback o evento
    print('📊 CategoryViewModel: Contador actualizado a $_totalCategories');
  }

  Future<bool> updateCategory(Category category) async {
    try {
      print('🔄 CategoryViewModel: Actualizando categoría: ${category.name}');
      
      // OPTIMIZACIÓN: Actualizar inmediatamente en la lista local para UI instantánea
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners(); // Actualizar UI inmediatamente
        print('✅ CategoryViewModel: Categoría actualizada localmente para UI instantánea');
      }
      
      // Sincronizar con Firestore en background
      _syncUpdateToFirestore(category);
      
      _errorType = null;
      return true;
    } catch (e, stackTrace) {
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      notifyListeners();
      return false;
    }
  }

  /// Sincronizar actualización con Firestore en background
  Future<void> _syncUpdateToFirestore(Category category) async {
    try {
      print('🔄 CategoryViewModel: Sincronizando actualización con Firestore en background');
      
      await _dataService.updateCategory(category);
      print('✅ CategoryViewModel: Categoría actualizada en Firestore');
      
      // Limpiar cache del servicio para forzar recarga en otros ViewModels
      if (_dataService is FirestoreOptimizedService) {
        (_dataService as FirestoreOptimizedService).clearCache();
        print('🗑️ CategoryViewModel: Cache limpiado para forzar recarga');
      }
      
    } catch (e) {
      print('❌ CategoryViewModel: Error sincronizando actualización con Firestore: $e');
      _error = 'Categoría actualizada localmente pero no se pudo sincronizar con el servidor';
      _errorType = AppErrorType.sincronizacion;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      print('🔄 CategoryViewModel: Eliminando categoría con ID: $id');
      
      // OPTIMIZACIÓN: Eliminar inmediatamente de la lista local para UI instantánea
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        final deletedCategory = _categories[index];
        _categories.removeAt(index);
        _totalCategories--;
        notifyListeners(); // Actualizar UI inmediatamente
        print('✅ CategoryViewModel: Categoría eliminada localmente para UI instantánea');
        
        // Sincronizar con Firestore en background
        _syncDeleteToFirestore(id, deletedCategory);
      }
      
      _errorType = null;
      return true;
    } catch (e, stackTrace) {
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      notifyListeners();
      return false;
    }
  }

  /// Sincronizar eliminación con Firestore en background
  Future<void> _syncDeleteToFirestore(String id, Category deletedCategory) async {
    try {
      print('🔄 CategoryViewModel: Sincronizando eliminación con Firestore en background');
      
      await _dataService.deleteCategory(id);
      print('✅ CategoryViewModel: Categoría eliminada en Firestore');
      
      // Limpiar cache del servicio para forzar recarga en otros ViewModels
      if (_dataService is FirestoreOptimizedService) {
        (_dataService as FirestoreOptimizedService).clearCache();
        print('🗑️ CategoryViewModel: Cache limpiado para forzar recarga');
      }
      
    } catch (e) {
      print('❌ CategoryViewModel: Error sincronizando eliminación con Firestore: $e');
      // Si falla la eliminación en Firestore, restaurar la categoría localmente
      _categories.add(deletedCategory);
      _totalCategories++;
      notifyListeners();
      _error = 'Categoría eliminada localmente pero no se pudo sincronizar con el servidor';
      _errorType = AppErrorType.sincronizacion;
      notifyListeners();
    }
  }

  List<Category> searchCategories(String query) {
    if (query.isEmpty) return _categories;
    
    return _categories.where((category) {
      return category.name.toLowerCase().contains(query.toLowerCase()) ||
             category.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadCategoryStats() async {
    try {
      _categoryStats = {
        'totalCategories': _categories.length,
        'categoriesWithProducts': _categories.length, // Placeholder
        'mostUsedCategory': _categories.isNotEmpty ? _categories.first.name : 'N/A',
      };
    } catch (e, stackTrace) {
      print('❌ Error cargando estadísticas de categorías: $e');
    }
  }

  void clearError() {
    _error = null;
    _errorType = null;
    notifyListeners();
  }

  void clearSelectedCategory() {
    _selectedCategory = null;
    notifyListeners();
  }

  Future<void> loadInitialCategories() async {
    // OPTIMIZACIÓN: No recargar si ya tenemos datos
    if (_categories.isNotEmpty) {
      print('📦 CategoryViewModel: Ya hay categorías cargadas (${_categories.length}), usando datos existentes');
      return;
    }
    
    _categories = [];
    _lastCategoryDoc = null;
    _hasMore = true;
    _totalCategories = await (_dataService as FirestoreOptimizedService).getCategoriesCount();
    await loadMoreCategories();
    
    // 🧹 LIMPIEZA AUTOMÁTICA: Eliminar categorías duplicadas al iniciar sesión
    // SOLO EN DESARROLLO: Eliminar TODAS las categorías duplicadas automáticamente
    if (foundation.kDebugMode) {
      print('🔧 DESARROLLO: Ejecutando limpieza automática completa de duplicados...');
      await _cleanAllDuplicateCategories();
    } else {
      await _cleanDuplicateCategories();
    }
  }

  /// Método para cargar más categorías con paginación real
  Future<void> loadMoreCategories() async {
    if (_isLoadingMore || !_hasMore) return;
    
    try {
      _isLoadingMore = true;
      notifyListeners();
      
      print('🔄 CategoryViewModel: Cargando más categorías con paginación real');
      
      if (_dataService is FirestoreOptimizedService) {
        final firestoreService = _dataService as FirestoreOptimizedService;
        final newCategories = await firestoreService.getAllCategories(
          limit: _limit,
          startAfter: _lastCategoryDoc,
        );
        
        print('📊 CategoryViewModel: Categorías obtenidas de la siguiente página: ${newCategories.length}');
        
        if (newCategories.length < _limit) {
          _hasMore = false;
          print('📊 CategoryViewModel: No hay más páginas disponibles');
        }
        
        // Filtrar duplicados por id
        final existingIds = _categories.map((c) => c.id).toSet();
        final uniqueNewCategories = newCategories.where((c) => !existingIds.contains(c.id)).toList();
        _categories.addAll(uniqueNewCategories);
        
        // Actualizar el último documento para la siguiente página
        if (newCategories.isNotEmpty) {
          _lastCategoryDoc = await _getLastDocumentSnapshot(newCategories.last);
        }
        
        print('📊 CategoryViewModel: Cargadas ${uniqueNewCategories.length} categorías adicionales');
        print('📊 CategoryViewModel: Total de categorías cargadas: ${_categories.length}');
        print('📊 CategoryViewModel: ¿Hay más páginas? $_hasMore');
      }
    } catch (e, stackTrace) {
      print('❌ CategoryViewModel: Error cargando más categorías: $e');
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Método para forzar recarga de categorías después de cambios
  Future<void> forceReloadCategories() async {
    try {
      print('🔄 CategoryViewModel: Forzando recarga de categorías con paginación real...');
      
      // Limpiar cache del servicio
      if (_dataService is FirestoreOptimizedService) {
        (_dataService as FirestoreOptimizedService).clearCache();
        print('🗑️ CategoryViewModel: Cache limpiado para forzar recarga');
      }
      
      // Resetear variables de paginación
      _lastCategoryDoc = null;
      _hasMore = true;
      
      // Forzar recarga incluso si ya hay datos
      _categories = [];
      
      // Esperar un momento para asegurar que Firestore haya procesado los cambios
      await Future.delayed(const Duration(milliseconds: 1000));
      
      await loadCategories();
      
      print('✅ CategoryViewModel: Recarga forzada completada con paginación real');
    } catch (e, stackTrace) {
      print('❌ CategoryViewModel: Error en forceReloadCategories: $e');
      print(stackTrace);
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
    }
  }

  /// 🧹 Función pública para limpiar duplicados manualmente
  Future<Map<String, dynamic>> cleanDuplicateCategoriesManually() async {
    try {
      print('🧹 CategoryViewModel: Limpieza manual de duplicados solicitada...');
      
      // En desarrollo, usar la limpieza completa
      if (foundation.kDebugMode) {
        print('🔧 DESARROLLO: Usando limpieza completa para limpieza manual...');
        await _cleanAllDuplicateCategories();
        
        // Contar duplicados encontrados después de la limpieza
        final Map<String, List<Category>> groupedCategories = {};
        for (final category in _categories) {
          final name = category.name.trim().toLowerCase();
          if (!groupedCategories.containsKey(name)) {
            groupedCategories[name] = [];
          }
          groupedCategories[name]!.add(category);
        }
        
        int totalDuplicates = 0;
        final List<String> duplicateNames = [];
        
        for (final entry in groupedCategories.entries) {
          if (entry.value.length > 1) {
            totalDuplicates += entry.value.length - 1;
            duplicateNames.add(entry.key);
          }
        }
        
        return {
          'success': true,
          'duplicatesFound': totalDuplicates,
          'duplicateNames': duplicateNames,
          'remainingCategories': _categories.length,
        };
      } else {
        // En producción, usar la limpieza normal
        await forceReloadCategories();
        await _cleanDuplicateCategories();
        
        // Contar duplicados encontrados
        final Map<String, List<Category>> groupedCategories = {};
        for (final category in _categories) {
          final name = category.name.trim().toLowerCase();
          if (!groupedCategories.containsKey(name)) {
            groupedCategories[name] = [];
          }
          groupedCategories[name]!.add(category);
        }
        
        int totalDuplicates = 0;
        final List<String> duplicateNames = [];
        
        for (final entry in groupedCategories.entries) {
          if (entry.value.length > 1) {
            totalDuplicates += entry.value.length - 1;
            duplicateNames.add(entry.key);
          }
        }
        
        return {
          'success': true,
          'duplicatesFound': totalDuplicates,
          'duplicateNames': duplicateNames,
          'remainingCategories': _categories.length,
        };
      }
      
    } catch (e, stackTrace) {
      print('❌ CategoryViewModel: Error en limpieza manual: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Contar categorías de un usuario específico
  Future<int> getCategoriesCountByUserId(String userId) async {
    try {
      print('🔄 CategoryViewModel: Contando categorías para usuario: $userId');
      
      if (_dataService is FirestoreOptimizedService) {
        final count = await (_dataService as FirestoreOptimizedService).getCategoriesCountByUserId(userId);
        print('✅ CategoryViewModel: Usuario $userId tiene $count categorías');
        return count;
      } else {
        print('⚠️ CategoryViewModel: Servicio no es FirestoreOptimizedService, usando método alternativo');
        // Fallback para otros servicios
        return 0;
      }
    } catch (e, stackTrace) {
      print('❌ CategoryViewModel: Error contando categorías para usuario $userId: $e');
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
      return 0;
    }
  }

  /// 🔧 DESARROLLO: Función pública para forzar limpieza completa de duplicados
  Future<Map<String, dynamic>> forceCleanAllDuplicates() async {
    if (!foundation.kDebugMode) {
      return {
        'success': false,
        'error': 'Esta función solo está disponible en desarrollo',
      };
    }
    
    try {
      print('🔧 DESARROLLO: Forzando limpieza completa de duplicados...');
      await _cleanAllDuplicateCategories();
      
      return {
        'success': true,
        'message': 'Limpieza completa ejecutada exitosamente',
        'remainingCategories': _categories.length,
      };
    } catch (e, stackTrace) {
      print('❌ DESARROLLO: Error en limpieza forzada: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🧹 Limpiar categorías duplicadas automáticamente
  Future<void> _cleanDuplicateCategories() async {
    try {
      print('🧹 CategoryViewModel: Iniciando limpieza automática de categorías duplicadas...');
      
      if (_categories.isEmpty) {
        print('📦 CategoryViewModel: No hay categorías para limpiar');
        return;
      }
      
      // Agrupar categorías por nombre (coincidencia exacta)
      final Map<String, List<Category>> groupedCategories = {};
      for (final category in _categories) {
        final name = category.name.trim().toLowerCase();
        if (!groupedCategories.containsKey(name)) {
          groupedCategories[name] = [];
        }
        groupedCategories[name]!.add(category);
      }
      
      // Identificar duplicados (más de una categoría con el mismo nombre)
      final List<Category> duplicatesToDelete = [];
      final List<String> duplicateNames = [];
      
      for (final entry in groupedCategories.entries) {
        final categories = entry.value;
        if (categories.length > 1) {
          // Ordenar por fecha de creación (más antigua primero)
          categories.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          // Mantener la más antigua, eliminar las demás
          final toDelete = categories.skip(1).toList();
          duplicatesToDelete.addAll(toDelete);
          duplicateNames.add(entry.key);
          
          print('🔄 CategoryViewModel: Encontradas ${categories.length} categorías con nombre "${entry.key}"');
          print('  - Manteniendo: ${categories.first.name} (ID: ${categories.first.id}, Creada: ${categories.first.createdAt})');
          for (final duplicate in toDelete) {
            print('  - Eliminando: ${duplicate.name} (ID: ${duplicate.id}, Creada: ${duplicate.createdAt})');
          }
        }
      }
      
      if (duplicatesToDelete.isEmpty) {
        print('✅ CategoryViewModel: No se encontraron categorías duplicadas');
        return;
      }
      
      print('🗑️ CategoryViewModel: Eliminando ${duplicatesToDelete.length} categorías duplicadas...');
      
      // Eliminar duplicados de Firestore
      int deletedCount = 0;
      for (final duplicate in duplicatesToDelete) {
        try {
          await _dataService.deleteCategory(duplicate.id);
          deletedCount++;
          print('✅ CategoryViewModel: Eliminada categoría duplicada: ${duplicate.name} (ID: ${duplicate.id})');
        } catch (e) {
          print('❌ CategoryViewModel: Error eliminando categoría ${duplicate.name}: $e');
        }
      }
      
      // Actualizar lista local
      _categories.removeWhere((cat) => duplicatesToDelete.any((dup) => dup.id == cat.id));
      _totalCategories = _categories.length;
      
      // Limpiar cache del servicio
      if (_dataService is FirestoreOptimizedService) {
        (_dataService as FirestoreOptimizedService).clearCache();
        print('🗑️ CategoryViewModel: Cache limpiado después de eliminar duplicados');
      }
      
      print('✅ CategoryViewModel: Limpieza completada');
      print('  - Categorías duplicadas eliminadas: $deletedCount');
      print('  - Nombres afectados: ${duplicateNames.join(', ')}');
      print('  - Total de categorías restantes: ${_categories.length}');
      
      // Notificar cambios
      notifyListeners();
      
    } catch (e, stackTrace) {
      print('❌ CategoryViewModel: Error en limpieza de duplicados: $e');
      print(stackTrace);
      // No propagar el error para no interrumpir el flujo normal
    }
  }

  /// 🧹 DESARROLLO: Limpiar TODAS las categorías duplicadas de la base de datos completa
  Future<void> _cleanAllDuplicateCategories() async {
    try {
      print('🔧 DESARROLLO: Iniciando limpieza completa de TODAS las categorías duplicadas...');
      
      // Cargar TODAS las categorías del usuario (sin límite)
      print('📥 DESARROLLO: Cargando todas las categorías para análisis completo...');
      final allCategories = await _dataService.getAllCategories(limit: 10000); // Límite alto para obtener todas
      
      if (allCategories.isEmpty) {
        print('📦 DESARROLLO: No hay categorías para limpiar');
        return;
      }
      
      print('📊 DESARROLLO: Analizando ${allCategories.length} categorías en total...');
      
      // Agrupar categorías por nombre (coincidencia exacta)
      final Map<String, List<Category>> groupedCategories = {};
      for (final category in allCategories) {
        final name = category.name.trim().toLowerCase();
        if (!groupedCategories.containsKey(name)) {
          groupedCategories[name] = [];
        }
        groupedCategories[name]!.add(category);
      }
      
      // Identificar duplicados (más de una categoría con el mismo nombre)
      final List<Category> duplicatesToDelete = [];
      final List<String> duplicateNames = [];
      
      for (final entry in groupedCategories.entries) {
        final categories = entry.value;
        if (categories.length > 1) {
          // Ordenar por fecha de creación (más antigua primero)
          categories.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          // Mantener la más antigua, eliminar las demás
          final toDelete = categories.skip(1).toList();
          duplicatesToDelete.addAll(toDelete);
          duplicateNames.add(entry.key);
          
          print('🔄 DESARROLLO: Encontradas ${categories.length} categorías con nombre "${entry.key}"');
          print('  - Manteniendo: ${categories.first.name} (ID: ${categories.first.id}, Creada: ${categories.first.createdAt})');
          for (final duplicate in toDelete) {
            print('  - Eliminando: ${duplicate.name} (ID: ${duplicate.id}, Creada: ${duplicate.createdAt})');
          }
        }
      }
      
      if (duplicatesToDelete.isEmpty) {
        print('✅ DESARROLLO: No se encontraron categorías duplicadas en toda la base de datos');
        return;
      }
      
      print('🗑️ DESARROLLO: Eliminando ${duplicatesToDelete.length} categorías duplicadas de toda la base de datos...');
      
      // Eliminar duplicados de Firestore usando batch para mayor eficiencia
      int deletedCount = 0;
      if (_dataService is FirestoreOptimizedService) {
        final firestoreService = _dataService as FirestoreOptimizedService;
        
        // Usar batch para eliminar todas las categorías duplicadas de una vez
        for (final duplicate in duplicatesToDelete) {
          try {
            await firestoreService.deleteCategory(duplicate.id);
            deletedCount++;
            print('✅ DESARROLLO: Eliminada categoría duplicada: ${duplicate.name} (ID: ${duplicate.id})');
          } catch (e) {
            print('❌ DESARROLLO: Error eliminando categoría ${duplicate.name}: $e');
          }
        }
      } else {
        // Fallback para otros servicios
        for (final duplicate in duplicatesToDelete) {
          try {
            await _dataService.deleteCategory(duplicate.id);
            deletedCount++;
            print('✅ DESARROLLO: Eliminada categoría duplicada: ${duplicate.name} (ID: ${duplicate.id})');
          } catch (e) {
            print('❌ DESARROLLO: Error eliminando categoría ${duplicate.name}: $e');
          }
        }
      }
      
      // Limpiar cache del servicio
      if (_dataService is FirestoreOptimizedService) {
        (_dataService as FirestoreOptimizedService).clearCache();
        print('🗑️ DESARROLLO: Cache limpiado después de eliminar duplicados');
      }
      
      print('✅ DESARROLLO: Limpieza completa finalizada');
      print('  - Categorías duplicadas eliminadas: $deletedCount');
      print('  - Nombres afectados: ${duplicateNames.join(', ')}');
      print('  - Total de categorías restantes: ${allCategories.length - deletedCount}');
      
      // Recargar categorías locales después de la limpieza
      _categories = [];
      _lastCategoryDoc = null;
      _hasMore = true;
      await loadMoreCategories();
      
      // Notificar cambios
      notifyListeners();
      
    } catch (e, stackTrace) {
      print('❌ DESARROLLO: Error en limpieza completa de duplicados: $e');
      print(stackTrace);
      // No propagar el error para no interrumpir el flujo normal
    }
  }

  /// Cargar una página específica de categorías usando paginación eficiente
  Future<void> loadCategoriesPage({required int page, required int pageSize}) async {
    if (_isLoading) return;
    try {
      _isLoading = true;
      _error = null;
      _errorType = null;
      notifyListeners();

      // Obtener el total real de categorías
      if (_dataService is FirestoreOptimizedService) {
        print('>>> [VM] Llamando a getCategoriesCount()...');
        _totalCategories = await (_dataService as FirestoreOptimizedService).getCategoriesCount();
        print('>>> [VM] totalCategories actualizado tras getCategoriesCount: $_totalCategories');
      }

      DocumentSnapshot? startAfter;
      if (page > 1) {
        startAfter = _pageStartAfter[page - 1];
      }

      if (_dataService is FirestoreOptimizedService) {
        final optimizedService = _dataService as FirestoreOptimizedService;
        final categories = await optimizedService.getAllCategories(limit: pageSize, startAfter: startAfter);
        print('>>> [VM] Categorías obtenidas en página: ${categories.length}');
        _categories = categories;
        // Guardar el último doc para la siguiente página
        if (categories.isNotEmpty) {
          _pageStartAfter[page] = await optimizedService.getCategoryDocumentSnapshot(categories.last.id);
        }
      } else {
        // Fallback: traer todas y hacer sublist
        final all = await _dataService.getAllCategories(limit: 10000);
        final offset = (page - 1) * pageSize;
        _categories = all.skip(offset).take(pageSize).toList();
      }
      _hasMore = _categories.length >= pageSize;
      print('>>> [VM] _hasMore: $_hasMore, _categories.length: ${_categories.length}, _totalCategories: $_totalCategories');
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ CategoryViewModel: Error cargando página de categorías: $e');
      final appError = AppError.fromException(e, stackTrace);
      _error = appError.message;
      _errorType = appError.appErrorType;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 