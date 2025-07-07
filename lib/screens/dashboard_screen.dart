import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/sale_viewmodel.dart';
import '../widgets/dashboard/dashboard_grid.dart';
import '../widgets/dashboard/modern_dashboard.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/responsive_form.dart';
import '../theme/responsive.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';
import '../router/app_router.dart';

class DashboardScreen extends StatefulWidget {
  final bool showAppBar;
  
  const DashboardScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Usar addPostFrameCallback para evitar llamar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
      _setupSaleCallback();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clearSaleCallback();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Recargar datos cuando la app vuelve a estar activa
    if (state == AppLifecycleState.resumed) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    final dashboardViewModel = context.read<DashboardViewModel>();
    await dashboardViewModel.loadDashboardData();
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.goToLogin();
      }
    } catch (e) {
      if (mounted) {
        context.showError(e);
      }
    }
  }

  void _setupSaleCallback() {
    final saleViewModel = context.read<SaleViewModel>();
    saleViewModel.setOnSaleAddedCallback(() {
      print('🔄 Dashboard: Recibida notificación de venta agregada, recargando datos...');
      _loadDashboardData();
    });
  }

  void _clearSaleCallback() {
    final saleViewModel = context.read<SaleViewModel>();
    saleViewModel.clearOnSaleAddedCallback();
  }

  @override
  Widget build(BuildContext context) {
    return widget.showAppBar
        ? Scaffold(
            appBar: _buildResponsiveAppBar(),
            body: _buildResponsiveBody(),
          )
        : _buildResponsiveBody();
  }

  /// AppBar responsive
  AppBar _buildResponsiveAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey.shade800,
      title: Text(
        'Dashboard',
        style: TextStyle(
          fontSize: Responsive.getResponsiveFontSize(context, 24),
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade900,
        ),
      ),
      actions: [
        // Widget de estado de sincronización responsive
        if (!Responsive.isDesktop(context))
          Padding(
            padding: EdgeInsets.only(right: Responsive.getResponsiveSpacing(context)),
            child: const SyncStatusWidget(),
          ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.grey.shade600,
            ),
            onPressed: _signOut,
            tooltip: 'Cerrar sesión',
            iconSize: Responsive.isMobile(context) ? 24 : 28,
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Cuerpo principal responsive
  Widget _buildResponsiveBody() {
    return Container(
      color: Responsive.isDesktop(context) ? Colors.grey.shade50 : Colors.white,
      child: RefreshIndicator(
        onRefresh: () => context.read<DashboardViewModel>().loadDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: widget.showAppBar 
              ? Responsive.isDesktop(context) 
                  ? EdgeInsets.zero 
                  : Responsive.getResponsivePadding(context)
              : EdgeInsets.zero,
          child: Column(
            children: [
              // Sección de estado de sincronización responsive (solo móvil/tablet)
              if (!Responsive.isDesktop(context)) _buildSyncStatusSection(),
              
              // Contenido principal del dashboard
              _buildDashboardContent(),
            ],
          ),
        ),
      ),
    );
  }

  /// Sección de estado de sincronización responsive
  Widget _buildSyncStatusSection() {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.getResponsiveSpacing(context)),
      child: Column(
        children: [
          // Widget de estado offline
          const SyncOfflineIndicator(),
          
          // Widget de progreso de sincronización
          const SyncProgressWidget(),
        ],
      ),
    );
  }

  /// Contenido principal del dashboard responsive
  Widget _buildDashboardContent() {
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return _buildLoadingState();
        }

        if (viewModel.error != null) {
          return _buildErrorState(viewModel.error!);
        }

        return _buildDashboardGrid();
      },
    );
  }

  /// Estado de carga responsive
  Widget _buildLoadingState() {
    // Para web, usar skeleton loading en lugar de circular progress
    if (Responsive.isDesktop(context)) {
      return const ModernDashboard();
    }
    
    return Center(
      child: Padding(
        padding: Responsive.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: Responsive.isMobile(context) ? 3 : 4,
            ),
            SizedBox(height: Responsive.getResponsiveSpacing(context)),
            Text(
              'Cargando dashboard...',
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(context, 16),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Estado de error responsive
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: Responsive.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: Responsive.isMobile(context) ? 48 : 64,
              color: Colors.red[300],
            ),
            SizedBox(height: Responsive.getResponsiveSpacing(context)),
            Text(
              error,
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(context, 16),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.getResponsiveSpacing(context)),
            ElevatedButton.icon(
              onPressed: () => context.read<DashboardViewModel>().loadDashboardData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Grid del dashboard responsive
  Widget _buildDashboardGrid() {
    // Usar ModernDashboard para todos los tamaños de pantalla
    return const ModernDashboard();
  }
} 