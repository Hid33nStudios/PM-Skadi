import 'package:flutter/material.dart';

class Responsive {
  // Breakpoints mejorados para mejor experiencia
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= largeDesktopBreakpoint;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double getResponsiveWidth(BuildContext context, double percentage) =>
      getScreenWidth(context) * (percentage / 100);

  static double getResponsiveHeight(BuildContext context, double percentage) =>
      getScreenHeight(context) * (percentage / 100);

  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.1;
    } else if (isLargeDesktop(context)) {
      return baseSize * 1.3;
    } else {
      return baseSize * 1.2;
    }
  }

  /// Obtener número de columnas para grids según el tamaño de pantalla
  static int getGridColumns(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3}) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  /// Obtener espaciado responsive
  static double getResponsiveSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 12.0;
    } else {
      return 16.0;
    }
  }

  /// Obtener tamaño de sidebar responsive
  static double getSidebarWidth(BuildContext context, {bool isExpanded = false}) {
    if (isMobile(context)) {
      return isExpanded ? 280.0 : 0.0; // Drawer completo o oculto
    } else if (isTablet(context)) {
      return isExpanded ? 200.0 : 60.0;
    } else {
      return isExpanded ? 250.0 : 70.0;
    }
  }

  static Widget responsiveBuilder({
    required BuildContext context,
    required Widget mobile,
    required Widget tablet,
    required Widget desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  /// Widget constructor para layouts responsive más avanzados
  static Widget responsiveWidget({
    required BuildContext context,
    required Widget Function(BuildContext context, BoxConstraints constraints) builder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => builder(context, constraints),
    );
  }
} 