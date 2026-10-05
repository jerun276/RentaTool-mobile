import 'package:flutter/material.dart';

/// Design tokens and brand color palette for RentaTool LK.
/// Supports both default White (Light) mode and Dark mode.
class AppColors {
  AppColors._();

  /// Global toggle reflecting the current active theme mode.
  /// Defaults to false (White Theme).
  static bool isDark = false;

  // Primary Brand Accents (Emerald)
  static const Color primary = Color(0xFF10B981);
  static const Color primaryLight = Color(0xFF4EDEA3);
  static const Color primaryDark = Color(0xFF047857);

  // Static constants for explicit Light Mode
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceLight = Color(0xFFF1F5F9);
  static const Color lightSurfaceElevated = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFCBD5E1);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Static constants for explicit Dark Mode
  static const Color darkBackground = Color(0xFF0F131C);
  static const Color darkSurface = Color(0xFF181C24);
  static const Color darkSurfaceLight = Color(0xFF222834);
  static const Color darkSurfaceElevated = Color(0xFF2B3242);
  static const Color darkBorder = Color(0xFF1F2937);
  static const Color darkBorderSubtle = Color(0xFF374151);
  static const Color darkTextPrimary = Color(0xFFDFE2EE);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);

  // Dynamic Backgrounds (Default: White / Light)
  static Color get background => isDark ? darkBackground : lightBackground;
  static Color get surface => isDark ? darkSurface : lightSurface;
  static Color get surfaceLight => isDark ? darkSurfaceLight : lightSurfaceLight;
  static Color get surfaceElevated => isDark ? darkSurfaceElevated : lightSurfaceElevated;

  // Dynamic Borders & Dividers
  static Color get border => isDark ? darkBorder : lightBorder;
  static Color get borderSubtle => isDark ? darkBorderSubtle : lightBorderSubtle;

  // Dynamic Typography
  static Color get textPrimary => isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => isDark ? darkTextSecondary : lightTextSecondary;
  static Color get textMuted => isDark ? darkTextMuted : lightTextMuted;

  // Component Status Badges
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);

  // Wear & Lockout State (Student 2)
  static const Color wearNormal = Color(0xFF10B981);
  static const Color wearWarning = Color(0xFFF59E0B);
  static const Color wearLockout = Color(0xFFFF6B6B);

  // Escrow State (Student 4)
  static const Color escrowHeld = Color(0xFF3B82F6);
  static const Color escrowSettled = Color(0xFF10B981);
  static const Color claimActive = Color(0xFFF59E0B);
}
