import 'dart:convert';
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
import '../widgets/batch_availability_dialog.dart';
import '../widgets/wear_progress_bar.dart';
import '../../identity/providers/auth_provider.dart';
import '../../identity/models/user_model.dart';

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
  int _selectedPhotoIdx = 0;

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

  Map<String, dynamic> _parseSpecs(String specsJson) {
    try {
      final decoded = jsonDecode(specsJson);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
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
    final specsMap = _parseSpecs(eq.specificationsJson);
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isRenter = currentUser?.role == UserRole.renter;
    final isNicVerified = currentUser?.isVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(eq.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined, size: 22),
            tooltip: 'Maintenance History',
            onPressed: () => context.push('/catalog/history/${eq.id}'),
          ),
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
            // Image Preview Container
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (eq.images.isNotEmpty)
                    Image.network(
                      eq.images[_selectedPhotoIdx.clamp(0, eq.images.length - 1)].imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackCenterIcon(),
                    )
                  else
                    _fallbackCenterIcon(),
                  // Top Status Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: StatusBadge(
                      label: isLocked ? 'LOCKED' : eq.status,
                      style: isLocked ? BadgeStyle.error : BadgeStyle.success,
                    ),
                  ),
                  // Angle Label
                  if (eq.images.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xCC000000),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ANGLE: ${eq.images[_selectedPhotoIdx.clamp(0, eq.images.length - 1)].angle.toUpperCase()}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Multi-Angle Thumbnail Strip
            if (eq.images.length > 1) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: eq.images.length,
                  itemBuilder: (context, idx) {
                    final isSelected = idx == _selectedPhotoIdx;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPhotoIdx = idx),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryLight : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          eq.images[idx].imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.image, size: 20, color: AppColors.textMuted),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Title and Category
            Text(
              eq.title,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0x2610B981),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    eq.categoryName,
                    style: const TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(eq.location, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 20),

            // 60-Day Wear Status Card (Component 2 key specification)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLocked ? const Color(0x1AEF4444) : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLocked ? AppColors.wearLockout : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'WEAR & MAINTENANCE TELEMETRY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        isLocked ? 'LOCKOUT TRIGGERED' : '${eq.daysUntilLockout}d until lockout',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? AppColors.wearLockout : AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  WearProgressBar(daysAccumulated: eq.totalRentalDaysAccumulated),
                  const SizedBox(height: 10),
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
            Text(
              'Equipment Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              eq.description.isNotEmpty ? eq.description : 'No additional description provided.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Technical Specifications List (if present)
            if (specsMap.isNotEmpty) ...[
              Text(
                'Technical Specifications',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: specsMap.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Text(e.value.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

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
                      Text(
                        'RENTAL RATE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      Text(
                        currencyFormatter.format(eq.dailyRate),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryLight),
                      ),
                      Text('per 24-hour day', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ESTIMATED VALUE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      Text(
                        currencyFormatter.format(eq.replacementValue),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text('Deposit Pre-Auth Base', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Renter NIC Document Validation Notice
            if (isRenter && !isNicVerified) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NIC Document Verification Required',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You must validate your Sri Lankan NIC before renting or receiving machinery.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => context.push('/kyc-submit'),
                      child: const Text('Verify NIC'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (isRenter && isNicVerified) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: AppColors.success, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'NIC Verified — You are authorized to rent and receive this equipment.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            AppButton(
              text: isLocked
                  ? 'Unavailable (Under Maintenance Lockout)'
                  : (isRenter && !isNicVerified)
                      ? 'Verify NIC to Rent Equipment'
                      : 'Reserve Equipment Now',
              variant: (isLocked || (isRenter && !isNicVerified))
                  ? AppButtonVariant.secondary
                  : AppButtonVariant.primary,
              icon: (isRenter && !isNicVerified)
                  ? Icons.badge_outlined
                  : Icons.calendar_month_outlined,
              onPressed: isLocked
                  ? null
                  : () {
                      if (currentUser == null) {
                        context.push('/login');
                        return;
                      }
                      if (isRenter && !isNicVerified) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surfaceElevated,
                            title: const Row(
                              children: [
                                Icon(Icons.shield_outlined, color: AppColors.warning),
                                SizedBox(width: 8),
                                Text('NIC Verification Required', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            content: Text(
                              'In accordance with RentaTool LK regulations, renters must submit and validate a valid Sri Lankan NIC document before acquiring or receiving machinery.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.upload_file, size: 16),
                                label: const Text('Validate NIC Now'),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  context.push('/kyc-submit');
                                },
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      context.push('/bookings', extra: eq);
                    },
            ),
            const SizedBox(height: 10),

            // Check Date Range Availability & Lockout Action
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range_outlined, size: 18),
              label: const Text('Check Period Availability & Lockout'),
              onPressed: () => BatchAvailabilityDialog.show(context, [eq]),
            ),
            const SizedBox(height: 10),

            // View Maintenance History Action
            OutlinedButton.icon(
              icon: const Icon(Icons.history_outlined, size: 18),
              label: const Text('View Maintenance & Inspection History'),
              onPressed: () => context.push('/catalog/history/${eq.id}'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _fallbackCenterIcon() {
    return Center(
      child: Icon(Icons.precision_manufacturing_outlined, size: 80, color: AppColors.textMuted),
    );
  }
}
