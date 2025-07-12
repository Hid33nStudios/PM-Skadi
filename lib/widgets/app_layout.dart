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

class _AppLayoutState extends State<AppLayout> {
  bool _isHovering = false;

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
    final isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      return Scaffold(
        body: widget.child,
      );
    } else {
      return Scaffold(
        body: Row(
          children: [
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
        }
      },
      onExit: (_) {
        if (!Responsive.isMobile(context)) {
          setState(() => _isHovering = false);
        }
      },
      child: Container(
        width: Responsive.getSidebarWidth(context, isExpanded: _isHovering),
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
                        child: Container(
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
                                      color: isSelected ? item.color : Colors.white,
                                      fontWeight: FontWeight.bold,
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
          ],
        ),
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