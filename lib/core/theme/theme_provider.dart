import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_colors.dart';

const String _themeStorageKey = 'app_theme_mode';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final FlutterSecureStorage _storage;

  ThemeNotifier({FlutterSecureStorage? storage, bool autoLoad = true})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(ThemeMode.light) {
    AppColors.isDark = false;
    if (autoLoad) {
      _loadTheme();
    }
  }

  Future<void> _loadTheme() async {
    try {
      final saved = await _storage.read(key: _themeStorageKey);
      if (saved == 'dark') {
        AppColors.isDark = true;
        state = ThemeMode.dark;
      } else if (saved == 'light') {
        AppColors.isDark = false;
        state = ThemeMode.light;
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    AppColors.isDark = (mode == ThemeMode.dark);
    state = mode;
    try {
      await _storage.write(
        key: _themeStorageKey,
        value: mode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
