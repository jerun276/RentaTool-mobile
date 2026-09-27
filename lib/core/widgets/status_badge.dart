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
    Color bg;
    Color fg;
    Color border;

    switch (style) {
      case BadgeStyle.success:
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.primaryLight;
        border = AppColors.success.withValues(alpha: 0.3);
        break;
      case BadgeStyle.warning:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = const Color(0xFFFFB95F);
        border = AppColors.warning.withValues(alpha: 0.3);
        break;
      case BadgeStyle.error:
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = const Color(0xFFFF8080);
        border = AppColors.error.withValues(alpha: 0.3);
        break;
      case BadgeStyle.purple:
        bg = AppColors.purple.withValues(alpha: 0.15);
        fg = const Color(0xFFD0BCFF);
        border = AppColors.purple.withValues(alpha: 0.3);
        break;
      case BadgeStyle.info:
        bg = AppColors.info.withValues(alpha: 0.15);
        fg = const Color(0xFF93C5FD);
        border = AppColors.info.withValues(alpha: 0.3);
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
