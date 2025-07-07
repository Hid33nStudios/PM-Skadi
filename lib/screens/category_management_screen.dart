import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../viewmodels/category_viewmodel.dart';
import '../widgets/responsive_form.dart';
import '../theme/responsive.dart';

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al agregar categoría: ${context.read<CategoryViewModel>().error ?? 'Error desconocido'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Excepción al agregar categoría: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
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
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
            Expanded(child: _buildCategoriesList()),
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
  Widget _buildCategoriesList() {
    return Consumer<CategoryViewModel>(
      builder: (context, categoryVM, child) {
        print('🔄 CategoryManagementScreen: Consumer builder - isLoading: ${categoryVM.isLoading}, error: ${categoryVM.error}, categories: ${categoryVM.categories.length}');
        
        if (categoryVM.isLoading) {
          print('🔄 CategoryManagementScreen: Mostrando CircularProgressIndicator');
          return const Center(child: CircularProgressIndicator());
        }

        if (categoryVM.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, 
                     size: Responsive.isMobile(context) ? 48 : 64, 
                     color: Colors.red[300]),
                SizedBox(height: Responsive.getResponsiveSpacing(context)),
                Text(
                  categoryVM.error!, 
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(context, 16),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.getResponsiveSpacing(context)),
                ElevatedButton(
                  onPressed: _loadCategories,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (categoryVM.categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined, 
                  size: Responsive.isMobile(context) ? 48 : 64, 
                  color: Colors.grey,
                ),
                SizedBox(height: Responsive.getResponsiveSpacing(context)),
                Text(
                  'No hay categorías registradas',
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(context, 18),
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: Responsive.getResponsiveSpacing(context) / 2),
                Text(
                  'Presiona + para agregar la primera categoría',
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(context, 14),
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Layout responsive para la lista
        if (Responsive.isDesktop(context)) {
          // En desktop: Grid de 2 columnas para mejor aprovechamiento del espacio
          return GridView.builder(
            padding: EdgeInsets.all(Responsive.getResponsiveSpacing(context)),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: Responsive.getResponsiveSpacing(context),
              crossAxisSpacing: Responsive.getResponsiveSpacing(context),
              childAspectRatio: 3.5,
            ),
            itemCount: categoryVM.categories.length,
            itemBuilder: (context, index) {
              final category = categoryVM.categories[index];
              return _buildCategoryCard(category);
            },
          );
        } else {
          // En móvil/tablet: Lista vertical
          return ListView.builder(
            padding: EdgeInsets.all(Responsive.getResponsiveSpacing(context)),
            itemCount: categoryVM.categories.length,
            itemBuilder: (context, index) {
              final category = categoryVM.categories[index];
              return Container(
                margin: EdgeInsets.only(
                  bottom: Responsive.getResponsiveSpacing(context),
                ),
                child: _buildCategoryCard(category),
              );
            },
          );
        }
      },
    );
  }

  /// Card individual para cada categoría
  Widget _buildCategoryCard(Category category) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(Responsive.getResponsiveSpacing(context)),
        leading: CircleAvatar(
          backgroundColor: Colors.amber.withOpacity(0.2),
          child: Icon(
            Icons.category,
            color: Colors.amber[700],
            size: Responsive.isMobile(context) ? 20 : 24,
          ),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Responsive.getResponsiveFontSize(context, 16),
          ),
        ),
        subtitle: category.description?.isNotEmpty == true 
            ? Text(
                category.description!,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(context, 14),
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : Text(
                'Sin descripción',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(context, 14),
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Colors.red[400],
            size: Responsive.isMobile(context) ? 20 : 24,
          ),
          onPressed: () => _deleteCategory(category),
          tooltip: 'Eliminar categoría',
        ),
      ),
    );
  }
} 