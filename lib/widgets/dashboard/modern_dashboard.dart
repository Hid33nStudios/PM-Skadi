import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../theme/responsive.dart';
import '../../screens/home_screen.dart';
import 'dashboard_card.dart';
import 'sales_chart.dart';
import 'category_distribution.dart';
import 'quick_actions.dart';
import 'recent_activity.dart';
import 'stock_status.dart';
import 'sales_summary.dart';
import '../skeleton_loading.dart';

class ModernDashboard extends StatefulWidget {
  const ModernDashboard({super.key});

  @override
  State<ModernDashboard> createState() => _ModernDashboardState();
}

class _ModernDashboardState extends State<ModernDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Iniciar animaciones con delay para lazy loading
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return _buildSkeletonLoading();
        }

        if (viewModel.error != null) {
          return _buildErrorState(viewModel.error!);
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildDashboardContent(),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          _buildHeaderSkeleton(),
          const SizedBox(height: 48),
          
          // Stats cards skeleton
          _buildStatsSkeleton(),
          const SizedBox(height: 48),
          
          // Grid skeleton
          _buildGridSkeleton(),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLoading(
          height: 32,
          width: 300,
          borderRadius: 8,
        ),
        const SizedBox(height: 8),
        SkeletonLoading(
          height: 20,
          width: 200,
          borderRadius: 4,
        ),
      ],
    );
  }

  Widget _buildStatsSkeleton() {
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 3 ? 24 : 0),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoading(
                  width: 40,
                  height: 40,
                  borderRadius: 8,
                ),
                const SizedBox(height: 16),
                SkeletonLoading(
                  height: 24,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                SkeletonLoading(
                  height: 16,
                  width: 80,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const SkeletonCard(),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar el dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.read<DashboardViewModel>().loadDashboardData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 16.0 : 24.0;
    final spacing = isMobile ? 24.0 : 32.0;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: spacing),
          _buildStatsCards(),
          SizedBox(height: spacing),
          _buildQuickActions(),
          SizedBox(height: spacing),
          _buildDashboardGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isMobile = Responsive.isMobile(context);
    final titleFontSize = isMobile ? 24.0 : 32.0;
    final subtitleFontSize = isMobile ? 16.0 : 18.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Resumen de tu negocio',
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, _) {
        final data = viewModel.dashboardData;
        
        if (data == null) {
          return const SizedBox.shrink();
        }
        
        // Calcular productos con stock bajo
        final lowStockProducts = data.products.where((p) => p.stock <= p.minStock).length;
        
        final isMobile = Responsive.isMobile(context);
        
        if (isMobile) {
          // Layout móvil: 2x2 grid
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.trending_up,
                      iconColor: Colors.green,
                      title: 'Ventas',
                      value: '${data.totalSales}',
                      subtitle: 'Total',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.attach_money,
                      iconColor: Colors.blue,
                      title: 'Ingresos',
                      value: '\$${data.totalRevenue.toStringAsFixed(2)}',
                      subtitle: 'Total',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.inventory,
                      iconColor: Colors.orange,
                      title: 'Productos',
                      value: '${data.totalProducts}',
                      subtitle: 'Inventario',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.warning,
                      iconColor: Colors.red,
                      title: 'Stock Bajo',
                      value: '$lowStockProducts',
                      subtitle: 'Productos',
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Layout desktop: fila horizontal
          return Row(
            children: [
              _buildStatCard(
                icon: Icons.trending_up,
                iconColor: Colors.green,
                title: 'Ventas Totales',
                value: '${data.totalSales}',
                subtitle: 'Transacciones',
              ),
              const SizedBox(width: 24),
              _buildStatCard(
                icon: Icons.attach_money,
                iconColor: Colors.blue,
                title: 'Ingresos',
                value: '\$${data.totalRevenue.toStringAsFixed(2)}',
                subtitle: 'Total acumulado',
              ),
              const SizedBox(width: 24),
              _buildStatCard(
                icon: Icons.inventory,
                iconColor: Colors.orange,
                title: 'Productos',
                value: '${data.totalProducts}',
                subtitle: 'En inventario',
              ),
              const SizedBox(width: 24),
              _buildStatCard(
                icon: Icons.warning,
                iconColor: Colors.red,
                title: 'Stock Bajo',
                value: '$lowStockProducts',
                subtitle: 'Productos',
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 16.0 : 24.0;
    final iconSize = isMobile ? 20.0 : 24.0;
    final valueFontSize = isMobile ? 24.0 : 32.0;
    final titleFontSize = isMobile ? 14.0 : 16.0;
    final subtitleFontSize = isMobile ? 12.0 : 14.0;
    
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: iconSize,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final homeScreenProvider = HomeScreenProvider.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.flash_on,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        QuickActions(onNavigateToIndex: homeScreenProvider?.navigateToIndex),
      ],
    );
  }

  Widget _buildDashboardGrid() {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    
    // Ajustar grid según el tamaño de pantalla
    final crossAxisCount = isMobile ? 1 : isTablet ? 2 : 3;
    final childAspectRatio = isMobile ? 1.0 : isTablet ? 1.1 : 1.2;
    final spacing = isMobile ? 16.0 : isTablet ? 20.0 : 24.0;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      children: [
        _buildGridCard(
          title: 'Ventas de la Semana',
          icon: Icons.trending_up,
          iconColor: Colors.green,
          child: const SalesChart(),
        ),
        _buildGridCard(
          title: 'Distribución por Categoría',
          icon: Icons.pie_chart,
          iconColor: Colors.blue,
          child: const CategoryDistribution(),
        ),
        _buildGridCard(
          title: 'Actividad Reciente',
          icon: Icons.history,
          iconColor: Colors.orange,
          child: const RecentActivity(),
        ),
        _buildGridCard(
          title: 'Productos con Bajo Stock',
          icon: Icons.warning,
          iconColor: Colors.red,
          child: const StockStatus(),
        ),
        _buildGridCard(
          title: 'Resumen de Ventas',
          icon: Icons.analytics,
          iconColor: Colors.purple,
          child: Consumer<DashboardViewModel>(
            builder: (context, viewModel, _) => SalesSummary(
              dashboardViewModel: viewModel,
            ),
          ),
        ),
        _buildGridCard(
          title: 'Tendencias',
          icon: Icons.show_chart,
          iconColor: Colors.teal,
          child: const Center(
            child: Text(
              'Gráfico de tendencias\n(Próximamente)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 16.0 : 20.0;
    final iconSize = isMobile ? 18.0 : 20.0;
    final titleFontSize = isMobile ? 14.0 : 16.0;
    
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: iconSize,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
} 