import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/equipment_model.dart';
import '../services/catalog_service.dart';
import '../widgets/wear_progress_bar.dart';

class EquipmentDetailScreen extends ConsumerStatefulWidget {
  final String equipmentId;

  const EquipmentDetailScreen({super.key, required this.equipmentId});

  @override
  ConsumerState<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends ConsumerState<EquipmentDetailScreen> {
  EquipmentModel? _equipment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(catalogServiceProvider);
      final item = await service.getEquipmentById(widget.equipmentId);
      setState(() {
        _equipment = item;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load equipment details.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Equipment Details')),
        body: const LoadingIndicator(message: 'Loading asset specifications...'),
      );
    }

    if (_error != null || _equipment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Equipment Details')),
        body: ErrorView(
          message: _error ?? 'Equipment not found',
          onRetry: _fetchDetail,
        ),
      );
    }

    final eq = _equipment!;
    final currencyFormatter = NumberFormat.currency(locale: 'en_LK', symbol: 'LKR ', decimalDigits: 0);
    final isLocked = eq.isWearLocked;

    return Scaffold(
      appBar: AppBar(
        title: Text(eq.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined, size: 20),
            tooltip: 'Condition Inspection',
            onPressed: () => context.push('/catalog/inspection/${eq.id}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview Card
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.precision_manufacturing_outlined, size: 80, color: AppColors.textMuted),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: StatusBadge(
                      label: isLocked ? 'LOCKED' : eq.status,
                      style: isLocked ? BadgeStyle.error : BadgeStyle.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title and Category
            Text(
              eq.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    eq.categoryName,
                    style: const TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(eq.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 20),

            // 60-Day Wear Status Card (Component 2 specification)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLocked ? AppColors.wearLockout.withOpacity(0.1) : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLocked ? AppColors.wearLockout.withOpacity(0.4) : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WEAR & MAINTENANCE TELEMETRY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  WearProgressBar(daysAccumulated: eq.totalRentalDaysAccumulated),
                  const SizedBox(height: 8),
                  Text(
                    isLocked
                      ? '⚠️ Asset has reached or exceeded the 60-day operational wear threshold and is temporarily delisted pending safety overhaul inspection.'
                      : '✓ Asset is certified healthy and available for immediate reservation.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isLocked ? AppColors.wearLockout : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Description
            const Text(
              'Equipment Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              eq.description.isNotEmpty ? eq.description : 'No additional description provided.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Pricing details
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
                        'RENTAL RATE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      Text(
                        currencyFormatter.format(eq.dailyRate),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryLight),
                      ),
                      const Text('per 24-hour day', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'ESTIMATED VALUE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      Text(
                        currencyFormatter.format(eq.replacementValue),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const Text('Deposit Pre-Auth Base', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Book Now Action
            AppButton(
              text: isLocked ? 'Unavailable (Under Maintenance)' : 'Reserve Equipment Now',
              variant: isLocked ? AppButtonVariant.secondary : AppButtonVariant.primary,
              icon: Icons.calendar_month_outlined,
              onPressed: isLocked
                  ? null
                  : () {
                      context.push('/bookings', extra: eq);
                    },
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: const Text('Log Condition Inspection'),
              onPressed: () => context.push('/catalog/inspection/${eq.id}'),
            ),
          ],
        ),
      ),
    );
  }
}
