import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/hive_database_service.dart';
import 'services/hybrid_data_service.dart';
import 'services/sync_service.dart';
import 'services/migration_service.dart';
import 'services/barcode_scanner_service.dart';
import 'viewmodels/product_viewmodel.dart';
import 'viewmodels/category_viewmodel.dart';
import 'viewmodels/movement_viewmodel.dart';
import 'viewmodels/sale_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/sync_viewmodel.dart';
import 'viewmodels/migration_viewmodel.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/add_sale_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/migration_screen.dart';
import 'screens/barcode_scanner_screen.dart';
import 'screens/category_management_screen.dart';
import 'screens/movement_history_screen.dart';
import 'screens/sales_history_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/edit_product_screen.dart';
import 'screens/product_detail_screen.dart';
import 'models/product.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'widgets/app_initializer.dart';
import 'router/app_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  // Asegurar que las inicializaciones estén en la misma zona
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar Hive
  await Hive.initFlutter();
  
  // Inicializar Sentry en la misma zona
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://7809e26486e6ab2d891da853864a2047@o4509520741335040.ingest.us.sentry.io/4509520742776832';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
    },
  );
  
  // Ejecutar la aplicación
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Servicios base
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ProxyProvider<AuthService, FirestoreService>(
          create: (_) => FirestoreService(AuthService()),
          update: (context, authService, previous) => FirestoreService(authService),
        ),
        Provider<HiveDatabaseService>(
          create: (_) => HiveDatabaseService(),
        ),
        ProxyProvider2<FirestoreService, HiveDatabaseService, HybridDataService>(
          create: (_) => HybridDataService(
            firestoreService: FirestoreService(AuthService()),
            localDatabase: HiveDatabaseService(),
            auth: FirebaseAuth.instance,
          ),
          update: (context, firestoreService, hiveDatabaseService, previous) => HybridDataService(
            firestoreService: firestoreService,
            localDatabase: hiveDatabaseService,
            auth: FirebaseAuth.instance,
          ),
        ),
        Provider<SyncService>(
          create: (context) => SyncService(
            FirebaseFirestore.instance,
            FirebaseAuth.instance,
            context.read<HybridDataService>(),
          ),
        ),
        Provider<MigrationService>(
          create: (context) => MigrationService(
            FirebaseFirestore.instance,
            FirebaseAuth.instance,
            context.read<HybridDataService>(),
          ),
        ),
        Provider<BarcodeScannerService>(
          create: (_) => BarcodeScannerService(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        // ViewModels con servicios híbridos y AuthService
        ChangeNotifierProxyProvider2<HybridDataService, AuthService, ProductViewModel>(
          create: (_) => ProductViewModel(HybridDataService(
            firestoreService: FirestoreService(AuthService()),
            localDatabase: HiveDatabaseService(),
            auth: FirebaseAuth.instance,
          ), AuthService()),
          update: (context, hybridService, authService, previous) => ProductViewModel(
            hybridService,
            authService,
          ),
        ),
        ChangeNotifierProxyProvider2<HybridDataService, AuthService, CategoryViewModel>(
          create: (_) => CategoryViewModel(HybridDataService(
            firestoreService: FirestoreService(AuthService()),
            localDatabase: HiveDatabaseService(),
            auth: FirebaseAuth.instance,
          ), AuthService()),
          update: (context, hybridService, authService, previous) => CategoryViewModel(
            hybridService,
            authService,
          ),
        ),
        ChangeNotifierProxyProvider2<HybridDataService, AuthService, MovementViewModel>(
          create: (_) => MovementViewModel(HybridDataService(
            firestoreService: FirestoreService(AuthService()),
            localDatabase: HiveDatabaseService(),
            auth: FirebaseAuth.instance,
          ), AuthService()),
          update: (context, hybridService, authService, previous) => MovementViewModel(
            hybridService,
            authService,
          ),
        ),
        ChangeNotifierProxyProvider2<HybridDataService, AuthService, SaleViewModel>(
          create: (_) => SaleViewModel(HybridDataService(
            firestoreService: FirestoreService(AuthService()),
            localDatabase: HiveDatabaseService(),
            auth: FirebaseAuth.instance,
          ), AuthService()),
          update: (context, hybridService, authService, previous) => SaleViewModel(
            hybridService,
            authService,
          ),
        ),
        
        // AuthViewModel debe ir ANTES del DashboardViewModel
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
        
        ChangeNotifierProxyProvider3<HybridDataService, AuthService, AuthViewModel, DashboardViewModel>(
          create: (_) => DashboardViewModel(HybridDataService(
            firestoreService: FirestoreService(AuthService()),
            localDatabase: HiveDatabaseService(),
            auth: FirebaseAuth.instance,
          ), AuthService()),
          update: (context, hybridService, authService, authViewModel, previous) {
            final currentUser = authViewModel.currentUser;
            final dashboardVM = previous ?? DashboardViewModel(hybridService, authService);
            dashboardVM.lastUserId = currentUser?.uid;
            // Actualizar servicios si cambiaron
            dashboardVM.dataService = hybridService;
            dashboardVM.authService = authService;
            // Si el usuario cambió, limpiar datos
            if (previous?.lastUserId != currentUser?.uid) {
              dashboardVM.clearData();
            }
            return dashboardVM;
          },
        ),
        
        // ViewModels de sincronización
        ChangeNotifierProxyProvider2<SyncService, HybridDataService, SyncViewModel>(
          create: (context) => SyncViewModel(
            context.read<SyncService>(),
            context.read<HybridDataService>(),
          ),
          update: (context, syncService, hybridService, previous) => SyncViewModel(
            syncService,
            hybridService,
          ),
        ),
        ChangeNotifierProxyProvider<MigrationService, MigrationViewModel>(
          create: (context) => MigrationViewModel(
            context.read<MigrationService>(),
            context.read<HybridDataService>(),
          ),
          update: (context, migrationService, previous) => MigrationViewModel(
            migrationService,
            context.read<HybridDataService>(),
          ),
        ),
        
        // ViewModels de tema
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
    );
  }
}


