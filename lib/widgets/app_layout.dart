import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/home_screen.dart';
import '../theme/responsive.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const AppLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> with TickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _hoverAnimationController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverAnimationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _hoverAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      return Scaffold(
        body: widget.child,
      );
    } else {
      return Scaffold(
        body: Row(
          children: [
            // Usar el mismo sidebar compacto que HomeScreen
            _buildCompactSidebar(context),
            const VerticalDivider(thickness: 1, width: 1, color: Colors.grey),
            Expanded(child: widget.child),
          ],
        ),
      );
    }
  }

  Widget _buildCompactSidebar(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!Responsive.isMobile(context)) {
          setState(() => _isHovering = true);
          _hoverAnimationController.forward();
        }
      },
      onExit: (_) {
        if (!Responsive.isMobile(context)) {
          setState(() => _isHovering = false);
          _hoverAnimationController.reverse();
        }
      },
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          // Usar las nuevas utilidades responsive para el ancho del sidebar
          final width = Responsive.getSidebarWidth(context, isExpanded: _isHovering);
          
          return Container(
            width: width,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                right: BorderSide(color: Colors.yellow.withOpacity(0.3), width: 1),
              ),
            ),
            child: Column(
              children: [
                // Header compacto
                Container(
                  height: 70,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border(
                      bottom: BorderSide(color: Colors.yellow.withOpacity(0.3), width: 1),
                    ),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: _isHovering
                      ? Row(
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
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Usuario',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.yellow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.yellow,
                              size: 20,
                            ),
                          ),
                        ),
                  ),
                ),
                
                // Menú items compactos
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected = widget.selectedIndex == index;
                      
                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: Responsive.getResponsiveSpacing(context),
                          vertical: Responsive.getResponsiveSpacing(context) / 2,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onDestinationSelected(index),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                horizontal: _isHovering 
                                    ? Responsive.getResponsiveSpacing(context) * 2
                                    : Responsive.getResponsiveSpacing(context) * 1.5,
                                vertical: Responsive.getResponsiveSpacing(context) * 1.5,
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
                                  ),
                                  if (_isHovering) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: TextStyle(
                                          color: isSelected ? item.color : Colors.grey.shade300,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          fontSize: Responsive.getResponsiveFontSize(context, 14),
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
                
                // Footer compacto con botón de logout
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isHovering)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                        child: Column(
                          children: [
                            Text(
                              'Alpha v1.0.0',
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade400,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Desarrollado por',
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              'Hid33nStudios',
                              style: GoogleFonts.inter(
                                color: Colors.yellow,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'para Planeta Motos',
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      height: 70,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isHovering ? Colors.yellow : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.yellow,
                                  width: 1.5,
                                ),
                              ),
                              child: _isHovering
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.dashboard,
                                          color: Colors.black,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Dashboard',
                                            style: GoogleFonts.inter(
                                              color: Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Icon(
                                      Icons.dashboard,
                                      color: Colors.yellow,
                                      size: 24,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // Menú items con iconos y colores personalizados (igual que HomeScreen)
  static const List<MenuItemData> _menuItems = [
    MenuItemData(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
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
      color: Colors.yellow,
    ),
    MenuItemData(
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
      label: 'Ventas',
      color: Colors.orange,
    ),
  ];
}

class MenuItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color color;

  const MenuItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.color,
  });
} 