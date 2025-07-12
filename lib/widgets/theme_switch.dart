import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/theme_viewmodel.dart';

class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel>();
    
    return IconButton(
      key: ValueKey<bool>(themeViewModel.isDarkMode),
      icon: Icon(
        themeViewModel.isDarkMode ? Icons.light_mode : Icons.dark_mode,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () {
        themeViewModel.toggleTheme();
      },
      tooltip: themeViewModel.isDarkMode ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
    );
  }
} 