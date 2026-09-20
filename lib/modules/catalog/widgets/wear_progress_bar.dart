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
    final double ratio = (daysAccumulated / thresholdDays).clamp(0.0, 1.0);
    final bool isCritical = daysAccumulated >= thresholdDays;
    final bool isWarning = daysAccumulated >= (thresholdDays * 0.75);

    final Color progressColor = isCritical
        ? AppColors.wearLockout
        : isWarning
            ? AppColors.wearWarning
            : AppColors.wearNormal;

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
                color: isCritical ? AppColors.wearLockout : AppColors.textSecondary,
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
            backgroundColor: AppColors.surfaceElevated,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
