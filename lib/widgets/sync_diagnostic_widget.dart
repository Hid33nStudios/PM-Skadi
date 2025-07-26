import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../viewmodels/sync_viewmodel.dart';

class SyncDiagnosticWidget extends StatelessWidget {
  final double size;

  const SyncDiagnosticWidget({
    super.key,
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncViewModel>(
      builder: (context, syncVM, _) {
        final syncState = _getSyncState(syncVM);
        final isMobile = Theme.of(context).platform == TargetPlatform.android ||
            Theme.of(context).platform == TargetPlatform.iOS;

        Widget dot = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: syncState.color,
            border: Border.all(
              color: syncState.borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: syncState.color.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: syncState.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Icon(
                  syncState.icon,
                  size: size * 0.6,
                  color: Colors.white,
                ),
        );

        // Tooltip solo en web/desktop
        if (!isMobile) {
          dot = Tooltip(
            message: syncState.tooltip,
            waitDuration: const Duration(milliseconds: 300),
            child: dot,
          );
        }

        return dot;
      },
    );
  }

  SyncState _getSyncState(SyncViewModel syncVM) {
    // Estado de sincronización
    if (syncVM.isSyncing) {
      return SyncState(
        color: Colors.orange,
        borderColor: Colors.orange.shade300,
        icon: Icons.sync,
        message: 'Sincronizando...',
        tooltip: 'Sincronizando con Firebase...',
        isLoading: true,
      );
    }
    if (!syncVM.isOnline) {
      return SyncState(
        color: Colors.red,
        borderColor: Colors.red.shade300,
        icon: Icons.cloud_off,
        message: 'Sin conexión',
        tooltip: 'Sin conexión con Firebase',
        isLoading: false,
      );
    }
    if (syncVM.pendingChangesCount > 0) {
      return SyncState(
        color: Colors.orange,
        borderColor: Colors.orange.shade300,
        icon: Icons.pending,
        message: 'Cambios pendientes',
        tooltip: 'Hay cambios pendientes por sincronizar',
        isLoading: false,
      );
    }
    return SyncState(
      color: Colors.green,
      borderColor: Colors.green.shade300,
      icon: Icons.cloud_done,
      message: 'Sincronizado',
      tooltip: 'Conectado y sincronizado con el servidor',
      isLoading: false,
    );
  }
}

class SyncState {
  final Color color;
  final Color borderColor;
  final IconData icon;
  final String message;
  final String tooltip;
  final bool isLoading;

  const SyncState({
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.message,
    required this.tooltip,
    required this.isLoading,
  });
} 