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
import '../widgets/booking_timeline_widget.dart';
import '../widgets/surge_extension_sheet.dart';
import '../../identity/providers/auth_provider.dart';
import '../../identity/models/user_model.dart';

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
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _openExtensionSheet() {
    if (_booking == null) return;
    SurgeExtensionSheet.show(context, _booking!, () {
      _fetchBooking();
    });
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
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isOwnerOrAdmin = currentUser?.role == UserRole.owner || currentUser?.role == UserRole.admin;
    final currencyFormatter = NumberFormat.currency(locale: 'en_LK', symbol: 'LKR ', decimalDigits: 0);
    final dateFormatter = DateFormat('EEEE, MMM dd, yyyy');

    BadgeStyle badgeStyle;
    switch (b.status.toLowerCase()) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(b.displayCode),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, size: 20),
            tooltip: 'Show Handover QR',
            onPressed: () => context.push('/bookings/qr/${b.id}'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: _fetchBooking,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Status Banner Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BOOKING STATUS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        b.status.toUpperCase(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryLight),
                      ),
                    ],
                  ),
                  StatusBadge(label: b.status, style: badgeStyle),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Visual Lifecycle Timeline (Student 3 Deliverable)
            BookingTimelineWidget(booking: b),
            const SizedBox(height: 20),

            // 3. Rental Schedule Card
            Container(
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
                        'RENTAL DURATION & SCHEDULE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      Text(
                        '${b.durationInDays} ${b.durationInDays == 1 ? 'day' : 'days'}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline, color: AppColors.primaryLight, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Start: ${dateFormatter.format(b.startDate)}', style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.stop_circle_outlined, color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('End: ${dateFormatter.format(b.endDate)}', style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Financial & Escrow Overview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
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
                        label: const Text('Escrow Ledger'),
                        onPressed: () => context.push('/escrow'),
                      ),
                    ],
                  ),
                  if (b.dailyRate > 0) ...[
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Calculated Daily Rate', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text('${currencyFormatter.format(b.dailyRate)} / day', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Handover QR Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Show Handover QR',
                    icon: Icons.qr_code,
                    fontSize: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                    onPressed: () => context.push('/bookings/qr/${b.id}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    text: 'Scan Handover QR',
                    variant: AppButtonVariant.outline,
                    icon: Icons.qr_code_scanner,
                    fontSize: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                    onPressed: () => context.push('/bookings/scan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 6. Dynamic Surge Schedule Extension
            if (b.canExtendSchedule)
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Extend Schedule (Dynamic Surge Preview)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.border),
                ),
                onPressed: _openExtensionSheet,
              ),
            const SizedBox(height: 12),

            // 7. Damage Claim Dispute Link (Only available to Equipment Owner or Admin)
            if (b.canDispute && isOwnerOrAdmin)
              TextButton.icon(
                icon: const Icon(Icons.report_problem_outlined, size: 18, color: AppColors.warning),
                label: const Text('File Damage Claim / Escrow Dispute', style: TextStyle(color: AppColors.warning)),
                onPressed: () => context.push('/escrow/claim/${b.id}'),
              ),
          ],
        ),
      ),
    );
  }
}
