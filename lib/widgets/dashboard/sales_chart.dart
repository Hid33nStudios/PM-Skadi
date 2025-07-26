import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/skeleton_loading.dart';
import '../../utils/validators.dart';

class SalesChart extends StatefulWidget {
  const SalesChart({super.key});

  @override
  State<SalesChart> createState() => _SalesChartState();
}

class _SalesChartState extends State<SalesChart> {
  bool showByProduct = false;

  @override
  Widget build(BuildContext context) {
    return Selector<DashboardViewModel, List>(
      selector: (_, vm) => vm.dashboardData?.sales ?? [],
      builder: (context, sales, _) {
        if (sales.isEmpty) {
          final isMobile = MediaQuery.of(context).size.width < 600;
          return Container(
            alignment: Alignment.center,
            height: isMobile ? 80 : 120,
            child: Text('No hay ventas para mostrar', style: TextStyle(color: Colors.grey)),
          );
        }
        final now = DateTime.now();
        final salesByDay = <String, double>{};
        final productSalesByDay = <String, Map<String, double>>{}; // fecha -> {producto: total}
        final productNames = <String>{};
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dateKey = '${date.day}/${date.month}';
          salesByDay[dateKey] = 0.0;
          productSalesByDay[dateKey] = {};
        }
        for (final sale in sales) {
          final saleDate = sale.date;
          if (saleDate.isAfter(now.subtract(const Duration(days: 7)))) {
            final dateKey = '${saleDate.day}/${saleDate.month}';
            // Modo total
            final total = sale.total ?? 0.0;
            salesByDay[dateKey] = (salesByDay[dateKey] ?? 0.0) + total;
            // Modo productos
            if (sale.items != null && sale.items.isNotEmpty) {
              for (final item in sale.items) {
                final name = item.productName ?? 'Producto';
                productNames.add(name);
                final cantidad = (item.quantity is int) ? item.quantity.toDouble() : (item.quantity is num) ? (item.quantity as num).toDouble() : 0.0;
                productSalesByDay[dateKey]![name] = (productSalesByDay[dateKey]![name] ?? 0.0) + cantidad;
              }
            }
          }
        }
        final salesData = salesByDay.values.toList();
        final dates = salesByDay.keys.toList();
        final isMobile = MediaQuery.of(context).size.width < 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Total'),
                Switch(
                  value: showByProduct,
                  onChanged: (value) => setState(() => showByProduct = value),
                ),
                const Text('Por producto'),
              ],
            ),
            const SizedBox(height: 8),
            if (isMobile)
              SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: showByProduct
                      ? _buildStackedLineChart(productSalesByDay, productNames.toList(), dates, context)
                      : _buildTotalLineChart(salesData, dates, context),
                ),
              ),
            if (!isMobile)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: showByProduct
                      ? _buildStackedLineChart(productSalesByDay, productNames.toList(), dates, context)
                      : _buildTotalLineChart(salesData, dates, context),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTotalLineChart(List<double> salesData, List<String> dates, BuildContext context) {
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
                  formatPrice(value),
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                  formatPrice(salesData[index]),
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
  }

  Widget _buildStackedLineChart(Map<String, Map<String, double>> productSalesByDay, List<String> productNames, List<String> dates, BuildContext context) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.brown,
      Colors.cyan,
      Colors.indigo,
      Colors.teal,
      Colors.pink,
    ];
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
                  formatPrice(value),
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
          for (int i = 0; i < productNames.length; i++)
            LineChartBarData(
              spots: [
                for (int j = 0; j < dates.length; j++)
                  FlSpot(
                    j.toDouble(),
                    (productSalesByDay[dates[j]] != null && productSalesByDay[dates[j]]![productNames[i]] != null)
                      ? productSalesByDay[dates[j]]![productNames[i]]!
                      : 0.0,
                  ),
              ],
              isCurved: true,
              color: colors[i % colors.length],
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
        ],
        minY: 0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.surface,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= dates.length) return null;
                final productIndex = spot.barIndex;
                final productName = productNames[productIndex];
                final cantidad = spot.y;
                return LineTooltipItem(
                  '$productName\n${formatPrice(cantidad)}',
                  TextStyle(
                    color: colors[productIndex % colors.length],
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, Map<String, double> salesByDay, Set<String> productNames, bool showByProduct) {
    final dates = salesByDay.keys.toList();
    final salesData = salesByDay.values.toList();
    if (showByProduct) {
      // Construir el mapa de ventas por producto por día
      final productSalesByDay = <String, Map<String, double>>{};
      for (final date in dates) {
        productSalesByDay[date] = {};
      }
      // Aquí deberías reconstruir el productSalesByDay como en build
      // Pero como ya lo tienes en build, puedes pasarlo como argumento si lo prefieres
      // Por simplicidad, solo muestro el gráfico vacío aquí
      return _buildStackedLineChart(productSalesByDay, productNames.toList(), dates, context);
    } else {
      return _buildTotalLineChart(salesData, dates, context);
    }
  }
} 