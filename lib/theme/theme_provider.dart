import 'package:flutter/material.dart';
import 'package:doctro/core/constants/pref_constant.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(Preferences.is_dark_mode) ?? false;
    AyurezeTheme.updateThemeMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    AyurezeTheme.updateThemeMode(_isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Preferences.is_dark_mode, _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    AyurezeTheme.updateThemeMode(_isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Preferences.is_dark_mode, _isDarkMode);
    notifyListeners();
  }

  ThemeData get theme => AyurezeTheme.theme(isDarkMode: _isDarkMode);
}
