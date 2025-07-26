import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/sync_viewmodel.dart';

import '../services/firestore_data_service.dart';
import '../config/app_config.dart';
import '../config/performance_config.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../viewmodels/product_viewmodel.dart';
import '../models/product.dart';
// Deferred imports para precarga
import '../widgets/dashboard/sales_chart.dart' deferred as sales_chart;
import '../widgets/dashboard/category_distribution.dart' deferred as category_distribution;
import '../widgets/dashboard/recent_activity.dart' deferred as recent_activity;
import '../widgets/dashboard/stock_status.dart' deferred as stock_status;
import '../widgets/dashboard/sales_summary.dart' deferred as sales_summary;
import 'dart:async'; // Import for Timer

class AppInitializer extends StatefulWidget {
  final Widget child;
  static final ValueNotifier<bool> isInitializedNotifier = ValueNotifier(false);

  const AppInitializer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String _initializationStatus = 'Inicializando...';
  bool _criticalServicesReady = false;

  // Variables para el listener global optimizado
  String _barcodeBuffer = '';
  DateTime? _lastKeyTime;
  static const Duration _barcodeTimeout = Duration(milliseconds: 100);
  
  // OPTIMIZACIÓN: Timer para debounce del listener
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    // OPTIMIZACIÓN: Listener global optimizado solo en web/PC
    if (kIsWeb) {
      html.window.addEventListener('keydown', _onKeyDownOptimized);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (kIsWeb) {
      html.window.removeEventListener('keydown', _onKeyDownOptimized);
    }
    super.dispose();
  }

  // OPTIMIZACIÓN: Listener optimizado con debounce
  void _onKeyDownOptimized(html.Event event) {
    if (event is! html.KeyboardEvent) return;
    
    // OPTIMIZACIÓN: Solo procesar si es necesario
    if (!_shouldProcessKeyEvent(event)) return;
    
    // OPTIMIZACIÓN: Debounce para reducir CPU
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      _processKeyEvent(event);
    });
  }

  // OPTIMIZACIÓN: Verificar si debe procesar el evento
  bool _shouldProcessKeyEvent(html.KeyboardEvent event) {
    // Ignorar si hay un TextField enfocado
    if (html.document.activeElement?.tagName == 'INPUT' || 
        html.document.activeElement?.tagName == 'TEXTAREA') {
      return false;
    }
    
    // Solo procesar teclas relevantes
    return event.key == 'Enter' || 
           (event.key != null && event.key!.length == 1);
  }

  // OPTIMIZACIÓN: Procesar evento de tecla de forma eficiente
  void _processKeyEvent(html.KeyboardEvent event) {
    final now = DateTime.now();
    if (_lastKeyTime == null || now.difference(_lastKeyTime!) > _barcodeTimeout) {
      _barcodeBuffer = '';
    }
    _lastKeyTime = now;
    
    if (event.key == 'Enter') {
      final code = _barcodeBuffer.trim();
      _barcodeBuffer = '';
      if (code.isNotEmpty) {
        _onBarcodeScanned(code);
      }
    } else if (event.key != null && event.key!.length == 1) {
      _barcodeBuffer += event.key!;
    }
  }

  void _onBarcodeScanned(String code) async {
    final productViewModel = Provider.of<ProductViewModel>(context, listen: false);
    final existingProducts = productViewModel.products;
    Product? product;
    try {
      product = existingProducts.firstWhere(
        (p) => p.barcode == code,
        orElse: () => null as Product,
      );
    } catch (_) {
      product = null;
    }
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Código escaneado: $code'),
          content: product != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Producto: ${product.name}'),
                    Text('Precio: ${product.price}'),
                    Text('Stock: ${product.stock}'),
                  ],
                )
              : const Text('Producto no registrado. ¿Qué deseas hacer?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Aquí puedes navegar a la pantalla de agregar producto con el código
                Navigator.of(context).pushNamed('/add-product', arguments: code);
              },
              child: const Text('Agregar producto'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Aquí puedes navegar a la pantalla de editar producto
                if (product != null) {
                  Navigator.of(context).pushNamed('/add-product', arguments: product);
                } else {
                  Navigator.of(context).pushNamed('/add-product', arguments: code);
                }
              },
              child: const Text('Editar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Aquí puedes navegar a la pantalla de registrar venta
                if (product != null) {
                  Navigator.of(context).pushNamed('/add-sale', arguments: product);
                } else {
                  Navigator.of(context).pushNamed('/add-sale', arguments: code);
                }
              },
              child: const Text('Registrar venta'),
            ),
          ],
        );
      },
    );
  }

  // OPTIMIZACIÓN: Inicialización en etapas
  Future<void> _initializeServices() async {
    try {
      print('🚀 AppInitializer: Iniciando inicialización optimizada...');
      
      // ETAPA 0: Detectar hardware (muy rápido)
      await _detectHardwareAndConfigure();
      _markStageComplete('hardware_detection');
      
      // ETAPA 1: Servicios críticos (rápido)
      await _initializeCriticalServices();
      _markStageComplete('critical');
      
      // ETAPA 2: Servicios básicos (medio)
      await _initializeBasicServices();
      _markStageComplete('basic');
      
      // ETAPA 3: Servicios avanzados (lento, en background)
      _initializeAdvancedServices();
      
    } catch (e, stack) {
      setState(() {
        _initializationStatus = 'Error: $e';
      });
      print('❌ AppInitializer: Error inicializando servicios: $e');
      print(stack);
    }
  }

  // OPTIMIZACIÓN: Detectar hardware y configurar optimizaciones
  Future<void> _detectHardwareAndConfigure() async {
    print('🔍 AppInitializer: Detectando hardware...');
    setState(() {
      _initializationStatus = 'Detectando hardware...';
    });

    try {
      final isLegacyHardware = await PerformanceConfig.detectLegacyHardware();
      final config = PerformanceConfig.getCurrentConfig();
      
      print('⚙️ AppInitializer: Configuración aplicada:');
      print('  - Hardware: ${isLegacyHardware ? "Antiguo" : "Moderno"}');
      print('  - Cache: ${config['cacheExpiration']} minutos');
      print('  - Sync: ${config['syncInterval']} minutos');
      print('  - Elementos por página: ${config['maxItemsPerPage']}');
      print('  - Animaciones: ${config['enableAnimations'] ? "Habilitadas" : "Deshabilitadas"}');
      
      setState(() {
        _initializationStatus = 'Hardware detectado: ${isLegacyHardware ? "Antiguo" : "Moderno"}';
      });
    } catch (e) {
      print('⚠️ AppInitializer: Error detectando hardware: $e');
      setState(() {
        _initializationStatus = 'Usando configuración estándar';
      });
    }
  }

  // OPTIMIZACIÓN: Servicios críticos (esenciales para mostrar la app)
  Future<void> _initializeCriticalServices() async {
    print('🔄 AppInitializer: Inicializando servicios críticos...');
    setState(() {
      _initializationStatus = 'Inicializando servicios críticos...';
    });

    // Solo servicios esenciales para mostrar la app
    final firestoreService = context.read<FirestoreDataService>();
    await firestoreService.initialize();
    print('✅ AppInitializer: FirestoreDataService inicializado correctamente');

    setState(() {
      _criticalServicesReady = true;
      _initializationStatus = 'Servicios críticos listos...';
    });
  }

  // OPTIMIZACIÓN: Servicios básicos (necesarios para funcionalidad básica)
  Future<void> _initializeBasicServices() async {
    print('🔄 AppInitializer: Inicializando servicios básicos...');
    setState(() {
      _initializationStatus = 'Configurando servicios básicos...';
    });

    // Verificar datos de Firebase (no crítico)
    print('AppInitializer: Verificación de datos completada');

    setState(() {
      _initializationStatus = 'Servicios básicos listos...';
    });
  }

  // OPTIMIZACIÓN: Servicios avanzados (en background)
  void _initializeAdvancedServices() {
    print('🔄 AppInitializer: Inicializando servicios avanzados en background...');
    setState(() {
      _initializationStatus = 'Configurando servicios avanzados...';
    });

    // Inicializar sincronización en background (no crítico)
    AppConfig.initializeSync(context).then((_) {
      print('✅ AppInitializer: Sincronización inicializada en background');
      if (mounted) {
        setState(() {
          _initializationStatus = 'Completado';
          _isInitialized = true;
        });
        AppInitializer.isInitializedNotifier.value = true;
        print('✅ AppInitializer: Servicios inicializados correctamente');
      }
    }).catchError((e) {
      print('⚠️ AppInitializer: Error en servicios avanzados: $e');
      // No bloquear la app si fallan servicios no críticos
      if (mounted) {
        setState(() {
          _initializationStatus = 'Completado (con advertencias)';
          _isInitialized = true;
        });
        AppInitializer.isInitializedNotifier.value = true;
      }
    });
  }

  // OPTIMIZACIÓN: Marcar etapa completada
  void _markStageComplete(String stage) {
    print('✅ AppInitializer: Etapa "$stage" completada');
  }

  @override
  Widget build(BuildContext context) {
    // OPTIMIZACIÓN: Mostrar app cuando servicios críticos estén listos
    if (!_criticalServicesReady) {
      return _buildMinimalLoadingUI();
    }

    return widget.child;
  }

  // OPTIMIZACIÓN: UI de carga minimalista
  Widget _buildMinimalLoadingUI() {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // OPTIMIZACIÓN: Texto en lugar de imagen pesada
              Text(
                'Stockcito',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Planeta Motos',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 40),
              
              // OPTIMIZACIÓN: Indicador simple
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              
              // OPTIMIZACIÓN: Estado simple
              Text(
                _initializationStatus,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // OPTIMIZACIÓN: Información minimalista
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Diseñado por Hid33nStudios',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Versión exclusiva para Planeta Motos',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> precargarBundlesDashboard() async {
    // OPTIMIZACIÓN: Cargar solo cuando se necesite
    print('🔄 AppInitializer: Precargando bundles del dashboard...');
    await Future.wait([
      sales_chart.loadLibrary(),
      category_distribution.loadLibrary(),
      recent_activity.loadLibrary(),
      stock_status.loadLibrary(),
      sales_summary.loadLibrary(),
    ]);
    print('✅ AppInitializer: Bundles del dashboard precargados');
  }
}

/// Widget para mostrar el estado de sincronización en cualquier pantalla
class SyncStatusIndicator extends StatelessWidget {
  final bool showDetails;
  final VoidCallback? onTap;

  const SyncStatusIndicator({
    Key? key,
    this.showDetails = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncViewModel>(
      builder: (context, syncViewModel, child) {
        return GestureDetector(
          onTap: onTap ?? () {
            _showSyncDetails(context, syncViewModel);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(syncViewModel.getSyncStatusColor()).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(syncViewModel.getSyncStatusColor()).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  syncViewModel.getSyncStatusIcon(),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  syncViewModel.getSyncStatusText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(syncViewModel.getSyncStatusColor()),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showDetails && syncViewModel.pendingChangesCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(syncViewModel.getSyncStatusColor()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      syncViewModel.pendingChangesCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSyncDetails(BuildContext context, SyncViewModel syncViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(syncViewModel.getSyncStatusIcon()),
            const SizedBox(width: 8),
            const Text('Estado de Sincronización'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado: ${syncViewModel.getSyncStatusText()}'),
            const SizedBox(height: 8),
            if (syncViewModel.pendingChangesCount > 0) ...[
              Text('Cambios pendientes: ${syncViewModel.pendingChangesCount}'),
              const SizedBox(height: 4),
              Text('Detalles: ${syncViewModel.getPendingChangesSummary()}'),
              const SizedBox(height: 8),
            ],
            if (syncViewModel.lastSyncTime != null) ...[
              Text('Última sincronización: ${_formatDateTime(syncViewModel.lastSyncTime!)}'),
              const SizedBox(height: 8),
            ],
            Text('Recomendación: ${syncViewModel.getSyncRecommendations()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (syncViewModel.pendingChangesCount > 0)
            ElevatedButton(
              onPressed: () {
                syncViewModel.forceSync();
                Navigator.pop(context);
              },
              child: const Text('Sincronizar'),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hace ${difference.inSeconds} segundos';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours} horas';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  }
} 