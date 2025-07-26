import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_service.dart';
import '../services/firestore_optimized_service.dart';
import '../theme/responsive.dart';
import '../viewmodels/sync_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel_optimized.dart';
import '../widgets/sync_diagnostic_widget.dart';
import '../widgets/performance_metrics_widget.dart';
import 'dashboard_screen.dart';
import 'product_list_screen.dart';
import 'movement_history_screen.dart';
import 'sales_screen.dart';
import '../widgets/custom_snackbar.dart';
import '../router/app_router.dart';
import '../utils/error_cases.dart';
import '../viewmodels/product_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  final Widget? child; // Nuevo parámetro para recibir el contenido
  
  const HomeScreen({super.key, this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _authService = AuthService();
  String _username = '';
  bool _isDrawerOpen = false;
  bool _isSidebarExpanded = false;
  bool _showPerformanceMetrics = false;

  // Servicio optimizado
  late final FirestoreOptimizedService _firestoreOptimizedService;
  late final DashboardViewModelOptimized _dashboardViewModelOptimized;

  // Menú items con iconos y colores personalizados
  static List<MenuItemData> _menuItems = [
    MenuItemData(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Inicio',
      color: Colors.yellow,
    ),
    MenuItemData(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Productos',
      color: Colors.orange,
    ),
    MenuItemData(
      icon: Icons.category_outlined,
      selectedIcon: Icons.category,
      label: 'Categorías',
      color: Colors.amber,
    ),
    MenuItemData(
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      label: 'Movimientos',
      color: Color(0xFFFBC02D), // amarillo.shade700
    ),
    MenuItemData(
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
      label: 'Ventas',
      color: Color(0xFFF57C00), // orange.shade700
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeOptimizedServices();
    _loadUserProfile();
    _updateSelectedIndexFromRoute();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndexFromRoute();
  }

  void _updateSelectedIndexFromRoute() {
    try {
      final location = GoRouterState.of(context).uri.path;
      int newIndex = _selectedIndex;
      
      switch (location) {
        case '/':
          newIndex = 0; // Dashboard
          break;
        case '/products':
          newIndex = 1; // Productos
          break;
        case '/categories':
          newIndex = 2; // Categorías
          break;
        case '/movements':
          newIndex = 3; // Movimientos
          break;
        case '/sales':
          newIndex = 4; // Ventas
          break;
      }
      
      if (newIndex != _selectedIndex) {
        setState(() {
          _selectedIndex = newIndex;
        });
      }
    } catch (e) {
      // Ignorar errores de contexto desactivado
      print('⚠️ Error al actualizar índice de navegación: $e');
    }
  }

  void _navigateToProducts() {
    setState(() {
      _selectedIndex = 1; // Productos
    });
  }

  // Método público para actualizar el índice desde otras pantallas
  void updateSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _initializeOptimizedServices() {
    _firestoreOptimizedService = FirestoreOptimizedService();
    _dashboardViewModelOptimized = DashboardViewModelOptimized(
      firestoreService: _firestoreOptimizedService,
    );
  }

  @override
  void dispose() {
    _firestoreOptimizedService.dispose();
    _dashboardViewModelOptimized.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userProfile = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _username = userProfile.get('username') ?? '';
        });
      }
    } catch (e) {
      // Error loading user profile
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        CustomSnackBar.showInfo(
          context: context,
          message: 'Sesión cerrada exitosamente',
        );
        context.go('/login');
      }
    } catch (e) {
      showAppError(context, AppErrorType.desconocido);
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _showPerformanceMetrics = false; // Ocultar métricas al cambiar de página
    });
    
    // Navegar usando el router
    switch (index) {
      case 0: // Dashboard
        context.go('/');
        break;
      case 1: // Productos
        context.go('/products');
        break;
      case 2: // Categorías
        context.go('/categories');
        break;
      case 3: // Movimientos
        context.go('/movements');
        break;
      case 4: // Ventas
        context.go('/sales');
        break;
    }
  }

  void _handleSettingsMenu(BuildContext context, String value) {
    switch (value) {
      case 'performance_metrics':
        setState(() {
          _showPerformanceMetrics = !_showPerformanceMetrics;
        });
        break;
      case 'force_sync':
        _forceSync(context);
        break;
      case 'app_info':
        _showAppInfo(context);
        break;
    }
  }

  void _forceSync(BuildContext context) async {
    try {
      await _firestoreOptimizedService.forceSync();
      if (context.mounted) {
        CustomSnackBar.showInfo(
          context: context,
          message: 'Sincronización completada',
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppError(context, AppErrorType.sincronizacion);
      }
    }
  }

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stockcito - Planeta Motos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Versión: 2.0.0'),
            const SizedBox(height: 8),
            const Text('Sistema de Gestión de Inventario'),
            const SizedBox(height: 16),
            const Text(
              'Funcionalidades:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Firebase optimizado con cache inteligente'),
            const Text('• Operaciones batch automáticas'),
            const Text('• Métricas de performance en tiempo real'),
            const Text('• Gestión de productos'),
            const Text('• Control de stock'),
            const Text('• Reportes y análisis'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: !isMobile, // Solo centrar en desktop
      title: isMobile 
        ? Row(
            children: [
              Image.asset(
                'assets/images/logo.webp',
                height: 32, // Más pequeño para móvil
                semanticLabel: 'Logo Planeta Motos',
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Planeta Motos',
                  style: GoogleFonts.poppins(
                    fontSize: 18, // Más pequeño para móvil
                    color: Colors.yellow,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Botón de búsqueda global al lado del texto
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                tooltip: 'Buscar producto o categoría',
                onPressed: _showGlobalSearchModal,
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.webp',
                height: 48,
                semanticLabel: 'Logo Planeta Motos',
              ),
              const SizedBox(width: 12),
              Text(
                'Planeta Motos',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  color: Colors.yellow,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 16),
              // Botón de búsqueda global al lado del texto
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                tooltip: 'Buscar producto o categoría',
                onPressed: _showGlobalSearchModal,
              ),
            ],
          ),
      actions: [
        // Widget de sincronización optimizado
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: SyncDiagnosticWidget(
            size: isMobile ? 12.0 : 16.0,
          ),
        ),
        
        // Menú de configuración optimizado
        PopupMenuButton<String>(
          icon: Icon(
            Icons.settings, 
            color: Colors.white,
            size: isMobile ? 20 : 24, // Más pequeño en móvil
          ),
          onSelected: (value) => _handleSettingsMenu(context, value),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'performance_metrics',
              child: Row(
                children: [
                  Icon(
                    _showPerformanceMetrics ? Icons.analytics : Icons.analytics_outlined,
                    color: _showPerformanceMetrics ? Colors.green : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showPerformanceMetrics ? 'Ocultar Métricas' : 'Métricas de Performance',
                    style: TextStyle(
                      color: _showPerformanceMetrics ? Colors.green : null,
                      fontWeight: _showPerformanceMetrics ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'force_sync',
              child: Row(
                children: [
                  const Icon(Icons.sync_alt),
                  const SizedBox(width: 8),
                  const Text('Sincronizar Ahora'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'app_info',
              child: Row(
                children: [
                  const Icon(Icons.info),
                  const SizedBox(width: 8),
                  const Text('Información de la App'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Sidebar(
      username: _username,
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
      onSignOut: _signOut,
      menuItems: _menuItems,
    );
  }

  Widget _buildCompactSidebar() {
    return CompactSidebar(
      username: _username,
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
      onSignOut: _signOut,
      menuItems: _menuItems,
      isSidebarExpanded: _isSidebarExpanded,
      onExpandChanged: (expanded) => setState(() => _isSidebarExpanded = expanded),
    );
  }

  Widget _buildMobileDrawer() {
    return Container(
      width: 280,
      height: double.infinity,
      child: _buildSidebar(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Widget de métricas de performance (solo si está activado)
        if (_showPerformanceMetrics)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: PerformanceMetricsWidget(
              viewModel: _dashboardViewModelOptimized,
            ),
          ),
        // Contenido principal
        Expanded(
          child: widget.child ?? const DashboardScreen(showAppBar: false),
        ),
      ],
    );
  }

  // --- NUEVO: Modal de búsqueda global tipo command palette ---
  void _showGlobalSearchModal() async {
    final productVM = context.read<ProductViewModel>();
    final categoryVM = context.read<CategoryViewModel>();
    if (productVM.products.isEmpty) {
      await productVM.loadInitialProducts();
    }
    if (categoryVM.categories.isEmpty) {
      await categoryVM.loadCategories();
    }
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _GlobalSearchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _buildContent(),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.grey.shade900,
              ],
            ),
            border: Border(
              top: BorderSide(color: Colors.yellow.withOpacity(0.3), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: _menuItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = _selectedIndex == index;
                  
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onItemTapped(index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? item.color.withOpacity(0.2) 
                            : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected 
                            ? Border.all(color: item.color, width: 1)
                            : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected 
                                  ? item.color.withOpacity(0.3) 
                                  : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                color: isSelected ? item.color : Colors.grey.shade400,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Flexible(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: isSelected ? item.color : Colors.grey.shade400,
                                  fontSize: 9,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Row(
          children: [
            _buildCompactSidebar(),
            const VerticalDivider(thickness: 1, width: 1, color: Colors.grey),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      );
    }
  }
}

class MenuItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color color;

  MenuItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.color,
  });
}

class HomeScreenProvider extends InheritedWidget {
  final Function(int) navigateToIndex;

  const HomeScreenProvider({
    Key? key,
    required this.navigateToIndex,
    required Widget child,
  }) : super(key: key, child: child);

  static HomeScreenProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HomeScreenProvider>();
  }

  @override
  bool updateShouldNotify(HomeScreenProvider oldWidget) {
    return navigateToIndex != oldWidget.navigateToIndex;
  }
} 

class Sidebar extends StatelessWidget {
  final String username;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onSignOut;
  final List<MenuItemData> menuItems;

  const Sidebar({
    Key? key,
    required this.username,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onSignOut,
    required this.menuItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                bottom: BorderSide(color: Colors.yellow.withOpacity(0.3), width: 2),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.yellow.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.yellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.yellow,
                          size: 28,
                          semanticLabel: 'Avatar de usuario',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        username,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.yellow, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Usuario Conectado',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Menú
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = selectedIndex == index;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onItemTapped(index),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? item.color.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected 
                            ? Border.all(color: item.color, width: 2)
                            : Border.all(color: Colors.grey.shade700, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? item.color : Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                color: isSelected ? Colors.black : Colors.grey.shade300,
                                size: 20,
                                semanticLabel: item.label,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item.label,
                                style: GoogleFonts.poppins(
                                  color: isSelected ? item.color : Colors.grey.shade300,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Footer
          SidebarFooter(onSignOut: onSignOut),
        ],
      ),
    );
  }
}

class CompactSidebar extends StatelessWidget {
  final String username;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onSignOut;
  final List<MenuItemData> menuItems;
  final bool isSidebarExpanded;
  final ValueChanged<bool> onExpandChanged;

  const CompactSidebar({
    Key? key,
    required this.username,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onSignOut,
    required this.menuItems,
    required this.isSidebarExpanded,
    required this.onExpandChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!Responsive.isMobile(context)) {
          onExpandChanged(true);
        }
      },
      onExit: (_) {
        if (!Responsive.isMobile(context)) {
          onExpandChanged(false);
        }
      },
      child: Container(
        width: isSidebarExpanded ? 280.0 : 80.0,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            right: BorderSide(color: Colors.yellow.withOpacity(0.3), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              height: 70,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  bottom: BorderSide(color: Colors.yellow.withOpacity(0.3), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.yellow,
                      size: 20,
                      semanticLabel: 'Avatar de usuario',
                    ),
                  ),
                  if (isSidebarExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        username,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Menú
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final isSelected = selectedIndex == index;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onItemTapped(index),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSidebarExpanded ? 16 : 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? item.color.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected 
                              ? Border.all(color: item.color, width: 1)
                              : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                color: isSelected ? item.color : Colors.grey.shade400,
                                size: 20,
                                semanticLabel: item.label,
                              ),
                              if (isSidebarExpanded) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: GoogleFonts.poppins(
                                      color: isSelected ? item.color : Colors.grey.shade300,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Footer
            SidebarFooter(onSignOut: onSignOut, isCompact: true, isSidebarExpanded: isSidebarExpanded),
          ],
        ),
      ),
    );
  }
}

class SidebarFooter extends StatelessWidget {
  final VoidCallback onSignOut;
  final bool isCompact;
  final bool isSidebarExpanded;

  const SidebarFooter({
    Key? key,
    required this.onSignOut,
    this.isCompact = false,
    this.isSidebarExpanded = true,
  }) : super(key: key);

  String _getAppVersion() {
    // Por ahora retornamos la versión hardcodeada hasta que se instale package_info_plus
    return '4.0.0';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isCompact || isSidebarExpanded) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.yellow,
                  size: 16,
                  semanticLabel: 'Información de versión',
                ),
                const SizedBox(width: 8),
                Text(
                  'Alpha v${_getAppVersion()}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              children: const [
                Text(
                  'Desarrollado por',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Hid33nStudios',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'para Planeta Motos',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(
          height: 70,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSignOut,
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.shade600,
                      width: 1.5,
                    ),
                  ),
                  child: (isCompact && !isSidebarExpanded)
                      ? const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 24,
                          semanticLabel: 'Cerrar Sesión',
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 16,
                              semanticLabel: 'Cerrar Sesión',
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cerrar Sesión',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 

// --- NUEVO: Widget del modal de búsqueda global ---
class _GlobalSearchDialog extends StatefulWidget {
  @override
  State<_GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<_GlobalSearchDialog> {
  String _query = '';
  List<dynamic> _results = [];
  bool _loading = false;

  // Función para normalizar tildes y minúsculas
  String _normalize(String input) {
    return input
      .toLowerCase()
      .replaceAll(RegExp(r'[áàäâã]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöôõ]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll(RegExp(r'ñ'), 'n');
  }

  void _onQueryChanged(String value) async {
    setState(() {
      _query = value;
      _loading = true;
    });
    final productVM = context.read<ProductViewModel>();
    final categoryVM = context.read<CategoryViewModel>();
    final q = _normalize(_query.trim());
    // Coincidencias que empiezan por la consulta (nombre o descripción)
    final productsStart = productVM.products.where((p) {
      final name = _normalize(p.name);
      final desc = _normalize(p.description ?? '');
      return name.startsWith(q) || desc.startsWith(q);
    }).toList();
    final categoriesStart = categoryVM.categories.where((c) {
      final name = _normalize(c.name);
      final desc = _normalize(c.description);
      return name.startsWith(q) || desc.startsWith(q);
    }).toList();
    // Coincidencias que contienen la consulta (pero no empiezan por ella)
    final productsContains = productVM.products.where((p) {
      final name = _normalize(p.name);
      final desc = _normalize(p.description ?? '');
      return !name.startsWith(q) && (name.contains(q) || desc.contains(q));
    }).toList();
    final categoriesContains = categoryVM.categories.where((c) {
      final name = _normalize(c.name);
      final desc = _normalize(c.description);
      return !name.startsWith(q) && (name.contains(q) || desc.contains(q));
    }).toList();
    // Ordenar alfabéticamente cada grupo
    productsStart.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    productsContains.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    categoriesStart.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    categoriesContains.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    setState(() {
      _results = [
        ...categoriesStart.map((c) => {'type': 'category', 'item': c}),
        ...categoriesContains.map((c) => {'type': 'category', 'item': c}),
        ...productsStart.map((p) => {'type': 'product', 'item': p}),
        ...productsContains.map((p) => {'type': 'product', 'item': p}),
      ];
      _loading = false;
    });
  }

  void _onResultTap(dynamic result) {
    Navigator.of(context).pop();
    if (result['type'] == 'product') {
      // Navegar a edición de producto
      final product = result['item'];
      context.go('/products/${product.id}/edit');
    } else if (result['type'] == 'category') {
      // Navegar a gestión de categorías y resaltar/editar
      final category = result['item'];
      context.go('/categories?edit=${category.id}');
    } else if (result['type'] == 'create_product') {
      context.go('/products/add');
    } else if (result['type'] == 'create_category') {
      context.go('/categories?add=1');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black.withOpacity(0.2), // Más sutil
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 32.0), // Menos separación
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 420,
                decoration: BoxDecoration(
                  color: Colors.grey[100], // Fondo más claro y neutro
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cuadro de búsqueda minimalista
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              autofocus: true,
                              style: const TextStyle(color: Colors.black, fontSize: 17),
                              decoration: const InputDecoration(
                                hintText: 'Buscar producto o categoría...',
                                hintStyle: TextStyle(color: Colors.black38),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                              onChanged: _onQueryChanged,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black38),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Cerrar',
                          ),
                        ],
                      ),
                    ),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (!_loading && _query.isNotEmpty && _results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        child: Column(
                          children: [
                            Text('No se encontraron resultados para "$_query"', style: const TextStyle(color: Colors.black54)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _onResultTap({'type': 'create_product'}),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Crear producto'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: () => _onResultTap({'type': 'create_category'}),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Crear categoría'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (!_loading && _results.isNotEmpty)
                      Flexible(
                        child: SizedBox(
                          height: 280,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => Divider(color: Colors.grey[200], height: 1),
                            itemBuilder: (context, index) {
                              final result = _results[index];
                              final isCategory = result['type'] == 'category';
                              final item = result['item'];
                              return ListTile(
                                leading: Icon(isCategory ? Icons.category : Icons.inventory_2, color: isCategory ? Colors.orange : Colors.blue),
                                title: Text(item.name, style: const TextStyle(color: Colors.black)),
                                subtitle: Text(isCategory ? 'Categoría' : 'Producto', style: const TextStyle(color: Colors.black38)),
                                onTap: () => _onResultTap(result),
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                minLeadingWidth: 28,
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 