import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/equipment_model.dart';
import 'wear_progress_bar.dart';

class EquipmentCard extends StatelessWidget {
  final EquipmentModel equipment;
  final VoidCallback? onTap;

  const EquipmentCard({
    super.key,
    required this.equipment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_LK',
      symbol: 'LKR ',
      decimalDigits: 0,
    );

    final isLocked = equipment.isWearLocked;
    final primaryImg = equipment.primaryImageUrl;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image Placeholder or Network image
            Container(
              height: 150,
              width: double.infinity,
              color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (primaryImg.isNotEmpty)
                    Image.network(
                      primaryImg,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackImagePlaceholder(),
                    )
                  else
                    _fallbackImagePlaceholder(),
                  // Top Status Badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: StatusBadge(
                      label: isLocked
                          ? (equipment.isWearLimitReached ? 'LOCKOUT (60D+)' : 'MAINTENANCE')
                          : equipment.status,
                      style: isLocked ? BadgeStyle.error : BadgeStyle.success,
                    ),
                  ),
                  // Category Badge (always dark semi-transparent pill, white text)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xCC000000),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        equipment.categoryName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: textMuted),
                      const SizedBox(width: 4),
                      Text(
                        equipment.location,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 60-Day Wear Limit Progress Bar (Student 2 key feature)
                  WearProgressBar(
                    daysAccumulated: equipment.totalRentalDaysAccumulated,
                  ),
                  const SizedBox(height: 12),

                  const Divider(),
                  const SizedBox(height: 6),

                  // Pricing row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DAILY RATE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: textMuted,
                            ),
                          ),
                          Text(
                            currencyFormatter.format(equipment.dailyRate),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Repl: ${currencyFormatter.format(equipment.replacementValue)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImagePlaceholder() {
    return const Center(
      child: Icon(
        Icons.precision_manufacturing_outlined,
        size: 56,
        color: Color(0x5594A3B8),
      ),
    );
  }
}
