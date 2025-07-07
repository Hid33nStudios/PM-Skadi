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

class _DashboardCardState extends State<DashboardCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = !Responsive.isMobile(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: isWeb ? _scaleAnimation.value : 1.0,
          child: MouseRegion(
            onEnter: (_) => isWeb ? _onHover(true) : null,
            onExit: (_) => isWeb ? _onHover(false) : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isWeb ? null : Colors.white,
                gradient: isWeb ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isWeb ? 0.08 : 0.05),
                    blurRadius: isWeb ? _elevationAnimation.value * 2 : 8,
                    offset: Offset(0, isWeb ? _elevationAnimation.value / 2 : 1),
                    spreadRadius: isWeb ? 0 : 0,
                  ),
                  if (isWeb && _isHovered)
                    BoxShadow(
                      color: (widget.iconColor ?? Theme.of(context).primaryColor).withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                ],
                border: isWeb ? null : Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
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
          ),
        );
      },
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
                    gradient: isWeb ? LinearGradient(
                      colors: [
                        (widget.iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
                        (widget.iconColor ?? Theme.of(context).primaryColor).withOpacity(0.2),
                      ],
                    ) : null,
                    color: isWeb ? null : (widget.iconColor ?? Theme.of(context).primaryColor).withOpacity(0.08),
                    shape: BoxShape.circle,
                    boxShadow: isWeb ? [
                      BoxShadow(
                        color: (widget.iconColor ?? Theme.of(context).primaryColor).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ] : null,
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _isHovered ? (widget.iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1) : Colors.transparent,
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