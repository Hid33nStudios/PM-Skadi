import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/skeleton_loading.dart';

class SalesChart extends StatelessWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<DashboardViewModel, Map<String, dynamic>>(
      selector: (_, vm) => {
        'sales': vm.dashboardData?.sales ?? [],
        'weekRevenue': vm.weekRevenue,
        'weekSales': vm.weekSales,
        'isLoading': vm.isLoading,
        'error': vm.error,
      },
      builder: (context, data, _) {
        if (data['isLoading'] as bool) {
          return const SkeletonLoading(height: 120, width: double.infinity, borderRadius: 12);
        }
        if (data['error'] != null) {
          return Center(
            child: Text(
              'Error: ${data['error']}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }
        final sales = data['sales'] as List;
        if (sales.isEmpty) {
          return const Center(
            child: Text('No hay datos de ventas disponibles'),
          );
        }
        // Agrupar ventas por día (últimos 7 días)
        final now = DateTime.now();
        final salesByDay = <String, double>{};
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dateKey = '${date.day}/${date.month}';
          salesByDay[dateKey] = 0.0;
        }
        for (final sale in sales) {
          final saleDate = sale.date;
          if (saleDate.isAfter(now.subtract(const Duration(days: 7)))) {
            final dateKey = '${saleDate.day}/${saleDate.month}';
            salesByDay[dateKey] = (salesByDay[dateKey] ?? 0.0) + sale.amount;
          }
        }
        final salesData = salesByDay.values.toList();
        final dates = salesByDay.keys.toList();
        final isMobile = MediaQuery.of(context).size.width < 600;
        if (isMobile) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ventas de la semana', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 8),
                Text('Total: \$${(data['weekRevenue'] as double).toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Colors.green)),
                const SizedBox(height: 8),
                Text('Cantidad: ${data['weekSales']}', style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        }
        return LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '\$${value.toInt()}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= dates.length) return const Text('');
                    return Text(
                      dates[value.toInt()],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: salesData.asMap().entries.map((entry) {
                  return FlSpot(entry.key.toDouble(), entry.value);
                }).toList(),
                isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
            minY: 0,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.surface,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    if (index >= salesData.length) return null;
                    return LineTooltipItem(
                      '\$${salesData[index].toStringAsFixed(2)}',
                      TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        );
      },
    );
  }
} 