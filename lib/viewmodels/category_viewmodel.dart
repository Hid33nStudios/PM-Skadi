import 'package:flutter/foundation.dart' as foundation;
import '../models/category.dart';
import '../services/hybrid_data_service.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';

class CategoryViewModel extends foundation.ChangeNotifier {
  final HybridDataService _dataService;
  final AuthService _authService;
  
  List<Category> _categories = [];
  Category? _selectedCategory;
  Map<String, dynamic> _categoryStats = {};
  bool _isLoading = false;
  String? _error;

  CategoryViewModel(this._dataService, this._authService);

  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  Map<String, dynamic> get categoryStats => _categoryStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    if (_isLoading) {
      print('⚠️ CategoryViewModel: Ya está cargando categorías, ignorando llamada');
      return; // Evitar múltiples llamadas simultáneas
    }
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔄 Cargando categorías');
      print('📊 CategoryViewModel: Usando servicio: ${_dataService.runtimeType}');
      
      _categories = await _dataService.getAllCategories();
      print('📊 CategoryViewModel: Categorías obtenidas del servicio: ${_categories.length}');
      
      print('📊 Categorías cargadas: ${_categories.length}');
      if (_categories.isEmpty) {
        print('⚠️  No se encontraron categorías');
      } else {
        for (var category in _categories) {
          print('  - ${category.name} (ID: ${category.id})');
        }
      }
      
      await _loadCategoryStats();
    } catch (e, stackTrace) {
      print('❌ CategoryViewModel: Error cargando categorías: $e');
      _error = AppError.fromException(e, stackTrace).message;
    } finally {
      _isLoading = false;
      notifyListeners();
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
      
      await _dataService.createCategory(category);
      print('✅ CategoryViewModel: Categoría creada en servicio de datos');
      
      // Recargar categorías de forma asíncrona para evitar problemas de build
      Future.microtask(() async {
        await loadCategories();
        print('✅ CategoryViewModel: Categorías recargadas');
        print('📊 CategoryViewModel: Total de categorías después de agregar: ${_categories.length}');
      });
      
      return true;
    } catch (e, stackTrace) {
      print('❌ CategoryViewModel: Error al agregar categoría: $e');
      _error = AppError.fromException(e, stackTrace).message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      print('🔄 CategoryViewModel: Actualizando categoría: ${category.name}');
      
      await _dataService.updateCategory(category);
      
      // Recargar categorías de forma asíncrona
      Future.microtask(() async {
        await loadCategories();
        print('✅ CategoryViewModel: Categoría actualizada exitosamente');
      });
      
      return true;
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace).message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      print('🔄 CategoryViewModel: Eliminando categoría con ID: $id');
      
      await _dataService.deleteCategory(id);
      
      // Recargar categorías de forma asíncrona
      Future.microtask(() async {
        await loadCategories();
        print('✅ CategoryViewModel: Categoría eliminada exitosamente');
      });
      
      return true;
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace).message;
      notifyListeners();
      return false;
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
    notifyListeners();
  }

  void clearSelectedCategory() {
    _selectedCategory = null;
    notifyListeners();
  }
} 