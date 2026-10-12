import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentatool_mobile/core/theme/app_colors.dart';
import 'package:rentatool_mobile/core/theme/app_theme.dart';
import 'package:rentatool_mobile/core/theme/theme_provider.dart';

void main() {
  group('Theme System Unit Tests', () {
    test('Default theme is Light (White Theme)', () {
      final notifier = ThemeNotifier();
      expect(notifier.state, ThemeMode.light);
      expect(AppColors.isDark, isFalse);
      expect(AppColors.background, AppColors.lightBackground);
      expect(AppColors.surface, AppColors.lightSurface);
    });

    test('Toggling theme switches between Light and Dark mode', () async {
      final notifier = ThemeNotifier();
      expect(notifier.state, ThemeMode.light);

      await notifier.toggleTheme();
      expect(notifier.state, ThemeMode.dark);
      expect(AppColors.isDark, isTrue);
      expect(AppColors.background, AppColors.darkBackground);
      expect(AppColors.surface, AppColors.darkSurface);

      await notifier.toggleTheme();
      expect(notifier.state, ThemeMode.light);
      expect(AppColors.isDark, isFalse);
      expect(AppColors.background, AppColors.lightBackground);
      expect(AppColors.surface, AppColors.lightSurface);
    });

    test('AppTheme provides valid light and dark ThemeData', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);
    });
  });
}
