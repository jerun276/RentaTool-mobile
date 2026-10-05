import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

/// Modal bottom sheet allowing users to review dynamic surge pricing and confirm schedule extensions.
class SurgeExtensionSheet extends ConsumerStatefulWidget {
  final BookingModel booking;
  final VoidCallback onSuccess;

  const SurgeExtensionSheet({
    super.key,
    required this.booking,
    required this.onSuccess,
  });

  static Future<void> show(BuildContext context, BookingModel booking, VoidCallback onSuccess) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SurgeExtensionSheet(booking: booking, onSuccess: onSuccess),
    );
  }

  @override
  ConsumerState<SurgeExtensionSheet> createState() => _SurgeExtensionSheetState();
}

class _SurgeExtensionSheetState extends ConsumerState<SurgeExtensionSheet> {
  late DateTime _newEndDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default to +2 days from current end date
    _newEndDate = widget.booking.endDate.add(const Duration(days: 2));
  }

  int get _extendedDays {
    final d1 = DateTime(widget.booking.endDate.year, widget.booking.endDate.month, widget.booking.endDate.day);
    final d2 = DateTime(_newEndDate.year, _newEndDate.month, _newEndDate.day);
    final diff = d2.difference(d1).inDays;
    return diff <= 0 ? 1 : diff;
  }

  /// Replicates backend surge calculation logic for real-time quotation preview
  ({double multiplier, String reason, bool isWeekend, bool isLastMinute}) _calculateSurge() {
    double mult = 1.0;
    final reasons = <String>[];
    bool isWeekend = false;

    // 1. Weekend Demand Surge (+25%)
    for (var d = widget.booking.endDate.add(const Duration(days: 1));
        d.isBefore(_newEndDate.add(const Duration(days: 1)));
        d = d.add(const Duration(days: 1))) {
      if (d.weekday == DateTime.friday || d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
        isWeekend = true;
        break;
      }
    }
    if (isWeekend) {
      mult += 0.25;
      reasons.add('Weekend High Demand (+25%)');
    }

    // 2. Short Notice Surge (+15%)
    final hoursRemaining = widget.booking.endDate.difference(DateTime.now()).inHours;
    final isLastMinute = hoursRemaining <= 24;
    if (isLastMinute) {
      mult += 0.15;
      reasons.add('Last-Minute Extension (+15%)');
    }

    // Standard Adjustment (+10%)
    if (reasons.isEmpty) {
      mult = 1.10;
      reasons.add('Standard Extension Rate (+10%)');
    }

    return (
      multiplier: mult,
      reason: reasons.join(' & '),
      isWeekend: isWeekend,
      isLastMinute: isLastMinute,
    );
  }

  Future<void> _pickDate() async {
    final firstAllowed = widget.booking.endDate.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _newEndDate.isAfter(firstAllowed) ? _newEndDate : firstAllowed,
      firstDate: firstAllowed,
      lastDate: widget.booking.endDate.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryLight,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _newEndDate = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _confirmExtension() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(bookingServiceProvider);
      final response = await service.extendSchedule(
        bookingId: widget.booking.id,
        newEndDate: _newEndDate,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              'Schedule extended by ${response.extendedDays} days! New Total: LKR ${response.newTotalRentalFee.toInt()}',
            ),
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_LK', symbol: 'LKR ', decimalDigits: 0);
    final dateFormatter = DateFormat('EEE, MMM dd, yyyy');

    final surge = _calculateSurge();
    final baseRate = widget.booking.dailyRate > 0 ? widget.booking.dailyRate : 3500.0;
    final surgeDailyRate = (baseRate * surge.multiplier).roundToDouble();
    final additionalFee = surgeDailyRate * _extendedDays;
    final newTotalFee = widget.booking.totalRentalFee + additionalFee;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Request Schedule Extension',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date Selector Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current End Date', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    Text(dateFormatter.format(widget.booking.endDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('Proposed New End Date', style: TextStyle(fontSize: 10, color: AppColors.primaryLight)),
                    Text(dateFormatter.format(_newEndDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('Change Date', style: TextStyle(fontSize: 12)),
                  onPressed: _pickDate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic Surge Pricing Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surge.multiplier > 1.0 ? AppColors.warning.withValues(alpha: 0.12) : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: surge.multiplier > 1.0 ? AppColors.warning.withValues(alpha: 0.4) : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DYNAMIC SURGE PRICING APPLIED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${((surge.multiplier - 1.0) * 100).round()}% Surge',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  surge.reason,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Fee Calculation Summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _feeRow('Extension Duration', '$_extendedDays days'),
                const SizedBox(height: 6),
                _feeRow('Surge Daily Rate', currencyFormatter.format(surgeDailyRate)),
                const SizedBox(height: 6),
                _feeRow('Additional Fee', currencyFormatter.format(additionalFee), isPositive: true),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Total Rental Fee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      currencyFormatter.format(newTotalFee),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryLight),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_errorMessage != null) ...[
            Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            const SizedBox(height: 12),
          ],

          AppButton(
            text: 'Confirm Extension (${currencyFormatter.format(additionalFee)})',
            icon: Icons.check,
            isLoading: _isSubmitting,
            onPressed: _confirmExtension,
          ),
        ],
      ),
    );
  }

  Widget _feeRow(String label, String value, {bool isPositive = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isPositive ? AppColors.primaryLight : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
