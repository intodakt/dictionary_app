// UPDATE 5
// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider({required ThemeMode initialThemeMode})
      : _themeMode = initialThemeMode;

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeMode.name);
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }
}
