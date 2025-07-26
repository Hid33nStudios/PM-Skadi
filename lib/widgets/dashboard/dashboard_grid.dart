import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/responsive_layout.dart';
import '../../theme/responsive.dart';
import '../../screens/home_screen.dart';
import 'dashboard_card.dart';
import 'sales_chart.dart';
import 'category_distribution.dart';
import 'quick_actions.dart';
import 'recent_activity.dart';
import 'stock_status.dart';
import 'sales_summary.dart';
import 'performance_test_widget.dart';

class DashboardGrid extends StatelessWidget {
  const DashboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Responsive.responsiveWidget(
      context: context,
      builder: (context, constraints) {
        if (Responsive.isMobile(context)) {
          return _buildMobileLayout(context);
        } else if (Responsive.isTablet(context)) {
          return _buildTabletLayout(context);
        } else {
          return _buildDesktopLayout(context);
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildDashboardItems(context, isMobile: true),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final items = _buildDashboardItems(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => items[index],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calcular el ancho de los widgets basado en el tamaño de la pantalla
    final widgetWidth = screenWidth > 1400 ? 400.0 : 
                       screenWidth > 1200 ? 380.0 : 
                       screenWidth > 1000 ? 350.0 : 
                       screenWidth > 800 ? 320.0 : 260.0;
    
    // Calcular el padding horizontal basado en el tamaño de la pantalla
    final horizontalPadding = screenWidth > 1400 ? 48.0 : 
                             screenWidth > 1200 ? 32.0 : 
                             screenWidth > 1000 ? 24.0 : 
                             screenWidth > 800 ? 16.0 : 8.0;
    
    // Calcular la altura de los widgets basada en el tamaño de pantalla
    final widgetHeight = screenWidth > 1200 ? 400.0 : 
                        screenWidth > 1000 ? 380.0 : 
                        screenWidth > 800 ? 360.0 : 340.0;
    final headerFontSize = screenWidth > 1000 ? 18.0 : 15.0;
    final iconSize = screenWidth > 1000 ? 20.0 : 16.0;
    final rowPadding = screenWidth > 800 ? 16.0 : 8.0;
    final maxListItems = screenWidth > 800 ? 5 : 3;
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fila 1: Ingresos (SalesSummary) ocupando todo el ancho
          Padding(
            padding: EdgeInsets.only(bottom: rowPadding * 2),
            child: _buildSalesSummaryCard(context),
          ),
          // Fila 2: Quick Actions ocupando todo el ancho
          Padding(
            padding: EdgeInsets.only(bottom: rowPadding * 2),
            child: _buildQuickActionsCard(context),
          ),
          // Fila 3: Grid con el resto de widgets
          Wrap(
            spacing: screenWidth > 1200 ? 32 : screenWidth > 800 ? 20 : 8,
            runSpacing: screenWidth > 1200 ? 32 : screenWidth > 800 ? 20 : 8,
            alignment: WrapAlignment.center,
            children: [
              // Ventas de la Semana
              Container(
                width: widgetWidth,
                constraints: BoxConstraints(maxHeight: widgetHeight + 120),
                child: ClipRect(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.green, size: iconSize),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ventas de la Semana',
                              style: TextStyle(
                                fontSize: headerFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        height: widgetHeight,
                        child: _buildSalesChartCard(context),
                      ),
                    ],
                  ),
                ),
              ),
              // Distribución por Categoría
              Container(
                width: widgetWidth,
                constraints: BoxConstraints(maxHeight: widgetHeight + 120),
                child: ClipRect(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pie_chart, color: Colors.blue, size: iconSize),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Distribución por Categoría',
                              style: TextStyle(
                                fontSize: headerFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        height: widgetHeight,
                        child: _buildCategoryDistributionCard(context),
                      ),
                    ],
                  ),
                ),
              ),
              // Actividad Reciente
              SizedBox(
                width: widgetWidth,
                child: DashboardCard(
                  title: 'Actividad Reciente',
                  icon: Icons.history,
                  iconColor: Colors.orange,
                  child: RecentActivity(),
                ),
              ),
              // Productos con Bajo Stock
              Container(
                width: widgetWidth,
                constraints: BoxConstraints(maxHeight: widgetHeight + 120),
                child: ClipRect(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: iconSize),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Productos con Bajo Stock',
                              style: TextStyle(
                                fontSize: headerFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        height: widgetHeight,
                        child: _buildStockStatusCard(context),
                      ),
                    ],
                  ),
                ),
              ),
              // Prueba de Performance
              Container(
                width: widgetWidth,
                constraints: BoxConstraints(maxHeight: widgetHeight + 120),
                child: ClipRect(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.speed, color: Colors.purple, size: iconSize),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Prueba de Performance',
                              style: TextStyle(
                                fontSize: headerFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        height: widgetHeight,
                        child: _buildPerformanceTestCard(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card minimalista y moderna solo para web
  Widget _minimalCard(BuildContext context, Widget child) {
    return Container(
      width: 380,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: child,
    );
  }

  // Cards específicos para desktop con mejor diseño
  Widget _buildSalesSummaryCard(BuildContext context) {
    final dashboardVM = Provider.of<DashboardViewModel>(context, listen: false);
    return SalesSummary(dashboardViewModel: dashboardVM);
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    final homeScreenProvider = HomeScreenProvider.of(context);
    return QuickActions(onNavigateToIndex: homeScreenProvider?.navigateToIndex);
  }

  Widget _buildSalesChartCard(BuildContext context) {
    return SalesChart();
  }

  Widget _buildCategoryDistributionCard(BuildContext context) {
    return CategoryDistribution();
  }

  Widget _buildRecentActivityCard(BuildContext context) {
    return RecentActivity();
  }

  Widget _buildStockStatusCard(BuildContext context) {
    return StockStatus();
  }

  Widget _buildPerformanceTestCard(BuildContext context) {
    return PerformanceTestWidget();
  }

  List<Widget> _buildDashboardItems(BuildContext context, {bool isMobile = false}) {
    final dashboardVM = Provider.of<DashboardViewModel>(context, listen: false);
    final homeScreenProvider = HomeScreenProvider.of(context);
    final spacing = isMobile ? 8.0 : Responsive.getResponsiveSpacing(context);

    final items = [
      SalesSummary(dashboardViewModel: dashboardVM),
      QuickActions(onNavigateToIndex: homeScreenProvider?.navigateToIndex),
      DashboardCard(
        title: 'Actividad Reciente',
        icon: Icons.history,
        iconColor: Colors.orange,
        child: RecentActivity(),
      ),
      DashboardCard(
        title: 'Ventas de la Semana',
        icon: Icons.trending_up,
        iconColor: Colors.green,
        child: SalesChart(),
      ),
      DashboardCard(
        title: 'Productos con Bajo Stock',
        icon: Icons.warning,
        iconColor: Colors.red,
        child: StockStatus(),
      ),
      DashboardCard(
        title: 'Distribución por Categoría',
        icon: Icons.pie_chart,
        iconColor: Colors.blue,
        child: CategoryDistribution(),
      ),
      DashboardCard(
        title: 'Prueba de Performance',
        icon: Icons.speed,
        iconColor: Colors.purple,
        child: PerformanceTestWidget(),
      ),
    ];

    if (isMobile) {
      // En móviles, añadir espaciado entre items
      return items.expand((item) => [
        item,
        SizedBox(height: spacing),
      ]).take(items.length * 2 - 1).toList();
    }

    return items;
  }
} 