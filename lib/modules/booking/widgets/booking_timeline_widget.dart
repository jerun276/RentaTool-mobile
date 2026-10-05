import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/booking_model.dart';

/// Visual 4-step lifecycle progress timeline for equipment rentals.
class BookingTimelineWidget extends StatelessWidget {
  final BookingModel booking;

  const BookingTimelineWidget({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final isCancelled = booking.isCancelled;
    final isDisputed = booking.isDisputed;

    final step1Done = !isCancelled; // Booking Requested & Confirmed
    final step2Done = booking.pickupVerified || booking.isActive || booking.isCompleted;
    final step3Done = booking.isActive || booking.isCompleted;
    final step4Done = booking.returnVerified || booking.isCompleted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RENTAL & HANDOVER LIFECYCLE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
              if (isCancelled)
                const Text('CANCELLED', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold))
              else if (isDisputed)
                const Text('DISPUTED', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          _timelineStep(
            index: '1',
            title: 'Reservation Confirmed',
            desc: 'Booking schedules locked in system; escrow pre-auth deposit verified.',
            isCompleted: step1Done,
            isCurrent: booking.isRequested || booking.isConfirmed && !booking.pickupVerified,
          ),
          _stepConnector(step1Done && step2Done),

          _timelineStep(
            index: '2',
            title: 'Pickup Handover Verified',
            desc: booking.pickupVerified
                ? 'Cryptographic QR token confirmed with logged GPS location.'
                : 'Owner presents QR token; renter scans camera to confirm equipment receipt.',
            isCompleted: step2Done,
            isCurrent: booking.isConfirmed && !booking.pickupVerified,
          ),
          _stepConnector(step2Done && step3Done),

          _timelineStep(
            index: '3',
            title: 'Active Rental Period',
            desc: booking.isActive
                ? 'Machinery in active possession. Dynamic extensions available.'
                : 'Equipment in use between rental start and return dates.',
            isCompleted: step3Done,
            isCurrent: booking.isActive && !booking.returnVerified,
          ),
          _stepConnector(step3Done && step4Done),

          _timelineStep(
            index: '4',
            title: 'Return Handover & Inspection',
            desc: booking.returnVerified
                ? 'Equipment returned. Post-rental condition verified.'
                : 'Renter generates return token; owner confirms receipt & physical condition.',
            isCompleted: step4Done,
            isCurrent: booking.isActive && !booking.returnVerified,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _timelineStep({
    required String index,
    required String title,
    required String desc,
    required bool isCompleted,
    required bool isCurrent,
    bool isLast = false,
  }) {
    Color iconColor = AppColors.textMuted;
    if (isCompleted) {
      iconColor = AppColors.primaryLight;
    } else if (isCurrent) {
      iconColor = AppColors.warning;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.primary.withValues(alpha: 0.2)
                : (isCurrent ? AppColors.warning.withValues(alpha: 0.15) : AppColors.surfaceElevated),
            border: Border.all(
              color: iconColor,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: AppColors.primaryLight)
                : Text(
                    index,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepConnector(bool isDone) {
    return Container(
      margin: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      width: 2,
      height: 16,
      color: isDone ? AppColors.primaryLight : AppColors.border,
    );
  }
}
