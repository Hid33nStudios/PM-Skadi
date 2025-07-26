import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_optimized_service.dart';
import '../../viewmodels/dashboard_viewmodel_optimized.dart';
import '../performance_metrics_widget.dart';

class PerformanceTestWidget extends StatefulWidget {
  const PerformanceTestWidget({Key? key}) : super(key: key);

  @override
  State<PerformanceTestWidget> createState() => _PerformanceTestWidgetState();
}

class _PerformanceTestWidgetState extends State<PerformanceTestWidget> {
  bool _showMetrics = false;
  late DashboardViewModelOptimized _viewModel;

  @override
  void initState() {
    super.initState();
    _initializeViewModel();
  }

  void _initializeViewModel() {
    final firestoreService = context.read<FirestoreOptimizedService>();
    _viewModel = DashboardViewModelOptimized(
      firestoreService: firestoreService,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Prueba de Performance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _showMetrics,
                  onChanged: (value) {
                    setState(() {
                      _showMetrics = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_showMetrics) ...[
              PerformanceMetricsWidget(viewModel: _viewModel),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await _viewModel.initializeDashboard();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Dashboard inicializado')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      icon: Icon(Icons.play_arrow),
                      label: Text('Inicializar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await _viewModel.refreshDashboard();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Dashboard recargado')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Recargar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _viewModel.resetMetrics();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Métricas reseteadas')),
                        );
                      },
                      icon: Icon(Icons.restart_alt),
                      label: Text('Resetear'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await _viewModel.forceSync();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sincronización forzada')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      icon: Icon(Icons.sync),
                      label: Text('Sincronizar'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Activa el switch para ver las métricas de performance del servicio optimizado de Firebase.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
} 