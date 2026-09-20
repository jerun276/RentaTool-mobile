import 'package:flutter/material.dart';

/// Design tokens and brand color palette for RentaTool LK.
/// Matches the high-contrast dark aesthetic of the web operations portal.
class AppColors {
  AppColors._();

  // Primary Brand Accents (Emerald)
  static const Color primary = Color(0xFF10B981);
  static const Color primaryLight = Color(0xFF4EDEA3);
  static const Color primaryDark = Color(0xFF047857);

  // Backgrounds (Dark Mode Slate / Charcoal)
  static const Color background = Color(0xFF0F131C);
  static const Color surface = Color(0xFF181C24);
  static const Color surfaceLight = Color(0xFF222834);
  static const Color surfaceElevated = Color(0xFF2B3242);

  // Borders & Dividers
  static const Color border = Color(0xFF1F2937);
  static const Color borderSubtle = Color(0xFF374151);

  // Typography
  static const Color textPrimary = Color(0xFFDFE2EE);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

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
