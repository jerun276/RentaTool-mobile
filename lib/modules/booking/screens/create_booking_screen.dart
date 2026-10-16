import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../catalog/models/equipment_model.dart';
import '../../escrow/services/escrow_service.dart';
import '../../identity/providers/auth_provider.dart';
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

  List<DateTimeRange> _bookedRanges = [];
  bool _isLoadingBookings = false;
  late DateTime _currentMonth;
  bool _isSelectingEndDate = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    if (widget.equipment != null) {
      _equipmentIdController.text = widget.equipment!.id;
      _ownerIdController.text = widget.equipment!.ownerId;
      _dailyRateController.text = widget.equipment!.dailyRate.toStringAsFixed(0);
    } else {
      _equipmentIdController.text = '';
      _ownerIdController.text = '';
      _dailyRateController.text = '';
    }
    _loadBookedDates();
  }

  Future<void> _loadBookedDates() async {
    final eqId = _equipmentIdController.text.trim();
    if (eqId.isEmpty) return;

    setState(() => _isLoadingBookings = true);

    final Set<String> seenRangeKeys = {};
    final List<DateTimeRange> ranges = [];

    void addRange(DateTime start, DateTime end) {
      final localStart = start.toLocal();
      final localEnd = end.toLocal();
      final s = DateTime(localStart.year, localStart.month, localStart.day);
      final e = DateTime(localEnd.year, localEnd.month, localEnd.day);
      final key = '${s.toIso8601String()}_${e.toIso8601String()}';
      if (!seenRangeKeys.contains(key)) {
        seenRangeKeys.add(key);
        ranges.add(DateTimeRange(start: s, end: e));
      }
    }

    // 1. If equipment is currently active in another rental, mark next 3 days as booked
    if (widget.equipment != null && widget.equipment!.status.toLowerCase() == 'rented') {
      final now = DateTime.now();
      addRange(
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day).add(const Duration(days: 3)),
      );
    }

    // 2. Fetch fleet bookings for this equipment (bypasses user filter so new renter sees ALL bookings on this tool)
    try {
      final service = ref.read(bookingServiceProvider);
      final eqBookings = await service.getBookingsForEquipment(eqId);
      for (final b in eqBookings) {
        if (!b.isCancelled) {
          addRange(b.startDate, b.endDate);
        }
      }
    } catch (_) {}

    // Fallback: active bookings from provider
    if (ranges.isEmpty) {
      try {
        final active = await ref.read(bookingServiceProvider).getActiveBookings();
        for (final b in active) {
          if (b.equipmentId.toLowerCase() == eqId.toLowerCase() && !b.isCancelled) {
            addRange(b.startDate, b.endDate);
          }
        }
      } catch (_) {
        final active = ref.read(bookingProvider).activeBookings;
        for (final b in active) {
          if (b.equipmentId.toLowerCase() == eqId.toLowerCase() && !b.isCancelled) {
            addRange(b.startDate, b.endDate);
          }
        }
      }
    }

    // 3. Parse any booked dates in specificationsJson if present
    if (widget.equipment != null && widget.equipment!.specificationsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(widget.equipment!.specificationsJson);
        if (decoded is Map && decoded['bookedDates'] is List) {
          for (final item in decoded['bookedDates']) {
            if (item is Map && item['start'] != null && item['end'] != null) {
              final s = DateTime.tryParse(item['start'].toString());
              final e = DateTime.tryParse(item['end'].toString());
              if (s != null && e != null) {
                addRange(s, e);
              }
            }
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _bookedRanges = ranges;
        _isLoadingBookings = false;
        _ensureValidInitialDates();
      });
    }
  }

  bool _isDateBooked(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    for (final r in _bookedRanges) {
      final s = DateTime(r.start.year, r.start.month, r.start.day);
      final e = DateTime(r.end.year, r.end.month, r.end.day);
      if (!d.isBefore(s) && !d.isAfter(e)) {
        return true;
      }
    }
    return false;
  }

  bool _hasConflict(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    for (final r in _bookedRanges) {
      final rStart = DateTime(r.start.year, r.start.month, r.start.day);
      final rEnd = DateTime(r.end.year, r.end.month, r.end.day);
      if (!s.isAfter(rEnd) && !e.isBefore(rStart)) {
        return true;
      }
    }
    return false;
  }

  void _ensureValidInitialDates() {
    final now = DateTime.now();
    DateTime candidateStart = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    while (_isDateBooked(candidateStart) && candidateStart.isBefore(now.add(const Duration(days: 90)))) {
      candidateStart = candidateStart.add(const Duration(days: 1));
    }
    DateTime candidateEnd = candidateStart.add(const Duration(days: 3));
    while (_hasConflict(candidateStart, candidateEnd) && candidateEnd.isAfter(candidateStart)) {
      candidateEnd = candidateEnd.subtract(const Duration(days: 1));
    }
    if (candidateEnd.isBefore(candidateStart)) {
      candidateEnd = candidateStart;
    }
    _startDate = candidateStart;
    _endDate = candidateEnd;
  }

  void _onDateTapped(DateTime day) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final target = DateTime(day.year, day.month, day.day);

    if (target.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot select past dates.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isDateBooked(target)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('${DateFormat('MMM dd, yyyy').format(target)} is already booked and unavailable.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _errorMessage = null;

      if (!_isSelectingEndDate) {
        // First tap: set Start Date
        _startDate = target;
        _endDate = target;
        _isSelectingEndDate = true;
      } else {
        // Second tap: set End Date
        if (target.isBefore(_startDate)) {
          _startDate = target;
          _endDate = target;
          _isSelectingEndDate = true;
        } else {
          if (_hasConflict(_startDate, target)) {
            _errorMessage = 'Selected range includes booked/unavailable dates. Please pick continuous available dates.';
            _startDate = target;
            _endDate = target;
            _isSelectingEndDate = true;
          } else {
            _endDate = target;
            _isSelectingEndDate = false;
          }
        }
      }
    });
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

  double get _calculatedDeposit {
    if (widget.equipment != null && widget.equipment!.replacementValue > 0) {
      return widget.equipment!.replacementValue * 0.15;
    }
    final rate = _dailyRate > 0 ? _dailyRate : (widget.equipment?.dailyRate ?? 5000.0);
    return rate * 3;
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
      if (_hasConflict(picked.start, picked.end)) {
        setState(() {
          _errorMessage = 'Selected range (${DateFormat('MMM dd').format(picked.start)} - ${DateFormat('MMM dd').format(picked.end)}) overlaps with an unavailable booked date. Please select available dates.';
        });
        return;
      }
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

    if (_hasConflict(_startDate, _endDate)) {
      setState(() {
        _errorMessage = 'Selected rental dates overlap with an existing booking. Please select only available dates.';
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

      // Auto-preauthorize security deposit in escrow so it appears immediately under Escrow Tab in "Held" status
      try {
        final authState = ref.read(authProvider);
        final renterId = authState.user?.id ?? '';
        final depositAmount = (widget.equipment != null && widget.equipment!.replacementValue > 0)
            ? (widget.equipment!.replacementValue * 0.15)
            : (rate * 3);
        if (renterId.isNotEmpty && ownId.isNotEmpty) {
          await ref.read(escrowServiceProvider).preAuthorizeDeposit(
            bookingId: newBooking.id,
            renterId: renterId,
            ownerId: ownId,
            depositAmount: depositAmount > 0 ? depositAmount : 15000.0,
          );
          // Booking intentionally stays 'Requested' until the owner accepts it.
        }
      } catch (err) {
        debugPrint('Auto escrow pre-auth notice: $err');
      }

      // Refresh active bookings provider
      ref.read(bookingProvider.notifier).fetchActiveBookings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Booking request sent! Waiting for the owner to accept.'),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.equipment!.categoryName,
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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

            // 2. Schedule Date Range Picker Card (Calendar showing available vs booked dates)
            _buildCalendarCard(dateFormatter),
            const SizedBox(height: 20),

            // 3. Technical Parameters (if equipment not pre-passed)
            if (widget.equipment == null) ...[
              AppTextField(
                controller: _equipmentIdController,
                label: 'Equipment ID (GUID)',
                hintText: 'Enter Equipment ID',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _ownerIdController,
                label: 'Equipment Owner ID (GUID)',
                hintText: 'Enter Equipment Owner ID',
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
                      Text('Daily Rate ($_rentalDays days)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text('${currencyFormatter.format(_dailyRate)} / day', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text('Refundable Deposit (Escrow Hold)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                      Text(
                        currencyFormatter.format(_calculatedDeposit),
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
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
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Escrow Pre-Authorization: A refundable security deposit hold of ${currencyFormatter.format(_calculatedDeposit)} will be secured in escrow upon booking. Funds are 100% returned upon safe equipment handover and return inspection.',
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
                  color: AppColors.error.withValues(alpha: 0.12),
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

  Widget _buildCalendarCard(DateFormat dateFormatter) {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = (firstDayOfMonth.weekday - 1) % 7;
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final canGoPrev = _currentMonth.isAfter(DateTime(today.year, today.month, 1));
    final canGoNext = _currentMonth.isBefore(DateTime(today.year, today.month + 5, 1));

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELECT RENTAL SCHEDULE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Available dates are selectable. Booked dates are unavailable.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              if (_isLoadingBookings)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Month navigation bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: canGoPrev
                      ? () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                          });
                        }
                      : null,
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: canGoNext
                      ? () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Day of week headers
          Row(
            children: const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((label) {
              return Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          for (int r = 0; r < rows; r++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  for (int c = 0; c < 7; c++) ...[
                    Expanded(
                      child: _buildDayCell(r, c, firstWeekday, daysInMonth, today),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _legendItem(color: AppColors.surfaceElevated, border: AppColors.border, label: 'Available'),
              _legendItem(color: AppColors.primaryLight, label: 'Selected Range', isSelected: true),
              _legendItem(color: AppColors.error.withValues(alpha: 0.15), border: AppColors.error, label: 'Booked / Unavailable', isBooked: true),
            ],
          ),
          const SizedBox(height: 14),

          // Selected Period Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Date', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(dateFormatter.format(_startDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const Icon(Icons.arrow_forward, size: 16, color: AppColors.primaryLight),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('End Date', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(dateFormatter.format(_endDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Rental: $_rentalDays ${_rentalDays == 1 ? 'day' : 'days'}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
              ),
              TextButton.icon(
                icon: const Icon(Icons.date_range, size: 14),
                label: const Text('Date Range Dialog', style: TextStyle(fontSize: 11)),
                onPressed: _pickDateRange,
              ),
            ],
          ),

          // Note if booked dates exist for this item
          if (_bookedRanges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.event_busy, color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Unavailable / Reserved Dates on Asset:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _bookedRanges.map((r) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          '${DateFormat('MMM dd').format(r.start)} - ${DateFormat('MMM dd, yyyy').format(r.end)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayCell(int r, int c, int firstWeekday, int daysInMonth, DateTime today) {
    final cellIndex = r * 7 + c;
    final dayNumber = cellIndex - firstWeekday + 1;

    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: 36);
    }

    final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
    final isPast = date.isBefore(today);
    final isBooked = _isDateBooked(date);

    final startOnly = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endOnly = DateTime(_endDate.year, _endDate.month, _endDate.day);
    final isSelectedStart = date.isAtSameMomentAs(startOnly);
    final isSelectedEnd = date.isAtSameMomentAs(endOnly);
    final isSelectedRange = !date.isBefore(startOnly) && !date.isAfter(endOnly);

    BoxDecoration decoration;
    TextStyle textStyle;

    if (isBooked) {
      decoration = BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.18),
        border: Border.all(color: AppColors.error),
        borderRadius: BorderRadius.circular(6),
      );
      textStyle = const TextStyle(
        color: AppColors.error,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.lineThrough,
        fontSize: 11,
      );
    } else if (isSelectedStart || isSelectedEnd) {
      decoration = BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      );
      textStyle = const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12);
    } else if (isSelectedRange) {
      decoration = BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
      );
      textStyle = const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600, fontSize: 12);
    } else if (isPast) {
      decoration = const BoxDecoration();
      textStyle = TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4), fontSize: 12);
    } else {
      decoration = BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      );
      textStyle = TextStyle(color: AppColors.textPrimary, fontSize: 12);
    }

    return GestureDetector(
      onTap: (isPast || isBooked)
          ? () {
              if (isBooked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.error,
                    content: Text('${DateFormat('MMM dd, yyyy').format(date)} is already booked and unavailable.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          : () => _onDateTapped(date),
      child: Container(
        height: 36,
        margin: const EdgeInsets.all(2),
        decoration: decoration,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$dayNumber', style: textStyle),
            if (isBooked)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'Booked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    Color? border,
    required String label,
    bool isSelected = false,
    bool isBooked = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: border != null ? Border.all(color: border) : null,
          ),
          child: isBooked
              ? const Center(
                  child: Text(
                    '✕',
                    style: TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
