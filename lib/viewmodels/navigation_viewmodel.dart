import 'package:flutter/foundation.dart';

class NavigationViewModel extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void navigateToProducts() {
    setSelectedIndex(1);
  }

  void navigateToCategories() {
    setSelectedIndex(2);
  }

  void navigateToDashboard() {
    setSelectedIndex(0);
  }

  void navigateToMovements() {
    setSelectedIndex(3);
  }

  void navigateToSales() {
    setSelectedIndex(4);
  }
} 