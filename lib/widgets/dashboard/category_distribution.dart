import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../models/category.dart';
import '../../widgets/skeleton_loading.dart';

class CategoryDistribution extends StatelessWidget {
  const CategoryDistribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<DashboardViewModel, Map<String, int>>(
      selector: (_, vm) => vm.categoryCounts,
      builder: (context, categoryCounts, _) {
        if (categoryCounts.isEmpty) {
          final isMobile = MediaQuery.of(context).size.width < 600;
          return Container(
            alignment: Alignment.center,
            height: isMobile ? 80 : 120,
            child: Text('No hay datos de categorías.', style: TextStyle(color: Colors.grey)),
          );
        }
        final isMobile = MediaQuery.of(context).size.width < 600;
        if (isMobile) {
          final total = categoryCounts.values.fold<int>(0, (sum, v) => sum + v);
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Distribución por categoría', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Total de productos: $total', style: const TextStyle(fontSize: 18, color: Colors.blue)),
                const SizedBox(height: 8),
                Text('Categorías: ${categoryCounts.length}', style: const TextStyle(fontSize: 16)),
                SizedBox(height: 80),
              ],
            ),
          );
        }
        // Versión web/desktop: lista de categorías y cantidad de productos expandible
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox.expand(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: categoryCounts.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 15)),
                      Text('${entry.value} productos', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryDistributionChart extends StatelessWidget {
  final Map<String, int> categoryCounts;

  const _CategoryDistributionChart({Key? key, required this.categoryCounts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mostrar solo resumen en móviles para optimizar rendimiento
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      final total = categoryCounts.values.fold<int>(0, (sum, v) => sum + v);
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Distribución por categoría', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total de productos: $total', style: const TextStyle(fontSize: 18, color: Colors.blue)),
            const SizedBox(height: 8),
            Text('Categorías: ${categoryCounts.length}', style: const TextStyle(fontSize: 16)),
            SizedBox(height: 80),
          ],
        ),
      );
    }

    // Limitar a las primeras 10 categorías
    int maxItems = 10;
    bool showAll = false;
    if (categoryCounts.length <= maxItems) showAll = true;
    final entries = categoryCounts.entries.toList();
    final visibleEntries = showAll ? entries : entries.take(maxItems).toList();

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            itemCount: visibleEntries.length,
            itemBuilder: (context, index) {
              final entry = visibleEntries[index];
              return ListTile(
                title: Text(entry.key),
                trailing: Text(
                  '${entry.value} productos',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            },
          ),
        ),
        if (!showAll)
          Center(
            child: ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Todas las categorías'),
                  content: SizedBox(
                    width: 400,
                    height: 400,
                    child: ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return ListTile(
                          title: Text(entry.key),
                          trailing: Text(
                            '${entry.value} productos',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ),
              child: const Text('Ver más'),
            ),
          ),
      ],
    );
  }
} 