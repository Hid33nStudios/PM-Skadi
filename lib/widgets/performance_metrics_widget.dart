import 'package:flutter/material.dart';
import '../viewmodels/dashboard_viewmodel_optimized.dart';

class PerformanceMetricsWidget extends StatelessWidget {
  final DashboardViewModelOptimized viewModel;

  const PerformanceMetricsWidget({
    Key? key,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final metrics = viewModel.currentMetrics;
        final performance = viewModel.performanceMetrics;

        if (metrics == null && performance == null) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Métricas de Performance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () => viewModel.resetMetrics(),
                      tooltip: 'Resetear métricas',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (metrics != null) _buildMetricsSection(context, metrics),
                if (performance != null) _buildPerformanceSection(context, performance),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricsSection(BuildContext context, Map<String, dynamic> metrics) {
    final operations = metrics['operations'] as Map<String, dynamic>?;
    final cache = metrics['cache'] as Map<String, dynamic>?;
    final batch = metrics['batch'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operaciones',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Lecturas',
                '${operations?['readCount'] ?? 0}',
                Icons.visibility,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                context,
                'Escrituras',
                '${operations?['writeCount'] ?? 0}',
                Icons.edit,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                context,
                'Batches',
                '${operations?['batchWriteCount'] ?? 0}',
                Icons.batch_prediction,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (cache != null) _buildCacheSection(context, cache),
        if (batch != null) _buildBatchSection(context, batch),
      ],
    );
  }

  Widget _buildCacheSection(BuildContext context, Map<String, dynamic> cache) {
    final hitRate = cache['hitRate'] as double? ?? 0.0;
    final size = cache['size'] as int? ?? 0;
    final hits = cache['hitCount'] as int? ?? 0;
    final misses = cache['missCount'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cache',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Tamaño',
                '$size',
                Icons.storage,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                context,
                'Hit Rate',
                '${(hitRate * 100).toStringAsFixed(1)}%',
                Icons.trending_up,
                hitRate > 0.7 ? Colors.green : hitRate > 0.4 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                context,
                'Hits/Misses',
                '$hits/$misses',
                Icons.speed,
                Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBatchSection(BuildContext context, Map<String, dynamic> batch) {
    final pending = batch['pendingOperations'] as int? ?? 0;
    final active = batch['hasActiveBatch'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Batch Operations',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Pendientes',
                '$pending',
                Icons.pending,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                context,
                'Activo',
                active ? 'Sí' : 'No',
                active ? Icons.play_circle : Icons.pause_circle,
                active ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(BuildContext context, Map<String, dynamic> performance) {
    final cache = performance['cache'] as Map<String, dynamic>?;
    final operations = performance['operations'] as Map<String, dynamic>?;
    final batch = performance['batch'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Performance en Tiempo Real',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (cache != null) _buildPerformanceCacheSection(context, cache),
        if (operations != null) _buildPerformanceOperationsSection(context, operations),
        if (batch != null) _buildPerformanceBatchSection(context, batch),
      ],
    );
  }

  Widget _buildPerformanceCacheSection(BuildContext context, Map<String, dynamic> cache) {
    final efficiency = cache['efficiency'] as double? ?? 0.0;
    final hitRate = cache['hitRate'] as double? ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            'Eficiencia',
            '${(efficiency * 100).toStringAsFixed(1)}%',
            Icons.auto_awesome,
            efficiency > 0.8 ? Colors.green : efficiency > 0.6 ? Colors.orange : Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            'Hit Rate',
            '${(hitRate * 100).toStringAsFixed(1)}%',
            Icons.trending_up,
            hitRate > 0.7 ? Colors.green : hitRate > 0.4 ? Colors.orange : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceOperationsSection(BuildContext context, Map<String, dynamic> operations) {
    final total = operations['total'] as int? ?? 0;
    final reads = operations['reads'] as int? ?? 0;
    final writes = operations['writes'] as int? ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            'Total Ops',
            '$total',
            Icons.analytics,
            Colors.indigo,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            'Lecturas',
            '$reads',
            Icons.visibility,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            'Escrituras',
            '$writes',
            Icons.edit,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceBatchSection(BuildContext context, Map<String, dynamic> batch) {
    final pending = batch['pending'] as int? ?? 0;
    final active = batch['active'] as bool? ?? false;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            'Batch Pendiente',
            '$pending',
            Icons.pending,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            'Batch Activo',
            active ? 'Sí' : 'No',
            active ? Icons.play_circle : Icons.pause_circle,
            active ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 