import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../models/category.dart';

class CategoryDistribution extends StatelessWidget {
  const CategoryDistribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, dashboardVM, _) {
        if (dashboardVM.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (dashboardVM.error != null) {
          return Center(
            child: Text(
              'Error: ${dashboardVM.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final data = dashboardVM.dashboardData;
        if (data == null) {
          return const Center(child: Text('No hay datos disponibles'));
        }

        // Agrupar productos por categoría
        final categoryCounts = <String, int>{};
        for (var product in data.products) {
          String categoryName = 'Sin categoría';
          
          if (product.categoryId.isNotEmpty) {
            try {
              final category = data.categories.firstWhere(
                (c) => c.id == product.categoryId,
                orElse: () => Category(
                  id: 'default',
                  name: 'Sin categoría',
                  description: '',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              categoryName = category.name;
            } catch (e) {
              categoryName = 'Sin categoría';
            }
          }
          
          categoryCounts[categoryName] = (categoryCounts[categoryName] ?? 0) + 1;
        }

        return ListView.builder(
          itemCount: categoryCounts.length,
          itemBuilder: (context, index) {
            final entry = categoryCounts.entries.elementAt(index);
            return ListTile(
              title: Text(entry.key),
              trailing: Text(
                '${entry.value} productos',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          },
        );
      },
    );
  }
} 