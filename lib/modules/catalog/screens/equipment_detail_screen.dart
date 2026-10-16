import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/equipment_model.dart';
import '../services/catalog_service.dart';
import '../providers/catalog_provider.dart';
import '../widgets/batch_availability_dialog.dart';
import '../widgets/wear_progress_bar.dart';
import '../../identity/providers/auth_provider.dart';
import '../../identity/models/user_model.dart';
import '../../identity/services/identity_service.dart';

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

      Map<String, dynamic>? ownerProfile;
      if (item.ownerId.isNotEmpty && (item.ownerName.isEmpty || item.ownerPhoneNumber == null)) {
        try {
          final identityService = ref.read(identityServiceProvider);
          ownerProfile = await identityService.getPublicProfile(item.ownerId);
        } catch (_) {}
      }

      setState(() {
        if (ownerProfile != null && ownerProfile.isNotEmpty) {
          _equipment = EquipmentModel(
            id: item.id,
            ownerId: item.ownerId,
            ownerName: (ownerProfile['name']?.toString() ?? item.ownerName).isNotEmpty
                ? (ownerProfile['name']?.toString() ?? item.ownerName)
                : 'Equipment Owner',
            ownerPhoneNumber: ownerProfile['phoneNumber']?.toString() ?? item.ownerPhoneNumber,
            ownerIsVerified: (ownerProfile['isVerified'] == true) || item.ownerIsVerified,
            ownerTrustScore: (ownerProfile['trustScore'] as num?)?.toInt() ?? item.ownerTrustScore,
            ownerMemberSinceUtc: ownerProfile['memberSinceUtc']?.toString() ?? item.ownerMemberSinceUtc,
            ownerProfilePhotoUrl: ownerProfile['profilePhotoUrl']?.toString() ?? item.ownerProfilePhotoUrl,
            title: item.title,
            description: item.description,
            categoryId: item.categoryId,
            categoryName: item.categoryName,
            dailyRate: item.dailyRate,
            replacementValue: item.replacementValue,
            status: item.status,
            location: item.location,
            totalRentalDaysAccumulated: item.totalRentalDaysAccumulated,
            requiresMaintenanceCheck: item.requiresMaintenanceCheck,
            lastMaintenanceDateUtc: item.lastMaintenanceDateUtc,
            specificationsJson: item.specificationsJson,
            images: item.images,
          );
        } else {
          _equipment = item;
        }
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
    ref.watch(themeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

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
    final isAssetOwner = currentUser != null && currentUser.id == eq.ownerId;
    final isRenter = currentUser?.role == UserRole.renter;
    final isNicVerified = currentUser?.isVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(eq.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh',
            onPressed: () async {
              await _fetchDetail();
              ref.read(catalogProvider.notifier).fetchEquipment(isRefresh: true);
            },
          ),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchDetail();
          ref.read(catalogProvider.notifier).fetchEquipment(isRefresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview Container
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
                          color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryLight : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          eq.images[idx].imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.image, size: 20, color: textMuted),
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
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
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.location_on_outlined, size: 16, color: textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    eq.location,
                    style: TextStyle(color: textSecondary, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Equipment Owner & Trust Profile Card (Key trust signals for renter)
            _buildOwnerTrustCard(
              context,
              eq,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ),
            const SizedBox(height: 20),

            // 60-Day Wear Status Card (Component 2 key specification)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLocked ? const Color(0x1AEF4444) : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLocked ? AppColors.wearLockout : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
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

            // Asset Owner vs Renter Notice Banner
            if (isAssetOwner) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x223B82F6) : const Color(0x153B82F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: Color(0xFF3B82F6), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Listed Fleet Asset',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You are the registered owner of this machinery unit. You can log condition inspections and track wear telemetry.',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (isRenter && !isNicVerified) ...[
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

            // Action Buttons (Tailored for Owner vs Renter)
            if (isAssetOwner) ...[
              AppButton(
                text: 'Edit Machinery Details',
                variant: AppButtonVariant.secondary,
                icon: Icons.edit_outlined,
                onPressed: () async {
                  final updated = await context.push<bool>('/catalog/edit/${eq.id}', extra: eq);
                  if (updated == true) {
                    await _fetchDetail();
                    ref.read(catalogProvider.notifier).fetchEquipment(isRefresh: true);
                  }
                },
              ),
              const SizedBox(height: 10),
              AppButton(
                text: 'Log Pre-Dispatch Inspection',
                variant: AppButtonVariant.primary,
                icon: Icons.document_scanner_outlined,
                onPressed: () => context.push('/catalog/inspection/${eq.id}'),
              ),
            ] else ...[
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
            ],
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
      ),
    );
  }

  Widget _fallbackCenterIcon() {
    return Center(
      child: Icon(Icons.precision_manufacturing_outlined, size: 80, color: AppColors.textMuted),
    );
  }

  Widget _buildOwnerTrustCard(
    BuildContext context,
    EquipmentModel eq, {
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    final ownerName = eq.ownerName.trim().isNotEmpty ? eq.ownerName.trim() : 'Equipment Owner';
    final hasPhone = eq.ownerPhoneNumber != null && eq.ownerPhoneNumber!.trim().isNotEmpty;
    final trustScore = eq.ownerTrustScore > 0 ? eq.ownerTrustScore : 50;

    Color trustColor;
    String trustLabel;
    if (trustScore >= 80) {
      trustColor = const Color(0xFF10B981);
      trustLabel = 'High Trust';
    } else if (trustScore >= 50) {
      trustColor = const Color(0xFFF59E0B);
      trustLabel = 'Good Standing';
    } else {
      trustColor = const Color(0xFFEF4444);
      trustLabel = 'Building Trust';
    }

    String memberSinceText = 'Verified Community Member';
    if (eq.ownerMemberSinceUtc != null && eq.ownerMemberSinceUtc!.isNotEmpty) {
      try {
        final parsed = DateTime.parse(eq.ownerMemberSinceUtc!);
        memberSinceText = 'Member since ${DateFormat('MMM yyyy').format(parsed)}';
      } catch (_) {}
    }

    final initials = ownerName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .take(2)
        .join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: eq.ownerIsVerified
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      eq.ownerIsVerified ? Icons.verified_user : Icons.person_pin_outlined,
                      size: 14,
                      color: eq.ownerIsVerified ? const Color(0xFF10B981) : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'EQUIPMENT OWNER & TRUST PROFILE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (eq.ownerIsVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        'NIC Verified',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Owner Profile Row
          Row(
            children: [
              // Avatar with verified badge overlay
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    backgroundImage: (eq.ownerProfilePhotoUrl != null && eq.ownerProfilePhotoUrl!.isNotEmpty)
                        ? NetworkImage(eq.ownerProfilePhotoUrl!)
                        : null,
                    child: (eq.ownerProfilePhotoUrl == null || eq.ownerProfilePhotoUrl!.isEmpty)
                        ? Text(
                            initials.isNotEmpty ? initials : 'EO',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                            ),
                          )
                        : null,
                  ),
                  if (eq.ownerIsVerified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Name & Trust info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      memberSinceText,
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Trust score badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: trustColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield, size: 11, color: trustColor),
                              const SizedBox(width: 4),
                              Text(
                                '$trustScore/100 ($trustLabel)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: trustColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Contact Button
              if (hasPhone)
                IconButton.filledTonal(
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  tooltip: 'Contact Owner',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFF10B981),
                  ),
                  onPressed: () => _showContactOwnerSheet(context, ownerName, eq.ownerPhoneNumber!),
                ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Trust and Escrow guarantee footer
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Protected by RentaTool Escrow: Your security deposit is locked and only released upon certified return inspection.',
                    style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContactOwnerSheet(BuildContext context, String ownerName, String phone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0x2610B981),
                      child: Icon(Icons.phone, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact $ownerName',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Equipment Owner / Fleet Manager',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        phone,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        tooltip: 'Copy Number',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: phone));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Phone number copied to clipboard.'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Copy Phone Number',
                  icon: Icons.copy,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: phone));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone number copied to clipboard.'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
