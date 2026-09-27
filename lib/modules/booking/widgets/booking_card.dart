import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onTap;
  final VoidCallback? onShowQR;
  final VoidCallback? onScanQR;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onShowQR,
    this.onScanQR,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_LK',
      symbol: 'LKR ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('MMM dd, yyyy');

    BadgeStyle badgeStyle;
    switch (booking.status.toLowerCase()) {
      case 'active':
        badgeStyle = BadgeStyle.success;
        break;
      case 'confirmed':
        badgeStyle = BadgeStyle.info;
        break;
      case 'completed':
        badgeStyle = BadgeStyle.purple;
        break;
      case 'cancelled':
        badgeStyle = BadgeStyle.error;
        break;
      default:
        badgeStyle = BadgeStyle.warning;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Code and Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        booking.displayCode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(label: booking.status, style: badgeStyle),
                ],
              ),
              const SizedBox(height: 12),

              // Date Range & Duration
              Row(
                children: [
                  const Icon(Icons.date_range_outlined, size: 16, color: AppColors.primaryLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${dateFormatter.format(booking.startDate)} → ${dateFormatter.format(booking.endDate)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${booking.durationInDays}d',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Handover verification status chips
              Row(
                children: [
                  _verificationChip(
                    label: 'Pickup',
                    isVerified: booking.pickupVerified,
                  ),
                  const SizedBox(width: 8),
                  _verificationChip(
                    label: 'Return',
                    isVerified: booking.returnVerified,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Divider(height: 1),
              const SizedBox(height: 10),

              // Total Fee & Action Shortcuts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL RENTAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(booking.totalRentalFee),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (onShowQR != null)
                        IconButton.filledTonal(
                          icon: const Icon(Icons.qr_code, size: 18),
                          tooltip: 'Show Handover QR',
                          onPressed: onShowQR,
                        ),
                      if (onScanQR != null) ...[
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.qr_code_scanner, size: 18),
                          tooltip: 'Scan Handover QR',
                          onPressed: onScanQR,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verificationChip({required String label, required bool isVerified}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isVerified ? AppColors.success.withValues(alpha: 0.12) : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isVerified ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 12,
            color: isVerified ? AppColors.primaryLight : AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            '$label ${isVerified ? "Verified" : "Pending"}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isVerified ? FontWeight.bold : FontWeight.normal,
              color: isVerified ? AppColors.primaryLight : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
