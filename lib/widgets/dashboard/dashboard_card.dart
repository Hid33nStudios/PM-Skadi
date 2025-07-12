import 'package:flutter/material.dart';
import '../../theme/responsive.dart';

class DashboardCard extends StatefulWidget {
  final String title;
  final Widget child;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;
  final Color? iconColor;

  const DashboardCard({
    super.key,
    required this.title,
    required this.child,
    this.onTap,
    this.isLoading = false,
    this.icon,
    this.iconColor,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  // Eliminar SingleTickerProviderStateMixin, animaciones y decoraciones avanzadas.
  // Reemplazar por Container plano y colores sólidos.

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = !Responsive.isMobile(context);
    
    return MouseRegion(
      onEnter: (_) => null, // No hacer nada en hover
      onExit: (_) => null, // No hacer nada en hover
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isWeb ? null : Colors.white,
          // Sin gradiente ni sombra ni efecto hover
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              constraints: BoxConstraints(
                minHeight: Responsive.isMobile(context) ? 180 : 200,
                maxHeight: Responsive.isMobile(context) ? 350 : 400,
              ),
              padding: Responsive.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header mejorado
                  _buildEnhancedHeader(context),
                  
                  Divider(
                    height: Responsive.getResponsiveSpacing(context),
                    thickness: 1,
                    color: Colors.grey.shade200,
                  ),
                  
                  // Contenido
                  Flexible(
                    child: widget.isLoading
                        ? _buildLoadingState(context)
                        : widget.child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Header mejorado con mejor diseño
  Widget _buildEnhancedHeader(BuildContext context) {
    final isWeb = !Responsive.isMobile(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Container(
                  margin: EdgeInsets.only(right: Responsive.getResponsiveSpacing(context) / 2),
                  decoration: BoxDecoration(
                    color: isWeb ? null : (widget.iconColor ?? Theme.of(context).primaryColor).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(Responsive.isMobile(context) ? 6 : 8),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor ?? Theme.of(context).primaryColor,
                    size: Responsive.isMobile(context) ? 16 : 24,
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.getResponsiveFontSize(context, 16),
                    color: isWeb ? Colors.grey.shade800 : Colors.grey.shade800,
                    letterSpacing: isWeb ? 0.5 : 0,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: Responsive.isMobile(context) ? 1 : 2,
                ),
              ),
            ],
          ),
        ),
        if (widget.onTap != null)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              size: Responsive.isMobile(context) ? 14 : 16,
              color: widget.iconColor ?? Theme.of(context).primaryColor,
            ),
          ),
      ],
    );
  }

  /// Estado de carga mejorado
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: Responsive.isMobile(context) ? 2 : 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.iconColor ?? Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: Responsive.getResponsiveSpacing(context)),
          Text(
            'Cargando...',
            style: TextStyle(
              fontSize: Responsive.getResponsiveFontSize(context, 14),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 