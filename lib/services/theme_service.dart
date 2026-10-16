import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeOption {
  final String name;
  final Color primaryColor;
  final IconData icon;

  const ThemeOption({
    required this.name,
    required this.primaryColor,
    required this.icon,
  });
}

class ThemeService extends ChangeNotifier {
  static const String _keyThemeMode = 'kantin_bu_sari_theme_mode';
  static const String _keyColorIndex = 'kantin_bu_sari_color_index';

  static final ThemeService instance = ThemeService._();
  ThemeService._();

  static const List<ThemeOption> availableColors = [
    ThemeOption(
      name: 'Bu Sari Orange (Original)',
      primaryColor: Colors.deepOrange,
      icon: Icons.local_fire_department,
    ),
    ThemeOption(
      name: 'Emerald Canteen',
      primaryColor: Color(0xFF059669),
      icon: Icons.eco,
    ),
    ThemeOption(
      name: 'Royal Blue Modern',
      primaryColor: Color(0xFF2563EB),
      icon: Icons.bolt,
    ),
    ThemeOption(
      name: 'Crimson Red Sambal',
      primaryColor: Color(0xFFDC2626),
      icon: Icons.restaurant,
    ),
    ThemeOption(
      name: 'Purple Velvet',
      primaryColor: Color(0xFF7C3AED),
      icon: Icons.auto_awesome,
    ),
  ];

  ThemeMode _themeMode = ThemeMode.system;
  int _selectedColorIndex = 0;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  int get selectedColorIndex => _selectedColorIndex;
  Color get primaryColor => availableColors[_selectedColorIndex].primaryColor;
  ThemeOption get currentThemeOption => availableColors[_selectedColorIndex];

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();

    final modeString = prefs.getString(_keyThemeMode);
    if (modeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (modeString == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    _selectedColorIndex = prefs.getInt(_keyColorIndex) ?? 0;
    if (_selectedColorIndex < 0 || _selectedColorIndex >= availableColors.length) {
      _selectedColorIndex = 0;
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setString(_keyThemeMode, 'dark');
    } else if (mode == ThemeMode.light) {
      await prefs.setString(_keyThemeMode, 'light');
    } else {
      await prefs.setString(_keyThemeMode, 'system');
    }
  }

  Future<void> toggleDarkMode(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setColorIndex(int index) async {
    if (index < 0 || index >= availableColors.length) return;
    _selectedColorIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyColorIndex, index);
  }
}
