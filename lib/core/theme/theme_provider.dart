import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_storage/hive_storage_service.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    return _loadTheme();
  }

  static ThemeMode _loadTheme() {
    final savedTheme = HiveStorageService.userPrefsBox.get(_themeKey) as String?;
    if (savedTheme == 'dark') {
      return ThemeMode.dark;
    } else if (savedTheme == 'light') {
      return ThemeMode.light;
    }
    return ThemeMode.system;
  }

  void toggleTheme(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    HiveStorageService.userPrefsBox.put(_themeKey, isDark ? 'dark' : 'light');
  }
}
