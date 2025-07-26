import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/firestore_data_service.dart';
import 'services/barcode_scanner_service.dart';
import 'services/firestore_optimized_service.dart';
import 'services/sync_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/product_viewmodel.dart';
import 'viewmodels/category_viewmodel.dart';
import 'viewmodels/movement_viewmodel.dart';
import 'viewmodels/sale_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/sync_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';

import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'router/app_router.dart';
import 'widgets/app_initializer.dart';
import 'widgets/safe_build_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeBuildWrapper(
      child: MultiProvider(
      providers: [
        // Servicios base
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(AuthService()),
        ),
        // TODO: FirestoreDataService aún necesario para CategoryViewModel, MovementViewModel, SaleViewModel y DashboardViewModel
        // TODO: Migrar gradualmente a FirestoreOptimizedService
        Provider<FirestoreDataService>(
          create: (_) => FirestoreDataService(
            firestoreService: FirestoreService(AuthService()),
            auth: FirebaseAuth.instance,
          ),
        ),
        Provider<BarcodeScannerService>(
          create: (_) => BarcodeScannerService(),
        ),
        Provider<SyncService>(
          create: (context) => SyncService(
            FirebaseFirestore.instance,
            FirebaseAuth.instance,
            context.read<FirestoreDataService>(),
          ),
        ),
        Provider<FirestoreOptimizedService>(
          create: (_) => FirestoreOptimizedService(),
        ),
        
        // Theme Provider
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        
        // ViewModels con FirestoreOptimizedService
        ChangeNotifierProxyProvider2<FirestoreOptimizedService, AuthService, ProductViewModel>(
          create: (context) => ProductViewModel(
            context.read<FirestoreOptimizedService>(),
            context.read<AuthService>(),
          ),
          update: (context, firestoreOptimizedService, authService, previous) {
            final productVM = ProductViewModel(
              firestoreOptimizedService,
              authService,
            );
            // TODO: Establecer referencia al DashboardViewModel cuando esté disponible
            return productVM;
          },
        ),
        
        // Cambiado a FirestoreOptimizedService para categorías
        ChangeNotifierProxyProvider2<FirestoreOptimizedService, AuthService, CategoryViewModel>(
          create: (context) => CategoryViewModel(
            context.read<FirestoreOptimizedService>(),
            context.read<AuthService>(),
          ),
          update: (context, firestoreOptimizedService, authService, previous) => CategoryViewModel(
            firestoreOptimizedService,
            authService,
          ),
        ),
        
        // TODO: Cambiar a FirestoreOptimizedService cuando esté implementado
        ChangeNotifierProxyProvider2<FirestoreDataService, AuthService, MovementViewModel>(
          create: (_) => MovementViewModel(
            FirestoreDataService(
              firestoreService: FirestoreService(AuthService()),
              auth: FirebaseAuth.instance,
            ),
            AuthService(),
          ),
          update: (context, firestoreService, authService, previous) => MovementViewModel(
            firestoreService,
            authService,
          ),
        ),
        
        // TODO: Cambiar a FirestoreOptimizedService cuando esté implementado
        ChangeNotifierProxyProvider2<FirestoreDataService, AuthService, SaleViewModel>(
          create: (_) => SaleViewModel(
            FirestoreDataService(
              firestoreService: FirestoreService(AuthService()),
              auth: FirebaseAuth.instance,
            ),
            AuthService(),
          ),
          update: (context, firestoreService, authService, previous) => SaleViewModel(
            firestoreService,
            authService,
          ),
        ),
        
        // AuthViewModel
        ChangeNotifierProxyProvider<AuthService, AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthService>(),
            context.read<FirestoreService>(),
          ),
          update: (context, authService, previous) => AuthViewModel(
            authService,
            context.read<FirestoreService>(),
          ),
        ),
        
        // DashboardViewModel - Usando FirestoreOptimizedService
        ChangeNotifierProxyProvider2<FirestoreOptimizedService, AuthService, DashboardViewModel>(
          create: (context) => DashboardViewModel.withOptimizedService(
            context.read<FirestoreOptimizedService>(),
            AuthService(),
          ),
          update: (context, firestoreOptimizedService, authService, previous) {
            final dashboardVM = previous ?? DashboardViewModel.withOptimizedService(
              firestoreOptimizedService,
              authService,
            );
            // Actualizar servicios si cambiaron
            dashboardVM.optimizedDataService = firestoreOptimizedService;
            dashboardVM.authService = authService;
            
            // Establecer referencia en ProductViewModel si está disponible
            try {
              final productVM = context.read<ProductViewModel>();
              productVM.setDashboardViewModel(dashboardVM);
              print('✅ DashboardViewModel: Referencia establecida en ProductViewModel');
            } catch (e) {
              print('⚠️ DashboardViewModel: No se pudo establecer referencia en ProductViewModel: $e');
            }
            
            return dashboardVM;
          },
        ),
        
        // SyncViewModel
        ChangeNotifierProxyProvider2<SyncService, FirestoreDataService, SyncViewModel>(
          create: (context) => SyncViewModel(
            context.read<SyncService>(),
            context.read<FirestoreDataService>(),
          ),
          update: (context, syncService, firestoreService, previous) => SyncViewModel(
            syncService,
            firestoreService,
          ),
        ),
        
        // ThemeViewModel
        ChangeNotifierProxyProvider<ThemeProvider, ThemeViewModel>(
          create: (context) => ThemeViewModel(
            context.read<ThemeProvider>(),
          ),
          update: (context, themeProvider, previous) => ThemeViewModel(
            themeProvider,
          ),
        ),
      ],
      child: AppInitializer(
        child: Consumer2<ThemeViewModel, AuthViewModel>(
          builder: (context, themeViewModel, authViewModel, _) {
            return MaterialApp.router(
              title: 'Stockcito - Planeta Motos',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeViewModel.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              routerConfig: AppRouter.createRouter(authViewModel),
            );
          },
        ),
      ),
      ),
    );
  }
}


