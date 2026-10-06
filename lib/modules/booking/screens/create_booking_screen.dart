import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../catalog/models/equipment_model.dart';
import '../models/create_booking_request.dart';
import '../providers/booking_provider.dart';
import '../services/booking_service.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final EquipmentModel? equipment;

  const CreateBookingScreen({super.key, this.equipment});

  @override
  ConsumerState<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 4));
  final _equipmentIdController = TextEditingController();
  final _ownerIdController = TextEditingController();
  final _dailyRateController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.equipment != null) {
      _equipmentIdController.text = widget.equipment!.id;
      _ownerIdController.text = widget.equipment!.ownerId;
      _dailyRateController.text = widget.equipment!.dailyRate.toStringAsFixed(0);
    } else {
      // Fallback deterministic dev IDs for testing
      _equipmentIdController.text = '22222222-2222-2222-2222-222222222222';
      _ownerIdController.text = '11111111-1111-1111-1111-111111111111';
      _dailyRateController.text = '3500';
    }
  }

  @override
  void dispose() {
    _equipmentIdController.dispose();
    _ownerIdController.dispose();
    _dailyRateController.dispose();
    super.dispose();
  }

  int get _rentalDays {
    final diff = _endDate.difference(_startDate).inDays;
    return diff <= 0 ? 1 : diff + 1;
  }

  double get _dailyRate {
    return double.tryParse(_dailyRateController.text.trim()) ?? 0.0;
  }

  double get _totalEstimatedFee {
    return _rentalDays * _dailyRate;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
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
        _startDate = picked.start;
        _endDate = picked.end;
        _errorMessage = null;
      });
    }
  }

  Future<void> _submitBooking() async {
    final eqId = _equipmentIdController.text.trim();
    final ownId = _ownerIdController.text.trim();
    final rate = _dailyRate;

    if (widget.equipment != null && widget.equipment!.isWearLocked) {
      setState(() {
        _errorMessage = 'Equipment is currently locked out for mandatory 60-day maintenance overhaul. Bookings are disabled.';
      });
      return;
    }

    if (eqId.isEmpty || ownId.isEmpty || rate <= 0) {
      setState(() {
        _errorMessage = 'Please complete all required equipment and pricing fields.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final request = CreateBookingRequestModel(
        equipmentId: eqId,
        ownerId: ownId,
        startDate: _startDate,
        endDate: _endDate,
        dailyRate: rate,
      );

      final service = ref.read(bookingServiceProvider);
      final newBooking = await service.createBooking(request);

      // Refresh active bookings provider
      ref.read(bookingProvider.notifier).fetchActiveBookings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Reservation successfully confirmed! Ready for pickup.'),
          ),
        );

        // Navigate to booking detail screen
        context.go('/bookings/detail/${newBooking.id}');
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
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_LK',
      symbol: 'LKR ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('EEE, MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserve Equipment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Equipment Preview Header
            if (widget.equipment != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.precision_manufacturing_outlined,
                        color: AppColors.primaryLight,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.equipment!.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.equipment!.categoryName,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currencyFormatter.format(widget.equipment!.dailyRate)} / day',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 2. Schedule Date Range Picker Card
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
                  const Text(
                    'SELECT RENTAL SCHEDULE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryLight.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Date', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              Text(dateFormatter.format(_startDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('End Date', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              Text(dateFormatter.format(_endDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Rental Duration: $_rentalDays ${_rentalDays == 1 ? 'day' : 'days'}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_calendar, size: 16),
                        label: const Text('Change Dates', style: TextStyle(fontSize: 12)),
                        onPressed: _pickDateRange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Technical Parameters (if equipment not pre-passed)
            if (widget.equipment == null) ...[
              AppTextField(
                controller: _equipmentIdController,
                label: 'Equipment ID (GUID)',
                hintText: 'e.g. 22222222-2222-2222-2222-222222222222',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _ownerIdController,
                label: 'Equipment Owner ID (GUID)',
                hintText: 'e.g. 11111111-1111-1111-1111-111111111111',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _dailyRateController,
                label: 'Daily Rental Rate (LKR)',
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
            ],

            // 4. Financial Breakdown & Escrow Notice
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
                      Text('Daily Rate ($_rentalDays days)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text('${currencyFormatter.format(_dailyRate)} / day', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL ESTIMATED RENTAL FEE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        currencyFormatter.format(_totalEstimatedFee),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Escrow Pre-Authorization Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryLight.withOpacity(0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.primaryLight, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Escrow Pre-Authorization: A refundable security deposit hold will be authorized upon booking. Funds are protected in escrow and released after return inspection.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6. Error Banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 7. Submit Action
            AppButton(
              text: (widget.equipment?.isWearLocked ?? false)
                  ? 'Locked: 60-Day Maintenance Required'
                  : 'Confirm & Reserve Equipment',
              icon: (widget.equipment?.isWearLocked ?? false)
                  ? Icons.lock_outline
                  : Icons.check_circle_outline,
              isLoading: _isSubmitting,
              onPressed: (widget.equipment?.isWearLocked ?? false) ? null : _submitBooking,
            ),
          ],
        ),
      ),
    );
  }
}
