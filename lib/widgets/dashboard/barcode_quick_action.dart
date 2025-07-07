import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/barcode_scanner_service.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../theme/responsive.dart';
import '../../router/app_router.dart';
import '../../screens/barcode_scanner_screen.dart';
import '../../models/product.dart';

class BarcodeQuickAction extends StatelessWidget {
  const BarcodeQuickAction({super.key});

  @override
  Widget build(BuildContext context) {
    // Solo mostrar en dispositivos móviles
    if (!Responsive.isMobile(context)) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => _openBarcodeScanner(context),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 12,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Escanear Producto',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Agregar producto rápido',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 7,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBarcodeScanner(BuildContext context) async {
    try {
      final result = await context.push('/barcode-scanner');

      if (result != null && result is Product) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Producto "${result.name}" escaneado exitosamente'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.white,
                onPressed: () {
                  // Aquí podrías navegar a la pantalla de productos
                  context.goToDashboard();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al escanear: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 