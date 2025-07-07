import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/add_product_screen.dart';
import '../screens/add_sale_screen.dart';
import '../screens/category_management_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/sales_history_screen.dart';
import '../screens/register_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/edit_product_screen.dart';
import '../screens/migration_screen.dart';
import '../screens/new_sale_screen.dart';
import '../screens/new_product_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/movement_history_screen.dart';
import '../screens/sales_screen.dart';
import '../services/auth_service.dart';

/// Configuración principal del router de la aplicación
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    
    // Middleware de autenticación
    redirect: (BuildContext context, GoRouterState state) {
      final authService = AuthService();
      final isLoggedIn = authService.currentUser != null;
      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';
      final isMigrationRoute = state.matchedLocation == '/migration';
      
      // Si no está logueado y no está en login/register/migration, redirigir a login
      if (!isLoggedIn && !isLoginRoute && !isRegisterRoute && !isMigrationRoute) {
        return '/login';
      }
      
      // Si está logueado y está en login/register, redirigir al dashboard
      if (isLoggedIn && (isLoginRoute || isRegisterRoute)) {
        return '/';
      }
      
      // No redirigir
      return null;
    },
    
    // Rutas de la aplicación
    routes: [
      // Rutas de autenticación (fuera del HomeScreen)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Migración (fuera del HomeScreen)
      GoRoute(
        path: '/migration',
        name: 'migration',
        builder: (context, state) => const MigrationScreen(),
      ),
      
      // HomeScreen como contenedor principal con rutas anidadas
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          // Dashboard principal
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(showAppBar: false),
          ),
          
          // Productos
          GoRoute(
            path: '/products',
            name: 'products',
            builder: (context, state) => const ProductListScreen(),
          ),
          
          GoRoute(
            path: '/products/add',
            name: 'add-product',
            builder: (context, state) => const AddProductScreen(),
          ),
          
          GoRoute(
            path: '/products/:id',
            name: 'product-detail',
            builder: (context, state) {
              final productId = state.pathParameters['id']!;
              return ProductDetailScreen(productId: productId);
            },
          ),
          
          GoRoute(
            path: '/products/:id/edit',
            name: 'edit-product',
            builder: (context, state) {
              final productId = state.pathParameters['id']!;
              return EditProductScreen(productId: productId);
            },
          ),
          
          // Ventas
          GoRoute(
            path: '/sales',
            name: 'sales',
            builder: (context, state) => const SalesScreen(),
          ),
          
          GoRoute(
            path: '/sales/add',
            name: 'add-sale',
            builder: (context, state) => const AddSaleScreen(),
          ),
          
          GoRoute(
            path: '/sales/new',
            name: 'new-sale',
            builder: (context, state) => const NewSaleScreen(),
          ),
          
          // Productos adicionales
          GoRoute(
            path: '/products/new',
            name: 'new-product',
            builder: (context, state) => const NewProductScreen(),
          ),
          
          // Escáner de códigos de barras
          GoRoute(
            path: '/barcode-scanner',
            name: 'barcode-scanner',
            builder: (context, state) => const BarcodeScannerScreen(),
          ),
          
          // Historial de movimientos
          GoRoute(
            path: '/movements',
            name: 'movements',
            builder: (context, state) => const MovementHistoryScreen(),
          ),
          
          // Categorías
          GoRoute(
            path: '/categories',
            name: 'categories',
            builder: (context, state) {
              final showAddForm = state.uri.queryParameters['add'] == '1';
              return CategoryManagementScreen(showAddForm: showAddForm);
            },
          ),
          
          // Analytics
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
        ],
      ),
    ],
    
    // Manejo de errores
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Página no encontrada'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error 404',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'La página "${state.matchedLocation}" no existe',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Volver al Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Extensiones para facilitar la navegación
extension GoRouterExtension on BuildContext {
  /// Navegar al dashboard
  void goToDashboard() => go('/');
  
  /// Navegar a productos
  void goToProducts() => go('/products');
  
  /// Navegar a agregar producto
  void goToAddProduct() => go('/products/add');
  
  /// Navegar a detalles de producto
  void goToProductDetail(String productId) => go('/products/$productId');
  
  /// Navegar a editar producto
  void goToEditProduct(String productId) => go('/products/$productId/edit');
  
  /// Navegar a ventas
  void goToSales() => go('/sales');
  
  /// Navegar a agregar venta
  void goToAddSale() => go('/sales/add');
  
  /// Navegar a nueva venta
  void goToNewSale() => go('/sales/new');
  
  /// Navegar a nuevo producto
  void goToNewProduct() => go('/products/new');
  
  /// Navegar a escáner de códigos de barras
  void goToBarcodeScanner() => go('/barcode-scanner');
  
  /// Navegar a historial de movimientos
  void goToMovements() => go('/movements');
  
  /// Navegar a categorías
  void goToCategories() => go('/categories');
  
  /// Navegar a categorías con formulario de añadir abierto
  void goToAddCategory() => go('/categories?add=1');
  
  /// Navegar a analytics
  void goToAnalytics() => go('/analytics');
  
  /// Navegar a login
  void goToLogin() => go('/login');
  
  /// Navegar a registro
  void goToRegister() => go('/register');
  
  /// Navegar a migración
  void goToMigration() => go('/migration');
} 