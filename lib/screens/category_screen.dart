import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart' show AutomaticKeepAliveClientMixin;
import '../models/category.dart';
import '../viewmodels/category_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/error_widgets.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/skeleton_loading.dart';
import '../utils/error_handler.dart';
import '../utils/validators.dart';
import '../config/app_config.dart';
import '../config/performance_config.dart';
import '../utils/performance_logger.dart';
import '../utils/error_cases.dart';
import '../utils/notification_service.dart';
import '../utils/category_diagnostic.dart';
import '../theme/responsive.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> 
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  int _totalPages = 0;
  final Set<String> _selectedCategoryIds = {};
  String _searchQuery = '';

  // Llama a _updatePagination solo en eventos de usuario o después de cargar datos, usando addPostFrameCallback
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryViewModel>().loadInitialCategories().then((_) {
        _updatePagination(_filterCategories(context.read<CategoryViewModel>().categories).length);
      });
      context.read<DashboardViewModel>().loadDashboardData();
    });
  }

  @override
  bool get wantKeepAlive => true; // Mantener el widget vivo entre navegaciones

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Category> _filterCategories(List<Category> categories) {
    if (_searchQuery.isEmpty) return categories;
    return categories.where((cat) =>
      cat.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      cat.description.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  List<Category> _getCurrentPageCategories(List<Category> filtered) {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(startIndex, endIndex);
  }

  void _updatePagination(int filteredLength) {
    setState(() {
      _totalPages = (filteredLength / _itemsPerPage).ceil();
      if (_currentPage >= _totalPages && _totalPages > 0) {
        _currentPage = _totalPages - 1;
      }
      if (_currentPage < 0) _currentPage = 0;
    });
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _onCategoryLongPress(String id) {
    setState(() {
      if (_selectedCategoryIds.contains(id)) {
        _selectedCategoryIds.remove(id);
      } else {
        _selectedCategoryIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCategoryIds.clear();
    });
  }

  Future<void> _deleteSelectedCategories(CategoryViewModel vm) async {
    final count = _selectedCategoryIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categorías'),
        content: Text('¿Seguro que deseas eliminar $count categorías seleccionadas? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final dashboardVM = context.read<DashboardViewModel>();
      final currentCount = dashboardVM.dashboardData?.totalCategories ?? 0;
      
      // Actualizar contador instantáneamente
      dashboardVM.updateCategoryCount(currentCount - count);
      
      for (final id in _selectedCategoryIds) {
        await vm.deleteCategory(id);
      }
      setState(() {
        _selectedCategoryIds.clear();
      });
      
      // Recargar dashboard en background
      await dashboardVM.loadDashboardData();
      
              if (mounted) {
          NotificationService.showSuccess(
            context,
            'Categorías eliminadas correctamente',
          );
        }
    }
  }

  // Agregar categoría
  Future<bool> _showAddCategoryDialog() async {
    _nameController.clear();
    _descriptionController.clear();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Categoría'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'El nombre es requerido' : null,
                  maxLength: 40,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLength: 100,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final name = _nameController.text.trim();
                  final desc = _descriptionController.text.trim();
                  final vm = context.read<CategoryViewModel>();
                  final exists = vm.categories.any((cat) => cat.name.trim().toLowerCase() == name.toLowerCase());
                  if (exists) {
                    showAppError(context, AppErrorType.duplicado, detalle: 'Ya existe una categoría con ese nombre.');
                    return;
                  }
                  final category = Category(
                    id: '',
                    name: name,
                    description: desc,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  
                  // OPTIMIZACIÓN: Cerrar diálogo inmediatamente y mostrar feedback
                  Navigator.of(context).pop(true);
                  
                  // Agregar categoría (será instantáneo en la UI)
                  final success = await vm.addCategory(category);
                  if (success && mounted) {
                    // Actualizar contador del dashboard instantáneamente
                    final currentCount = context.read<DashboardViewModel>().dashboardData?.totalCategories ?? 0;
                    context.read<DashboardViewModel>().updateCategoryCount(currentCount + 1);
                    
                    // Recargar dashboard en background (sin bloquear la UI)
                    context.read<DashboardViewModel>().loadDashboardData();
                    
                    // Mostrar notificación de éxito
                    NotificationService.showSuccess(
                      context,
                      'Categoría agregada correctamente',
                    );
                  } else if (mounted) {
                    final errorType = vm.errorType ?? AppErrorType.desconocido;
                    showAppError(context, errorType);
                  }
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  // Editar categoría
  Future<void> _showEditCategoryDialog(Category category) async {
    _nameController.text = category.name;
    _descriptionController.text = category.description;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Categoría'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'El nombre es requerido' : null,
                  maxLength: 40,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLength: 100,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final name = _nameController.text.trim();
                  final desc = _descriptionController.text.trim();
                  final vm = context.read<CategoryViewModel>();
                  final exists = vm.categories.any((cat) => cat.name.trim().toLowerCase() == name.toLowerCase() && cat.id != category.id);
                  if (exists) {
                    showAppError(context, AppErrorType.duplicado, detalle: 'Ya existe una categoría con ese nombre.');
                    return;
                  }
                  final updated = category.copyWith(name: name, description: desc, updatedAt: DateTime.now());
                  final success = await vm.updateCategory(updated);
                  if (success && mounted) {
                    Navigator.of(context).pop();
                    NotificationService.showSuccess(
                      context,
                      'Categoría actualizada correctamente',
                    );
                  } else if (mounted) {
                    final errorType = vm.errorType ?? AppErrorType.desconocido;
                    showAppError(context, errorType);
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // Eliminar categoría individual
  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Estás seguro de que deseas eliminar la categoría "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final vm = context.read<CategoryViewModel>();
      final dashboardVM = context.read<DashboardViewModel>();
      
      // Actualizar contador instantáneamente
      final currentCount = dashboardVM.dashboardData?.totalCategories ?? 0;
      dashboardVM.updateCategoryCount(currentCount - 1);
      
              final success = await vm.deleteCategory(category.id);
        if (success && mounted) {
          NotificationService.showSuccess(
            context,
            'Categoría eliminada correctamente',
          );
          _clearSelection();
        
        // Recargar dashboard en background
        dashboardVM.loadDashboardData();
      } else if (mounted) {
        // Si falló, restaurar el contador
        dashboardVM.updateCategoryCount(currentCount);
        final errorType = vm.errorType ?? AppErrorType.desconocido;
        showAppError(context, errorType);
      }
    }
  }

  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorías',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gestiona tus categorías de productos',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryStatCard(DashboardViewModel dashboardVM) {
    final dashboard = dashboardVM.dashboardData;
    if (dashboard == null) return const SizedBox.shrink();
    
    // Estadísticas calculadas
    final categoriesWithProducts = dashboard.categories.where((c) => 
      dashboard.products.any((p) => p.categoryId == c.id)
    ).length;
    final mostUsedCategory = _getMostUsedCategoryName(dashboard);
    final averageProductsPerCategory = dashboard.categories.isNotEmpty 
      ? (dashboard.products.length / dashboard.categories.length).toStringAsFixed(1)
      : '0';
    final emptyCategories = dashboard.categories.length - categoriesWithProducts;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          children: [
            // Fila principal con contador
            Row(
              children: [
                Icon(Icons.category, color: Colors.blue, size: 40),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dashboard.totalCategories}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Categorías registradas',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Estadísticas rápidas
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                        const SizedBox(width: 4),
                        Text('$categoriesWithProducts con productos', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.orange[600]),
                        const SizedBox(width: 4),
                        Text('$emptyCategories vacías', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700])),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Fila de estadísticas detalladas
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.trending_up,
                    label: 'Promedio productos',
                    value: '$averageProductsPerCategory',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.star,
                    label: 'Más usada',
                    value: mostUsedCategory,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.analytics,
                    label: 'Productos total',
                    value: '${dashboard.products.length}',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedStatsCard(DashboardViewModel dashboardVM) {
    final dashboard = dashboardVM.dashboardData;
    if (dashboard == null) return const SizedBox.shrink();

    // Calcular estadísticas
    final totalCategories = dashboard.totalCategories;
    final mostPopularCategory = _getMostUsedCategoryName(dashboard);
    final emptyCategories = dashboard.categories.where((c) => 
      !dashboard.products.any((p) => p.categoryId == c.id)
    ).length;
    final categoriesWithProducts = dashboard.categories.where((c) => 
      dashboard.products.any((p) => p.categoryId == c.id)
    ).length;

    return Column(
      children: [
        // Primera fila: 2 cards
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message: 'Número total de categorías registradas en el sistema',
                child: _buildMinimalCard(
                  icon: Icons.category,
                  title: 'Categorías Totales',
                  value: '$totalCategories',
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Tooltip(
                message: 'Categoría con mayor número de productos asignados',
                child: _buildMinimalCard(
                  icon: Icons.star,
                  title: 'Categoría Más Popular',
                  value: mostPopularCategory,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Segunda fila: 2 cards
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message: 'Categorías que tienen al menos un producto asignado',
                child: _buildMinimalCard(
                  icon: Icons.check_circle,
                  title: 'Con Productos',
                  value: '$categoriesWithProducts',
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Tooltip(
                message: 'Categorías sin productos asignados',
                child: _buildMinimalCard(
                  icon: Icons.warning,
                  title: 'Categorías Vacías',
                  value: '$emptyCategories',
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimalCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getMostUsedCategoryName(dashboard) {
    final Map<String, int> categoryCounts = {};
    for (final product in dashboard.products) {
      categoryCounts[product.categoryId] = (categoryCounts[product.categoryId] ?? 0) + 1;
    }
    if (categoryCounts.isEmpty) return '-';
    final mostUsedId = categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final cat = dashboard.categories.firstWhere(
      (c) => c.id == mostUsedId,
      orElse: () => Category(
        id: '',
        name: '-',
        description: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return cat.name;
  }

  Widget _buildBulkActionsBar(CategoryViewModel vm) {
    return Material(
      elevation: 4,
      color: Colors.red.shade700,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(8),
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.delete, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              '${_selectedCategoryIds.length} seleccionadas',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Tooltip(
              message: 'Eliminar todas las categorías seleccionadas',
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade700,
                ),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Eliminar seleccionadas'),
                onPressed: _selectedCategoryIds.isEmpty ? null : () => _deleteSelectedCategories(vm),
              ),
            ),
            const SizedBox(width: 16),
            Tooltip(
              message: 'Cancelar selección de categorías',
              child: ElevatedButton(
                onPressed: _clearSelection,
                child: const Text('Cancelar selección'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, CategoryViewModel vm, DashboardViewModel dashboardVM) {
    final dashboard = dashboardVM.dashboardData;
    final Map<String, int> categoryProductCounts = {};
    if (dashboard != null) {
      for (final product in dashboard.products) {
        categoryProductCounts[product.categoryId] = (categoryProductCounts[product.categoryId] ?? 0) + 1;
      }
    }
    if (vm.isLoading && categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No hay categorías')), 
      );
    }
    if (Responsive.isMobile(context)) {
      // Mobile: ListTile minimalista, sin Card
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = _selectedCategoryIds.contains(category.id);
          final productCount = categoryProductCounts[category.id] ?? 0;
          return ListTile(
            leading: Checkbox(
              value: selected,
              onChanged: (checked) => _onCategoryLongPress(category.id),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.list, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Text(
                  'Productos: $productCount',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 15, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  category.createdAt.toLocal().toString().split(" ")[0],
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'edit') {
                  _showEditCategoryDialog(category);
                } else if (action == 'delete') {
                  _deleteCategory(category);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
            onLongPress: () => _onCategoryLongPress(category.id),
            onTap: _selectedCategoryIds.isNotEmpty
                ? () => _onCategoryLongPress(category.id)
                : null,
          );
        },
      );
    } else {
      // Desktop: Tabla custom con encabezado fijo, filas scrollables y paginación
      final filteredCategories = _filterCategories(vm.categories);
      final totalPages = (filteredCategories.length / _itemsPerPage).ceil();
      final startIndex = _currentPage * _itemsPerPage;
      final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredCategories.length);
      final pageCategories = filteredCategories.sublist(startIndex, endIndex);
      final allSelected = _selectedCategoryIds.length == pageCategories.length && pageCategories.isNotEmpty;
      return Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(
                  height: 520,
                  child: Column(
                    children: [
                      // Encabezado fijo
                      Container(
                        color: Colors.grey[100],
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: allSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedCategoryIds.addAll(pageCategories.map((c) => c.id));
                                  } else {
                                    _selectedCategoryIds.clear();
                                  }
                                });
                              },
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            _TableHeaderCell('Nombre', flex: 2),
                            _TableHeaderCell('Descripción', flex: 3),
                            _TableHeaderCell('Productos', flex: 1),
                            _TableHeaderCell('Creada', flex: 1),
                            _TableHeaderCell('Acciones', flex: 1, align: Alignment.centerRight),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Filas con scroll
                      Expanded(
                        child: ListView.separated(
                          itemCount: pageCategories.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final category = pageCategories[index];
                            final selected = _selectedCategoryIds.contains(category.id);
                            final productCount = categoryProductCounts[category.id] ?? 0;
                            return Container(
                              color: selected ? Colors.blue.withOpacity(0.08) : null,
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: selected,
                                    onChanged: (checked) => _onCategoryLongPress(category.id),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  _TableCell(Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)), flex: 2),
                                  _TableCell(Text(category.description), flex: 3),
                                  _TableCell(Row(
                                    children: [
                                      Icon(Icons.list, size: 16, color: Colors.blue[600]),
                                      const SizedBox(width: 4),
                                      Text('$productCount', style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.w500, fontSize: 13)),
                                    ],
                                  ), flex: 1),
                                  _TableCell(Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 15, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(category.createdAt.toLocal().toString().split(" ")[0], style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                    ],
                                  ), flex: 1),
                                                                    _TableCell(
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Tooltip(
                                      message: 'Editar categoría',
                                      child: IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showEditCategoryDialog(category),
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Eliminar categoría',
                                      child: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteCategory(category),
                                      ),
                                    ),
                                  ],
                        ),
                                    flex: 1,
                                    align: Alignment.centerRight,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Controles de paginación
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Tooltip(
                          message: 'Página anterior',
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _currentPage > 0 ? _previousPage : null,
                          ),
                        ),
                        ...List.generate(totalPages, (i) => _buildPageButton(i)),
                        Tooltip(
                          message: 'Página siguiente',
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _currentPage < totalPages - 1 ? _nextPage : null,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedCategoryIds.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildBulkActionsBar(vm),
            ),
        ],
      );
    }
  }

  Widget _buildPaginationControls(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Tooltip(
              message: 'Página anterior',
              child: IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0 ? _previousPage : null,
              ),
            ),
            const SizedBox(width: 16),
            ...List.generate(totalPages, (i) => _buildPageButton(i)),
            const SizedBox(width: 16),
            Tooltip(
              message: 'Página siguiente',
              child: IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages - 1 ? _nextPage : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageButton(int page) {
    final isCurrentPage = page == _currentPage;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => _goToPage(page),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isCurrentPage ? Colors.blue.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isCurrentPage ? Colors.blue.shade600 : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Text(
            '${page + 1}',
            style: TextStyle(
              color: isCurrentPage ? Colors.white : Colors.grey[700],
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido para AutomaticKeepAliveClientMixin
    return Consumer2<CategoryViewModel, DashboardViewModel>(
      builder: (context, vm, dashboardVM, _) {
        final filteredCategories = _filterCategories(vm.categories);
        final currentPageCategories = _getCurrentPageCategories(filteredCategories);
        // Si el número de páginas cambió, actualiza la paginación después del build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updatePagination(filteredCategories.length);
        });
        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                  child: _buildPageTitle(),
                ),
                const SizedBox(height: 16),
                // Estadísticas en cards horizontales
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildAdvancedStatsCard(dashboardVM),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                              child: Row(
                          children: [
                            Tooltip(
                              message: 'Agregar nueva categoría',
                              child: IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () async {
                                  final added = await _showAddCategoryDialog();
                                  if (added) {
                                    // OPTIMIZACIÓN: Usar recarga forzada para asegurar datos frescos
                                    await context.read<CategoryViewModel>().forceReloadCategories();
                                    // Recargar dashboard en background
                                    context.read<DashboardViewModel>().loadDashboardData();
                                  }
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.green.shade50,
                                  foregroundColor: Colors.green.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Limpiar categorías duplicadas',
                              child: IconButton(
                                icon: const Icon(Icons.cleaning_services),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Limpiar Duplicados'),
                                      content: const Text(
                                        '¿Deseas limpiar automáticamente las categorías duplicadas?\n\n'
                                        'Esto eliminará las categorías con nombres idénticos, manteniendo la más antigua.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Limpiar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  
                                  if (confirmed == true) {
                                    final result = await context.read<CategoryViewModel>().cleanDuplicateCategoriesManually();
                                    if (mounted) {
                                      if (result['success'] == true) {
                                        final duplicates = result['duplicatesFound'] as int;
                                        final names = result['duplicateNames'] as List<String>;
                                        final remaining = result['remainingCategories'] as int;
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              duplicates > 0 
                                                ? '✅ Se eliminaron $duplicates categorías duplicadas. Restantes: $remaining'
                                                : '✅ No se encontraron categorías duplicadas'
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(seconds: 4),
                                          ),
                                        );
                                        
                                        // Recargar dashboard
                                        context.read<DashboardViewModel>().loadDashboardData();
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('❌ Error: ${result['error']}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.orange.shade50,
                                  foregroundColor: Colors.orange.shade700,
                                ),
                              ),
                            ),
                            // 🔧 DESARROLLO: Botón para limpieza completa
                            if (foundation.kDebugMode)
                              Tooltip(
                                message: '🔧 DESARROLLO: Limpiar TODAS las categorías duplicadas',
                                child: IconButton(
                                  icon: const Icon(Icons.cleaning_services_outlined),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('🔧 DESARROLLO: Limpieza Completa'),
                                        content: const Text(
                                          '⚠️ SOLO PARA DESARROLLO\n\n'
                                          '¿Deseas limpiar TODAS las categorías duplicadas de la base de datos completa?\n\n'
                                          'Esto analizará todas las categorías y eliminará los duplicados manteniendo la más antigua.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('🔧 Limpiar Todo'),
                                          ),
                                        ],
                                      ),
                                    );
                                    
                                    if (confirmed == true) {
                                      final result = await context.read<CategoryViewModel>().forceCleanAllDuplicates();
                                      if (mounted) {
                                        if (result['success'] == true) {
                                          final remaining = result['remainingCategories'] as int;
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '🔧 DESARROLLO: Limpieza completa ejecutada. Categorías restantes: $remaining'
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: const Duration(seconds: 4),
                                            ),
                                          );
                                          
                                          // Recargar dashboard
                                          context.read<DashboardViewModel>().loadDashboardData();
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('❌ Error: ${result['error']}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    foregroundColor: Colors.red.shade700,
                                  ),
                                ),
                              ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Buscar categorías',
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
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _updatePagination(_filterCategories(vm.categories).length);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_selectedCategoryIds.isNotEmpty)
                  _buildBulkActionsBar(vm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildCategoryList(currentPageCategories, vm, dashboardVM),
                ),
                if (Responsive.isMobile(context))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildPaginationControls(_totalPages),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
} 

// Helpers para celdas de tabla custom
class _TableHeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final Alignment align;
  
  const _TableHeaderCell(this.label, {this.flex = 1, this.align = Alignment.centerLeft, Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: align,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15),
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final Widget child;
  final int flex;
  final Alignment align;
  
  const _TableCell(this.child, {this.flex = 1, this.align = Alignment.centerLeft, Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: align,
        child: child,
      ),
    );
  }
} 