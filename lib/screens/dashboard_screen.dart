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
import '../utils/error_cases.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_initializer.dart';
import '../viewmodels/sync_viewmodel.dart';

class DashboardScreen extends StatefulWidget {
  final bool showAppBar;
  
  const DashboardScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  final _authService = AuthService();
  
  // Guardar referencias a los ViewModels para evitar acceder al contexto en dispose
  DashboardViewModel? _dashboardViewModel;
  SaleViewModel? _saleViewModel;

  // Nuevo: Para evitar recargas infinitas
  String? _lastUserId;
  bool _lastSyncDone = false;
  bool _hasInitialData = false;
  
  // Implementar AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Solo cargar datos una vez al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupViewModels();
      _loadDashboardDataIfNeeded();
      
      // Agregar listener para cambios de autenticación
      final authViewModel = context.read<AuthViewModel>();
      authViewModel.addListener(_onAuthStateChanged);
    });
  }
  
  void _onAuthStateChanged() {
    if (mounted) {
      final authViewModel = context.read<AuthViewModel>();
      if (authViewModel.isAuthenticated && !_hasInitialData) {
        print('🔄 Dashboard: Usuario autenticado, cargando datos...');
        _loadDashboardDataIfNeeded();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Solo configurar ViewModels si no están configurados
    if (_dashboardViewModel == null || _saleViewModel == null) {
      _setupViewModels();
    }
    // NO recargar datos aquí - solo en initState
  }
  
  void _setupViewModels() {
    if (_dashboardViewModel == null) {
      _dashboardViewModel = context.read<DashboardViewModel>();
    }
    if (_saleViewModel == null) {
      _saleViewModel = context.read<SaleViewModel>();
      _setupSaleCallback();
    }
  }
  
  void _loadDashboardDataIfNeeded() {
    // Solo cargar datos si hay usuario autenticado
    final authViewModel = context.read<AuthViewModel>();
    if (authViewModel.isAuthenticated && 
        _dashboardViewModel?.dashboardData == null && 
        !_dashboardViewModel!.isLoading && 
        !_hasInitialData) {
      print('🔄 Dashboard: Cargando datos iniciales...');
      _loadDashboardData();
      _hasInitialData = true;
    } else if (!authViewModel.isAuthenticated) {
      print('⚠️  Dashboard: No hay usuario autenticado, esperando...');
    }
  }

  @override
  void dispose() {
    _clearSaleCallback();
    // Remover listener de auth
    if (mounted) {
      final authViewModel = context.read<AuthViewModel>();
      authViewModel.removeListener(_onAuthStateChanged);
    }
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    // Verificar que el widget sigue montado antes de acceder al contexto
    if (!mounted) return;
    
    // Usar la referencia guardada en lugar de acceder al contexto
    if (_dashboardViewModel != null) {
      await _dashboardViewModel!.loadDashboardData();
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.goToLogin();
      }
    } catch (e) {
      if (mounted) {
        final dashboardViewModel = _dashboardViewModel;
        showAppError(context, AppErrorType.desconocido);
      }
    }
  }

  void _setupSaleCallback() {
    // Verificar que el widget sigue montado
    if (!mounted || _saleViewModel == null) return;
    
    _saleViewModel!.setOnSaleAddedCallback(() {
      // Verificar que el widget sigue montado antes de ejecutar el callback
      if (mounted) {
        print('🔄 Dashboard: Recibida notificación de venta agregada, recargando datos...');
        _loadDashboardData();
      }
    });
  }
  
  // Método público para recargar datos cuando sea necesario
  void reloadDashboardData() {
    if (mounted && _dashboardViewModel != null) {
      print('🔄 Dashboard: Recarga manual solicitada...');
      _dashboardViewModel!.clearData();
      _dashboardViewModel!.loadDashboardData();
    }
  }

  void _clearSaleCallback() {
    // Usar la referencia guardada en lugar de acceder al contexto
    if (_saleViewModel != null) {
      _saleViewModel!.clearOnSaleAddedCallback();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por AutomaticKeepAliveClientMixin
    return ValueListenableBuilder<bool>(
      valueListenable: AppInitializer.isInitializedNotifier,
      builder: (context, isInitialized, _) {
        if (!isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Consumer3<AuthViewModel, DashboardViewModel, SyncViewModel>(
          builder: (context, authViewModel, dashboardViewModel, syncViewModel, child) {
            // Mostrar loading mientras se verifica autenticación
            if (authViewModel.isAuthLoading) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Verificando autenticación...'),
                    ],
                  ),
                ),
              );
            }
            
            // Si no está autenticado, mostrar mensaje claro
            if (!authViewModel.isAuthenticated) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No autenticado',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Inicia sesión para continuar'),
                    ],
                  ),
                ),
              );
            }
            
            // Mostrar loading mientras sincroniza
            if (!syncViewModel.isInitialSyncDone) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Sincronizando datos iniciales...'),
                    ],
                  ),
                ),
              );
            }
            return widget.showAppBar
                ? Scaffold(
                    appBar: _buildResponsiveAppBar(),
                    body: _buildResponsiveBody(),
                  )
                : _buildResponsiveBody();
          },
        );
      },
    );
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
        onRefresh: () async {
          if (_dashboardViewModel != null) {
            await _dashboardViewModel!.loadDashboardData();
          }
        },
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
              onPressed: () {
                if (_dashboardViewModel != null) {
                  _dashboardViewModel!.loadDashboardData();
                }
              },
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