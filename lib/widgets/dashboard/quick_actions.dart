import 'package:flutter/material.dart';
import 'dashboard_card.dart';
import 'barcode_quick_action.dart';
import '../../theme/responsive.dart';
import '../../router/app_router.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import 'package:provider/provider.dart';

class QuickActions extends StatelessWidget {
  final Function(int)? onNavigateToIndex;
  
  const QuickActions({
    super.key,
    this.onNavigateToIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Las acciones rápidas son estáticas, así que siempre mostramos el layout
    return _buildResponsiveLayout(context);
  }

  /// Layout responsive para las acciones rápidas
  Widget _buildResponsiveLayout(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return _buildMobileLayout(context);
    } else if (Responsive.isTablet(context)) {
      return _buildTabletLayout(context);
    } else {
      return _buildDesktopLayout(context);
    }
  }

  /// Layout para móvil mejorado
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Escáner de código de barras mejorado
        Container(
          margin: EdgeInsets.only(bottom: 2),
          child: _buildEnhancedBarcodeAction(context),
        ),
        
        // Acciones en grid mejorado
        _buildEnhancedActionGrid(context, 2),
      ],
    );
  }

  /// Layout para tablet mejorado
  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primera fila: 3 acciones principales
        Row(
          children: [
            Expanded(
              child: _buildModernActionButton(
                context,
                'Nueva Venta',
                Icons.add_shopping_cart,
                Colors.green,
                () => context.goToNewSale(),
                isPrimary: true,
              ),
            ),
            SizedBox(width: Responsive.getResponsiveSpacing(context) / 3),
            Expanded(
              child: _buildModernActionButton(
                context,
                'Nuevo Producto',
                Icons.add_box,
                Colors.blue,
                () => context.goToAddProduct(),
                isPrimary: true,
              ),
            ),
            SizedBox(width: Responsive.getResponsiveSpacing(context) / 3),
            Expanded(
              child: _buildModernActionButton(
                context,
                'Añadir Categoría',
                Icons.category,
                Colors.amber,
                () => context.goToAddCategory(),
                isPrimary: true,
              ),
            ),
          ],
        ),
        
        SizedBox(height: Responsive.getResponsiveSpacing(context) / 2),
        
        // Segunda fila: 3 acciones secundarias
        Row(
          children: [
            Expanded(
              child: _buildModernActionButton(
                context,
                'Ver Movimientos',
                Icons.compare_arrows,
                Colors.teal,
                () => context.goToMovements(),
              ),
            ),
            SizedBox(width: Responsive.getResponsiveSpacing(context) / 3),
            Expanded(
              child: _buildModernActionButton(
                context,
                'Ver Productos',
                Icons.inventory,
                Colors.orange,
                () => context.goToProducts(),
              ),
            ),
            SizedBox(width: Responsive.getResponsiveSpacing(context) / 3),
            Expanded(
              child: _buildModernActionButton(
                context,
                'Ver Ventas',
                Icons.receipt_long,
                Colors.purple,
                () => context.goToSales(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Layout para desktop mejorado
  Widget _buildDesktopLayout(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Primera fila: 3 acciones principales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildPremiumActionButton(
                  context,
                  'Nueva Venta',
                  Icons.add_shopping_cart,
                  Colors.green,
                  () => context.goToNewSale(),
                  isPrimary: true,
                  iconSize: 28, // Antes: 38
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), // Antes: vertical: 18
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumActionButton(
                  context,
                  'Nuevo Producto',
                  Icons.add_box,
                  Colors.blue,
                  () => context.goToAddProduct(),
                  isPrimary: true,
                  iconSize: 28, // Antes: 38
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), // Antes: vertical: 18
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumActionButton(
                  context,
                  'Añadir Categoría',
                  Icons.category,
                  Colors.amber,
                  () => context.goToAddCategory(),
                  isPrimary: true,
                  iconSize: 28, // Antes: 38
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), // Antes: vertical: 18
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Antes: 16
          // Segunda fila: 3 acciones secundarias
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildPremiumActionButton(
                  context,
                  'Ver Movimientos',
                  Icons.compare_arrows,
                  Colors.teal,
                  () => context.goToMovements(),
                  iconSize: 22, // Antes: 34
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), // Antes: vertical: 14
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumActionButton(
                  context,
                  'Ver Productos',
                  Icons.inventory,
                  Colors.orange,
                  () => context.goToProducts(),
                  iconSize: 22, // Antes: 34
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), // Antes: vertical: 14
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumActionButton(
                  context,
                  'Ver Ventas',
                  Icons.receipt_long,
                  Colors.purple,
                  () => context.goToSales(),
                  iconSize: 22, // Antes: 34
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), // Antes: vertical: 14
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Grid de acciones mejorado para móvil
  Widget _buildEnhancedActionGrid(BuildContext context, int columns) {
    final actions = [
      _buildModernActionButton(
        context,
        'Nueva Venta',
        Icons.add_shopping_cart,
        Colors.green,
        () => context.goToNewSale(),
        isPrimary: true,
      ),
      _buildModernActionButton(
        context,
        'Nuevo Producto',
        Icons.add_box,
        Colors.blue,
        () => context.goToAddProduct(),
        isPrimary: true,
      ),
      _buildModernActionButton(
        context,
        'Añadir Categoría',
        Icons.category,
        Colors.amber,
        () => context.goToAddCategory(),
        isPrimary: true,
      ),
      _buildModernActionButton(
        context,
        'Ver Movimientos',
        Icons.compare_arrows,
        Colors.teal,
        () => context.goToMovements(),
      ),
      _buildModernActionButton(
        context,
        'Ver Productos',
        Icons.inventory,
        Colors.orange,
        () => context.goToProducts(),
      ),
      _buildModernActionButton(
        context,
        'Ver Ventas',
        Icons.receipt_long,
        Colors.purple,
        () => context.goToSales(),
      ),
    ];

    return SizedBox(
      height: 120,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
          childAspectRatio: Responsive.isMobile(context) ? 1.8 : 1.0,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) => actions[index],
      ),
    );
  }

  /// Botón de acción moderno para móvil y tablet
  Widget _buildModernActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool isPrimary = false,
  }) {
    final isMobile = Responsive.isMobile(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 3 : 12),
          decoration: BoxDecoration(
            color: isPrimary ? color.withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPrimary ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
              width: isPrimary ? 1 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 3 : 8),
                decoration: BoxDecoration(
                  color: isPrimary ? color.withValues(alpha: 0.15) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? color : color.withValues(alpha: 0.7),
                  size: isMobile ? 14 : 24,
                ),
              ),
              SizedBox(height: isMobile ? 2 : 6),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? color.withValues(alpha: 0.8) : Colors.grey.shade700,
                  fontSize: isMobile ? 8 : Responsive.getResponsiveFontSize(context, 10),
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botón de acción premium para desktop
  Widget _buildPremiumActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isPrimary = false,
    double iconSize = 28,
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: isPrimary ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
              width: isPrimary ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPrimary ? color.withValues(alpha: 0.2) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? color : color.withValues(alpha: 0.7),
                  size: iconSize,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? color.withValues(alpha: 0.8) : Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Acción de escáner mejorada
  Widget _buildEnhancedBarcodeAction(BuildContext context) {
    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: BarcodeQuickAction(),
      ),
    );
  }
} 