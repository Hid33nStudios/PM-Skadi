import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Nueva paleta de colores: Negro, Amarillo y Blanco
  static const _primaryColor = Color(0xFFFFD700); // Amarillo dorado
  static const _secondaryColor = Color(0xFFFFEB3B); // Amarillo más claro
  static const _accentColor = Color(0xFFFFC107); // Amarillo ámbar
  static const _errorColor = Color(0xFFE57373);
  static const _successColor = Color(0xFF81C784);
  static const _warningColor = Color(0xFFFFB74D);
  
  // Colores base
  static const _blackColor = Color(0xFF1A1A1A); // Negro suave
  static const _darkGrayColor = Color(0xFF2D2D2D); // Gris oscuro
  static const _lightGrayColor = Color(0xFFF5F5F5); // Gris claro
  static const _whiteColor = Color(0xFFFFFFFF); // Blanco puro

  // Configuración de fuente Poppins
  static TextTheme _getPoppinsTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
        textBaseline: TextBaseline.alphabetic,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
        textBaseline: TextBaseline.alphabetic,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
        textBaseline: TextBaseline.alphabetic,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.25,
        textBaseline: TextBaseline.alphabetic,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.29,
        textBaseline: TextBaseline.alphabetic,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.33,
        textBaseline: TextBaseline.alphabetic,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.27,
        textBaseline: TextBaseline.alphabetic,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.50,
        textBaseline: TextBaseline.alphabetic,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        textBaseline: TextBaseline.alphabetic,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.50,
        textBaseline: TextBaseline.alphabetic,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        textBaseline: TextBaseline.alphabetic,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        textBaseline: TextBaseline.alphabetic,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        textBaseline: TextBaseline.alphabetic,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        textBaseline: TextBaseline.alphabetic,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        textBaseline: TextBaseline.alphabetic,
      ),
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: _getPoppinsTextTheme(ThemeData.light().textTheme),
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      onPrimary: _blackColor,
      secondary: _secondaryColor,
      onSecondary: _blackColor,
      tertiary: _accentColor,
      onTertiary: _blackColor,
      error: _errorColor,
      onError: _whiteColor,
      surface: _whiteColor,
      onSurface: _blackColor,
      surfaceContainerHighest: _lightGrayColor,
      onSurfaceVariant: Color(0xFF666666),
    ),
    scaffoldBackgroundColor: _whiteColor,
    appBarTheme: AppBarTheme(
      backgroundColor: _blackColor,
      foregroundColor: _primaryColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: _primaryColor),
      titleTextStyle: GoogleFonts.poppins(
        color: _primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      color: _whiteColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _primaryColor.withValues(alpha: 0.1), width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightGrayColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorColor, width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF666666)),
      floatingLabelStyle: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: _blackColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: _primaryColor,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: _blackColor,
      elevation: 4,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _blackColor,
      indicatorColor: _primaryColor.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.poppins(color: _primaryColor, fontWeight: FontWeight.w500),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(color: _primaryColor),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: _blackColor,
      selectedIconTheme: const IconThemeData(color: _primaryColor),
      unselectedIconTheme: const IconThemeData(color: Color(0xFF999999)),
      selectedLabelTextStyle: GoogleFonts.poppins(color: _primaryColor, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: GoogleFonts.poppins(color: Color(0xFF999999)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _primaryColor.withValues(alpha: 0.1),
      labelStyle: GoogleFonts.poppins(color: _blackColor, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _blackColor,
      contentTextStyle: GoogleFonts.poppins(color: _primaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 1,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: _getPoppinsTextTheme(ThemeData.dark().textTheme),
    colorScheme: const ColorScheme.dark(
      primary: _primaryColor,
      onPrimary: _blackColor,
      secondary: _secondaryColor,
      onSecondary: _blackColor,
      tertiary: _accentColor,
      onTertiary: _blackColor,
      error: _errorColor,
      onError: _whiteColor,
      surface: _darkGrayColor,
      onSurface: _whiteColor,
    ),
    scaffoldBackgroundColor: _blackColor,
    appBarTheme: AppBarTheme(
      backgroundColor: _darkGrayColor,
      foregroundColor: _primaryColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: _primaryColor),
      titleTextStyle: GoogleFonts.poppins(
        color: _primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      color: _darkGrayColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _primaryColor.withValues(alpha: 0.2), width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF3A3A3A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorColor, width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFFCCCCCC)),
      floatingLabelStyle: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: _blackColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: _primaryColor,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: _blackColor,
      elevation: 4,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _darkGrayColor,
      indicatorColor: _primaryColor.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.poppins(color: _primaryColor, fontWeight: FontWeight.w500),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(color: _primaryColor),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: _darkGrayColor,
      selectedIconTheme: const IconThemeData(color: _primaryColor),
      unselectedIconTheme: const IconThemeData(color: Color(0xFF999999)),
      selectedLabelTextStyle: GoogleFonts.poppins(color: _primaryColor, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: GoogleFonts.poppins(color: Color(0xFF999999)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _primaryColor.withValues(alpha: 0.1),
      labelStyle: GoogleFonts.poppins(color: _whiteColor, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkGrayColor,
      contentTextStyle: GoogleFonts.poppins(color: _primaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF424242),
      thickness: 1,
      space: 1,
    ),
  );
} 