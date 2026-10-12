import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BadgeStyle { success, warning, error, info, purple }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeStyle style;

  const StatusBadge({
    super.key,
    required this.label,
    this.style = BadgeStyle.info,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color border;

    switch (style) {
      case BadgeStyle.success:
        bg = isDark ? AppColors.success.withValues(alpha: 0.15) : const Color(0xFFD1FAE5);
        fg = isDark ? AppColors.primaryLight : const Color(0xFF047857);
        border = isDark ? AppColors.success.withValues(alpha: 0.3) : const Color(0xFFA7F3D0);
        break;
      case BadgeStyle.warning:
        bg = isDark ? AppColors.warning.withValues(alpha: 0.15) : const Color(0xFFFEF3C7);
        fg = isDark ? const Color(0xFFFFB95F) : const Color(0xFFB45309);
        border = isDark ? AppColors.warning.withValues(alpha: 0.3) : const Color(0xFFFDE68A);
        break;
      case BadgeStyle.error:
        bg = isDark ? AppColors.error.withValues(alpha: 0.15) : const Color(0xFFFEE2E2);
        fg = isDark ? const Color(0xFFFF8080) : const Color(0xFFB91C1C);
        border = isDark ? AppColors.error.withValues(alpha: 0.3) : const Color(0xFFFECACA);
        break;
      case BadgeStyle.purple:
        bg = isDark ? AppColors.purple.withValues(alpha: 0.15) : const Color(0xFFF3E8FF);
        fg = isDark ? const Color(0xFFD0BCFF) : const Color(0xFF6D28D9);
        border = isDark ? AppColors.purple.withValues(alpha: 0.3) : const Color(0xFFDDD6FE);
        break;
      case BadgeStyle.info:
        bg = isDark ? AppColors.info.withValues(alpha: 0.15) : const Color(0xFFDBEAFE);
        fg = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
        border = isDark ? AppColors.info.withValues(alpha: 0.3) : const Color(0xFFBFDBFE);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
