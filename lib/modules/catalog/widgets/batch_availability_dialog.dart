import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/batch_availability_model.dart';
import '../models/equipment_model.dart';
import '../services/catalog_service.dart';

class BatchAvailabilityDialog extends ConsumerStatefulWidget {
  final List<EquipmentModel> equipmentList;

  const BatchAvailabilityDialog({
    super.key,
    required this.equipmentList,
  });

  static Future<void> show(BuildContext context, List<EquipmentModel> equipmentList) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BatchAvailabilityDialog(equipmentList: equipmentList),
    );
  }

  @override
  ConsumerState<BatchAvailabilityDialog> createState() => _BatchAvailabilityDialogState();
}

class _BatchAvailabilityDialogState extends ConsumerState<BatchAvailabilityDialog> {
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 4));
  bool _isLoading = false;
  BatchAvailabilityResultModel? _result;
  String? _errorMessage;

  final _dateFormat = DateFormat('MMM dd, yyyy');

  Future<void> _checkAvailability() async {
    if (widget.equipmentList.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(catalogServiceProvider);
      final res = await service.checkBatchAvailability(
        equipmentIds: widget.equipmentList.map((e) => e.id).toList(),
        desiredStartDate: _startDate,
        desiredEndDate: _endDate,
      );
      if (mounted) {
        setState(() {
          _result = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to evaluate fleet availability. Please check connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
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
        _result = null;
      });
      _checkAvailability();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAvailability();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fleet Wear & Dispatch Safety',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Algorithmic 60-Day Policy Lockout Check',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Selector Button
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range_outlined, size: 18, color: AppColors.primaryLight),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rental Period: ${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  const Text('Change', style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Result content
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingIndicator(message: 'Evaluating maintenance limits...'))
                : _errorMessage != null
                    ? Center(
                        child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                      )
                    : _result == null
                        ? const SizedBox.shrink()
                        : _buildResultView(_result!),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(BatchAvailabilityResultModel result) {
    return ListView(
      children: [
        // Summary metrics
        Row(
          children: [
            _metricBox(
              label: 'AVAILABLE',
              count: result.totalAvailable,
              color: AppColors.success,
            ),
            const SizedBox(width: 12),
            _metricBox(
              label: 'POLICY LOCKED',
              count: result.totalLockedOut,
              color: result.hasLockouts ? AppColors.wearLockout : AppColors.textMuted,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Locked Out Items List
        if (result.hasLockouts) ...[
          const Text(
            'LOCKED OUT TOOLS (MANDATORY SERVICING)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColors.wearLockout,
            ),
          ),
          const SizedBox(height: 8),
          ...result.lockedOutItems.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x22EF4444),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.wearLockout),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                        ),
                        const StatusBadge(label: 'BLOCKED', style: BadgeStyle.error),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accumulated: ${item.accumulatedRentalDays} / 60 days',
                      style: const TextStyle(fontSize: 12, color: AppColors.wearLockout, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.requiredAction,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],

        // Available Items List
        const Text(
          'DISPATCH READY MACHINES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        ...result.availableItems.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          'Wear: ${item.accumulatedDays} days accumulated',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const StatusBadge(label: 'READY', style: BadgeStyle.success),
                ],
              ),
            )),
      ],
    );
  }

  Widget _metricBox({required String label, required int count, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
