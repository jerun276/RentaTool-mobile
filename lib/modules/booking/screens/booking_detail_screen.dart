import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  BookingModel? _booking;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBooking();
  }

  Future<void> _fetchBooking() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(bookingServiceProvider);
      final item = await service.getBookingById(widget.bookingId);
      setState(() {
        _booking = item;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load booking details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleExtend() async {
    if (_booking == null) return;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _booking!.endDate.add(const Duration(days: 2)),
      firstDate: _booking!.endDate.add(const Duration(days: 1)),
      lastDate: _booking!.endDate.add(const Duration(days: 30)),
    );

    if (pickedDate != null && mounted) {
      try {
        final service = ref.read(bookingServiceProvider);
        await service.extendSchedule(
          bookingId: _booking!.id,
          newEndDate: pickedDate,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule extension requested successfully')),
        );
        _fetchBooking();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not extend schedule')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const LoadingIndicator(message: 'Loading reservation status...'),
      );
    }

    if (_error != null || _booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: ErrorView(message: _error ?? 'Booking not found', onRetry: _fetchBooking),
      );
    }

    final b = _booking!;
    final currencyFormatter = NumberFormat.currency(locale: 'en_LK', symbol: 'LKR ', decimalDigits: 0);
    final dateFormatter = DateFormat('EEEE, MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking #${b.id.substring(0, b.id.length >= 8 ? 8 : b.id.length).toUpperCase()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, size: 20),
            tooltip: 'Show Handover QR',
            onPressed: () => context.push('/bookings/qr/${b.id}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BOOKING STATUS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        b.status.toUpperCase(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryLight),
                      ),
                    ],
                  ),
                  StatusBadge(label: b.status, style: BadgeStyle.success),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rental Schedule Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RENTAL DURATION & SCHEDULE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline, color: AppColors.primaryLight, size: 18),
                      const SizedBox(width: 8),
                      Text('Start: ${dateFormatter.format(b.startDate)}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.stop_circle_outlined, color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Text('End: ${dateFormatter.format(b.endDate)}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Handover Verification Protocol (Student 3 key feature)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DUAL-PARTY HANDOVER PROTOCOL',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  _protocolStep(
                    title: '1. Equipment Pickup Confirmation',
                    isDone: b.pickupVerified,
                    desc: 'Equipment owner generates single-use token; renter scans camera QR to verify receipt.',
                  ),
                  const SizedBox(height: 12),
                  _protocolStep(
                    title: '2. Return & Post-Inspection',
                    isDone: b.returnVerified,
                    desc: 'Renter generates return token; owner inspects condition before confirming return.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment & Escrow Overview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL RENTAL FEE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      Text(
                        currencyFormatter.format(b.totalRentalFee),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryLight),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.shield_outlined, size: 16),
                    label: const Text('Escrow Details'),
                    onPressed: () => context.push('/escrow'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Actions
            AppButton(
              text: 'Show Handover QR Code',
              icon: Icons.qr_code,
              onPressed: () => context.push('/bookings/qr/${b.id}'),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month, size: 18),
              label: const Text('Request Schedule Extension'),
              onPressed: _handleExtend,
            ),
            const SizedBox(height: 12),

            TextButton.icon(
              icon: const Icon(Icons.report_problem_outlined, size: 18, color: AppColors.warning),
              label: const Text('File Damage Claim / Dispute', style: TextStyle(color: AppColors.warning)),
              onPressed: () => context.push('/escrow/claim/${b.id}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _protocolStep({required String title, required bool isDone, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isDone ? AppColors.primaryLight : AppColors.textMuted,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDone ? AppColors.primaryLight : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
