import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/sale.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import 'dashboard_card.dart';

class SalesSummary extends StatelessWidget {
  final DashboardViewModel dashboardViewModel;

  const SalesSummary({super.key, required this.dashboardViewModel});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, dashboardVM, _) {
        if (dashboardVM.isLoading) {
          return const _SalesSummarySkeleton();
        }

        if (dashboardVM.error != null) {
          return DashboardCard(
            title: 'Resumen de Ventas',
            child: Center(child: Text(dashboardVM.error!)),
          );
        }

        final sales = dashboardVM.dashboardData?.sales ?? [];
        final totalRevenue = dashboardVM.dashboardData?.totalRevenue ?? 0.0;
        
        return _SalesSummaryContent(
          sales: sales,
          totalRevenue: totalRevenue,
          dashboardViewModel: dashboardViewModel,
        );
      },
    );
  }
}

class _SalesSummaryContent extends StatelessWidget {
  final List<Sale> sales;
  final double totalRevenue;
  final DashboardViewModel dashboardViewModel;

  const _SalesSummaryContent({
    required this.sales,
    required this.totalRevenue,
    required this.dashboardViewModel,
  });

  @override
  Widget build(BuildContext context) {
    final todaySales = _calculateTodaySales(sales);
    final weekSales = _calculateWeekSales(sales);
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return DashboardCard(
      title: 'Resumen de Ventas',
      icon: Icons.bar_chart,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSalesMetric(context, 'Hoy', todaySales, currencyFormat, Colors.blue),
                  const SizedBox(height: 12),
                  _buildSalesMetric(context, 'Semana', weekSales, currencyFormat, Colors.orange),
                  const SizedBox(height: 12),
                  _buildSalesMetric(context, 'Total', totalRevenue, currencyFormat, Colors.green),
                ],
              ),
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildSalesMetric(context, 'Hoy', todaySales, currencyFormat, Colors.blue)),
              Expanded(child: _buildSalesMetric(context, 'Semana', weekSales, currencyFormat, Colors.orange)),
              Expanded(child: _buildSalesMetric(context, 'Total', totalRevenue, currencyFormat, Colors.green)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSalesMetric(BuildContext context, String title, double value, NumberFormat format, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Text(
          format.format(value),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  double _calculateTodaySales(List<Sale> sales) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return sales
        .where((s) => s.date.isAfter(today))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double _calculateWeekSales(List<Sale> sales) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return sales
        .where((s) => s.date.isAfter(startOfWeek))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Layout para desktop
  Widget _buildDesktopLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumen de Ventas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  'Hoy',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Estadísticas principales
          Row(
            children: [
              Expanded(
                child: _buildEnhancedStatCard(
                  context,
                  'Ventas Totales',
                  '\$${dashboardViewModel.dashboardData?.totalRevenue.toStringAsFixed(2) ?? '0.00'}',
                  Icons.attach_money,
                  Colors.green,
                  '+12.5%',
                  true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEnhancedStatCard(
                  context,
                  'Productos Vendidos',
                  dashboardViewModel.dashboardData?.totalSales.toString() ?? '0',
                  Icons.inventory,
                  Colors.blue,
                  '+8.2%',
                  true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEnhancedStatCard(
                  context,
                  'Total Productos',
                  dashboardViewModel.dashboardData?.totalProducts.toString() ?? '0',
                  Icons.receipt,
                  Colors.orange,
                  '+15.3%',
                  true,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Gráfico de tendencia
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.blue.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tendencia de Ventas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Crecimiento constante esta semana',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+12.5%',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card de estadística mejorado para web
  Widget _buildEnhancedStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.05),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesSummarySkeleton extends StatelessWidget {
  const _SalesSummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Resumen de Ventas',
      child: LayoutBuilder(
        builder: (context, constraints) {
           if (constraints.maxWidth < 600) {
            return Column(
              children: List.generate(3, (index) => const _MetricSkeleton(isMobile: true)),
            );
           }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (index) => const _MetricSkeleton()),
          );
        },
      ),
    );
  }
}

class _MetricSkeleton extends StatelessWidget {
  final bool isMobile;
  const _MetricSkeleton({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final skeleton = Column(
      children: [
        Container(width: 80, height: 18, color: Colors.grey[800]),
        const SizedBox(height: 8),
        Container(width: 120, height: 24, color: Colors.grey[700]),
      ],
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: skeleton,
      );
    }
    return skeleton;
  }
} 