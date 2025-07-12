import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../viewmodels/category_viewmodel.dart';
import '../widgets/responsive_form.dart';
import '../theme/responsive.dart';
import '../utils/error_cases.dart';

class CategoryManagementScreen extends StatefulWidget {
  final bool showAddForm;
  
  const CategoryManagementScreen({
    super.key,
    this.showAddForm = false,
  });

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isAddingCategory = false;

  @override
  void initState() {
    super.initState();
    print('🔄 CategoryManagementScreen: initState llamado');
    print('📊 CategoryManagementScreen: showAddForm = ${widget.showAddForm}');
    
    if (widget.showAddForm) {
      _isAddingCategory = true;
    }
    // Usar addPostFrameCallback para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔄 CategoryManagementScreen: addPostFrameCallback ejecutado');
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    print('🔄 CategoryManagementScreen: _loadCategories llamado');
    try {
      await context.read<CategoryViewModel>().loadCategories();
      print('✅ CategoryManagementScreen: _loadCategories completado');
    } catch (e) {
      print('❌ CategoryManagementScreen: Error en _loadCategories: $e');
    }
  }

  Future<void> _addCategory() async {
    if (_formKey.currentState!.validate()) {
      try {
        final category = Category(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        print('🔄 Intentando agregar categoría: ${category.name}');
        final success = await context.read<CategoryViewModel>().addCategory(category);
        
        if (success) {
          print('✅ Categoría agregada exitosamente');
          _nameController.clear();
          _descriptionController.clear();
          setState(() {
            _isAddingCategory = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Categoría agregada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          print('❌ Error al agregar categoría: ${context.read<CategoryViewModel>().error}');
          if (mounted) {
            final errorType = context.read<CategoryViewModel>().errorType ?? AppErrorType.desconocido;
            showAppError(context, errorType);
          }
        }
      } catch (e) {
        print('❌ Excepción al agregar categoría: $e');
        if (mounted) {
          final errorType = context.read<CategoryViewModel>().errorType ?? AppErrorType.desconocido;
          showAppError(context, errorType);
        }
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Estás seguro de eliminar "${category.name}"?'),
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
      try {
        final success = await context.read<CategoryViewModel>().deleteCategory(category.id);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Categoría eliminada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            final errorType = context.read<CategoryViewModel>().errorType ?? AppErrorType.desconocido;
            showAppError(context, errorType);
          }
        }
      } catch (e) {
        if (mounted) {
          final errorType = context.read<CategoryViewModel>().errorType ?? AppErrorType.desconocido;
          showAppError(context, errorType);
        }
      }
    }
  }

  void _showEditCategoryDialog(Category category) {
    final _editNameController = TextEditingController(text: category.name);
    final _editDescriptionController = TextEditingController(text: category.description);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Categoría'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _editNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                maxLength: 40,
                validator: (value) => value == null || value.trim().isEmpty ? 'El nombre es requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _editDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = _editNameController.text.trim();
                final newDesc = _editDescriptionController.text.trim();
                if (newName.isEmpty) {
                  showAppError(context, AppErrorType.campoObligatorio);
                  return;
                }
                final updatedCategory = category.copyWith(name: newName, description: newDesc);
                final viewModel = context.read<CategoryViewModel>();
                final success = await viewModel.updateCategory(updatedCategory);
                if (success) {
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Categoría actualizada correctamente'), backgroundColor: Colors.green),
                    );
                  }
                } else {
                  if (mounted) {
                    final errorType = viewModel.errorType ?? AppErrorType.desconocido;
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

  @override
  Widget build(BuildContext context) {
    print('🔄 CategoryManagementScreen: build llamado');
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isAddingCategory) ...[
              _buildAddCategoryForm(),
              const SizedBox(height: 16),
            ],
            Expanded(child: _buildCategoryList()),
          ],
        ),
      ),
    );
  }

  /// Formulario responsive para agregar categorías
  Widget _buildAddCategoryForm() {
    return ResponsiveForm(
      title: 'Nueva Categoría',
      wrapInCard: true,
      maxWidth: 600, // Ancho máximo en desktop
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Campo de nombre con icono
              ResponsiveFormField(
                label: 'Nombre de la Categoría',
                isRequired: true,
                helperText: 'Nombre descriptivo para la categoría',
                prefix: Icon(Icons.category, color: Colors.amber),
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Aceites, Frenos, Filtros',
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
              
              // Campo de descripción
              ResponsiveFormField(
                label: 'Descripción',
                helperText: 'Descripción opcional de la categoría',
                prefix: Icon(Icons.description, color: Colors.blue),
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Describe qué tipo de productos incluye esta categoría',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: Responsive.isMobile(context) ? 2 : 3,
                ),
              ),
              
              // Botones de acción responsive
              ResponsiveButtonRow(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _nameController.clear();
                      _descriptionController.clear();
                      setState(() {
                        _isAddingCategory = false;
                      });
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.isMobile(context) ? 20 : 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addCategory,
                    icon: const Icon(Icons.add),
                    label: Text(Responsive.isMobile(context) 
                        ? 'Agregar' 
                        : 'Agregar Categoría'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.isMobile(context) ? 20 : 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Lista responsive de categorías
  Widget _buildCategoryList() {
    final viewModel = context.watch<CategoryViewModel>();
    final categories = List<Category>.from(viewModel.categories)..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (viewModel.isLoading && categories.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    if (viewModel.error != null) {
      return Center(child: Text(viewModel.error!));
    }
    if (categories.isEmpty) {
      return Center(child: Text('No hay categorías registradas.'));
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryItem(category);
            },
          ),
        ),
        if (viewModel.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton(
              onPressed: viewModel.isLoadingMore ? null : () => viewModel.loadMoreCategories(),
              child: viewModel.isLoadingMore
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Cargar más'),
            ),
          ),
      ],
    );
  }

  /// Card individual para cada categoría
  Widget _buildCategoryItem(Category category) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: const Icon(Icons.category, color: Colors.amber),
        title: Text(category.name),
        subtitle: Text(category.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Editar',
              onPressed: () => _showEditCategoryDialog(category),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red[400],
                size: Responsive.isMobile(context) ? 20 : 24,
              ),
              onPressed: () => _deleteCategory(category),
              tooltip: 'Eliminar categoría',
            ),
          ],
        ),
      ),
    );
  }
} 