import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class WearProgressBar extends StatelessWidget {
  final int daysAccumulated;
  final int thresholdDays;

  const WearProgressBar({
    super.key,
    required this.daysAccumulated,
    this.thresholdDays = 60,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double ratio = (daysAccumulated / thresholdDays).clamp(0.0, 1.0);
    final bool isCritical = daysAccumulated >= thresholdDays;
    final bool isWarning = daysAccumulated >= (thresholdDays * 0.75);

    final Color progressColor = isCritical
        ? AppColors.wearLockout
        : isWarning
            ? AppColors.wearWarning
            : AppColors.wearNormal;

    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final trackColor = isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wear Accumulation: $daysAccumulated / $thresholdDays days',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isCritical ? AppColors.wearLockout : secondaryText,
              ),
            ),
            if (isCritical)
              const Text(
                'MAINTENANCE LOCK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.wearLockout,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
