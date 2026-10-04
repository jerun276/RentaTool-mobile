import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/token_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/identity_service.dart';
import '../services/local_profile_photo_service.dart';
import 'edit_profile_screen.dart';

final profileKycStatusProvider = FutureProvider.autoDispose.family<Map<String, String?>, String>((ref, userId) async {
  try {
    final sub = await ref.watch(identityServiceProvider).getMyKycSubmission(userId);
    if (sub != null) {
      await ref.read(tokenStorageServiceProvider).saveKycStatus(
        userId,
        sub.status,
        rejectionReason: sub.rejectionReason,
        documentNumber: sub.documentNumber,
      );
      return {
        'status': sub.status,
        'rejectionReason': sub.rejectionReason,
        'documentNumber': sub.documentNumber,
      };
    }
  } catch (_) {}

  final localStatus = await ref.read(tokenStorageServiceProvider).getKycStatus(userId);
  final localReason = await ref.read(tokenStorageServiceProvider).getKycRejectionReason(userId);
  final localDoc = await ref.read(tokenStorageServiceProvider).getKycDocumentNumber(userId);
  return {
    'status': localStatus ?? 'none',
    'rejectionReason': localReason,
    'documentNumber': localDoc,
  };
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  Future<void> _refreshAllData() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(authProvider.notifier).refreshProfile();
      ref.invalidate(trustScoreProvider(user.id));
      ref.invalidate(profileKycStatusProvider(user.id));
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source, UserModel user) async {
    setState(() => _isUploadingPhoto = true);
    try {
      final photoService = LocalProfilePhotoService();
      final path = await photoService.chooseAndSave(source: source);
      if (path == null) {
        if (mounted) setState(() => _isUploadingPhoto = false);
        return;
      }
      final cloudinary = ref.read(cloudinaryServiceProvider);
      final uploadedUrl = await cloudinary.uploadImage(
        path,
        folder: 'rentatool/profiles',
      );

      final updated = await ref.read(authProvider.notifier).updateProfile(
        name: user.name,
        phoneNumber: user.phoneNumber,
        profilePhotoUrl: uploadedUrl,
      );

      if (updated) {
        await ref.read(authProvider.notifier).saveLocalProfilePhoto(uploadedUrl);
        await ref.read(authProvider.notifier).refreshProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _showPhotoOptions(BuildContext context, UserModel user) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Profile Photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Take Photo (Camera)'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadPhoto(ImageSource.camera, user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadPhoto(ImageSource.gallery, user);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPendingStatusModal(BuildContext context, String? docNumber) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Verification In Progress',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your National Identity Card (NIC) was submitted successfully and is currently in the administrative review queue.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  if (docNumber != null && docNumber.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Document:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text('NIC ($docNumber)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const Text('Under Review ⏳', style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No further action is required from you at this time. You will receive notification as soon as verification completes.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showVerifiedStatusModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppColors.success, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Identity Verified',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your National Identity Card (NIC) has been approved by compliance administrators.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              'You have full access to machinery reservations, equipment fleet listings, and secure escrow transactions.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRejectedStatusModal(BuildContext context, String? reason, String userId, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Verification Declined',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your previous identity submission was declined by compliance administrators.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Admin Reason:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                    const SizedBox(height: 4),
                    Text(reason, style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Please re-upload clear photographs of both front and back of your NIC to unlock equipment access.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.push('/kyc-submit');
              ref.invalidate(profileKycStatusProvider(userId));
              ref.read(authProvider.notifier).refreshProfile();
            },
            child: const Text('Re-upload Documents', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showUnverifiedInfoModal(BuildContext context, String userId, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.assignment_ind_outlined, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Identity Verification',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Identity verification (NIC) is required by Sri Lankan rental regulations to ensure equipment security.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Please submit clear photos of both sides of your National Identity Card to unlock equipment rentals.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.push('/kyc-submit');
              ref.invalidate(profileKycStatusProvider(userId));
              ref.read(authProvider.notifier).refreshProfile();
            },
            child: const Text('Submit NIC', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  ImageProvider? _resolveAvatarImage(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final currentThemeMode = ref.watch(themeProvider);
    final isDarkMode = currentThemeMode == ThemeMode.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account Profile')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please sign in to view your profile.'),
              const SizedBox(height: 16),
              AppButton(
                text: 'Sign In',
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      );
    }

    final trustScoreAsync = ref.watch(trustScoreProvider(user.id));
    final liveScore = trustScoreAsync.valueOrNull?.score;
    final trustScore = liveScore ?? (user.trustScore > 0 ? user.trustScore : 50);
    final trustTier =
        trustScoreAsync.valueOrNull?.tier ?? _tierForScore(trustScore);

    final kycInfoAsync = ref.watch(profileKycStatusProvider(user.id));
    final kycInfo = kycInfoAsync.valueOrNull;
    final rawStatus = user.isVerified ? 'Approved' : (kycInfo?['status'] ?? 'none');
    final String kycStatus;
    if (user.isVerified || rawStatus.toLowerCase() == 'approved' || rawStatus == '2') {
      kycStatus = 'Approved';
    } else if (rawStatus.toLowerCase() == 'pending' || rawStatus == '1') {
      kycStatus = 'Pending';
    } else if (rawStatus.toLowerCase() == 'rejected' || rawStatus == '3') {
      kycStatus = 'Rejected';
    } else {
      kycStatus = rawStatus;
    }
    final rejectionReason = kycInfo?['rejectionReason'];
    final kycDocNumber = kycInfo?['documentNumber'];

    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile & Trust'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, size: 22),
            tooltip: 'Sync Profile & Trust',
            onPressed: () async {
              await _refreshAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile & trust score updated.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (trustScoreAsync.hasError &&
                  trustScoreAsync.error.toString().contains('401')) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session Expired',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Please sign in again to sync your live trust score (75 Points) and profile photo.',
                              style: TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ),
              ],
              // User Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _isUploadingPhoto ? null : () => _showPhotoOptions(context, user),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                            backgroundImage: _resolveAvatarImage(user.profilePhotoPath),
                            child: _isUploadingPhoto
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : (user.profilePhotoPath != null && user.profilePhotoPath!.isNotEmpty
                                    ? null
                                    : Text(
                                        user.name.isNotEmpty
                                            ? user.name[0].toUpperCase()
                                            : 'U',
                                        style: TextStyle(
                                          color: isDarkMode ? AppColors.primaryLight : AppColors.primaryDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      )),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDarkMode ? AppColors.darkSurface : Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => EditProfileScreen(user: user),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? AppColors.darkSurfaceLight
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 13,
                                      color: textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            StatusBadge(
                              label: user.role.displayName.toUpperCase(),
                              style: user.role == UserRole.owner
                                  ? BadgeStyle.info
                                  : (user.role == UserRole.admin
                                      ? BadgeStyle.purple
                                      : BadgeStyle.success),
                            ),
                            InkWell(
                              onTap: () {
                                if (kycStatus == 'Pending') {
                                  _showPendingStatusModal(context, kycDocNumber);
                                } else if (kycStatus == 'Approved' || user.isVerified) {
                                  _showVerifiedStatusModal(context);
                                } else if (kycStatus == 'Rejected') {
                                  _showRejectedStatusModal(context, rejectionReason, user.id, ref);
                                } else {
                                  _showUnverifiedInfoModal(context, user.id, ref);
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: StatusBadge(
                                label: user.isVerified || kycStatus == 'Approved'
                                    ? 'KYC VERIFIED'
                                    : (kycStatus == 'Pending'
                                        ? 'UNDER REVIEW'
                                        : (kycStatus == 'Rejected' ? 'RE-UPLOAD' : 'PENDING KYC')),
                                style: user.isVerified || kycStatus == 'Approved'
                                    ? BadgeStyle.success
                                    : (kycStatus == 'Pending'
                                        ? BadgeStyle.warning
                                        : (kycStatus == 'Rejected' ? BadgeStyle.error : BadgeStyle.info)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!user.isVerified && kycStatus != 'Approved') ...[
              const SizedBox(height: 16),
              if (kycInfoAsync.isLoading && kycInfo == null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Text('Checking verification status...', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ] else ...[
                // KYC Action Card
                InkWell(
                  onTap: kycStatus == 'Pending' ? () => _showPendingStatusModal(context, kycDocNumber) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kycStatus == 'Pending'
                            ? AppColors.warning.withValues(alpha: 0.4)
                            : (kycStatus == 'Rejected'
                                ? const Color(0xFFDC2626).withValues(alpha: 0.4)
                                : (isDarkMode ? AppColors.darkBorder : AppColors.lightBorder)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              kycStatus == 'Pending'
                                  ? Icons.hourglass_top_rounded
                                  : (kycStatus == 'Rejected'
                                      ? Icons.warning_amber_rounded
                                      : Icons.assignment_ind_outlined),
                              color: kycStatus == 'Pending'
                                  ? AppColors.warning
                                  : (isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              kycStatus == 'Pending'
                                  ? 'KYC Verification Under Review'
                                  : (kycStatus == 'Rejected'
                                      ? 'NIC Re-upload Requested'
                                      : 'Complete NIC Verification'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kycStatus == 'Pending'
                                    ? AppColors.warning
                                    : (isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          kycStatus == 'Pending'
                              ? 'Your NIC document has been uploaded and is currently being inspected by compliance administrators. You will receive notification once verified.'
                              : (kycStatus == 'Rejected'
                                  ? (rejectionReason != null && rejectionReason.isNotEmpty
                                      ? 'Admin Feedback: $rejectionReason\nPlease tap below to re-upload clear replacement photographs.'
                                      : 'Your previous submission was declined. Please re-upload clear photographs of your NIC.')
                                  : 'Upload your Sri Lankan NIC photo to unlock unrestricted equipment rental access.'),
                          style: TextStyle(
                            color: isDarkMode
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (kycStatus == 'Pending') ...[
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 16),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'In Administrative Queue',
                                          style: TextStyle(
                                            color: AppColors.warning,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                icon: const Icon(Icons.info_outline, size: 16),
                                label: const Text('Details'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onPressed: () => _showPendingStatusModal(context, kycDocNumber),
                              ),
                            ],
                          ),
                        ] else ...[
                          AppButton(
                            text: kycStatus == 'Rejected' ? 'Re-upload NIC Documents' : 'Submit NIC Documents',
                            variant: AppButtonVariant.primary,
                            icon: kycStatus == 'Rejected' ? Icons.replay_outlined : Icons.upload_file_outlined,
                            onPressed: () async {
                              await context.push('/kyc-submit');
                              ref.invalidate(profileKycStatusProvider(user.id));
                              ref.read(authProvider.notifier).refreshProfile();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),

            // Algorithmic Trust Score Card (Component 1 requirement)
            Container(
              padding: const EdgeInsets.all(20),
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
                        'ALGORITHMIC TRUST SCORE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      StatusBadge(
                          label: trustTier.toUpperCase(),
                          style: BadgeStyle.success),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$trustScore',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ 100 Points',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: trustScore.clamp(0, 100).toDouble() / 100,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Higher trust scores unlock reduced escrow pre-authorizations and automatic booking confirmations across Sri Lanka.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  if (trustScoreAsync.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text('Refreshing trust score...',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Appearance & Theme Mode Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF312E81).withValues(alpha: 0.35)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDarkMode
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: isDarkMode
                          ? const Color(0xFFA5B4FC)
                          : const Color(0xFFD97706),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dark Mode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDarkMode
                              ? 'Dark theme enabled'
                              : 'Default white theme enabled',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isDarkMode,
                    activeColor: AppColors.primary,
                    activeTrackColor: AppColors.primaryDark,
                    onChanged: (val) {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                  ),
                ],
              ),
            ),

            // Admin Management Section (Visible for Admin role)
            if (user.role == UserRole.admin) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
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
                          'SYSTEM ADMINISTRATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const StatusBadge(label: 'ADMIN', style: BadgeStyle.purple),
                      ],
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => context.push('/admin/categories'),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.category_outlined, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Categories & Dynamic Specs',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Create machinery categories & configure dynamic schema fields',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Owner Fleet Management Section (Visible for Owner role)
            if (user.role == UserRole.owner) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
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
                          'FLEET & DISPATCH CONTROLS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const StatusBadge(label: 'FLEET OWNER', style: BadgeStyle.info),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _profileActionTile(
                      icon: Icons.add_business_outlined,
                      iconColor: AppColors.primary,
                      title: 'List New Fleet Machinery',
                      subtitle: 'Add equipment specifications, daily rates & photo telemetry',
                      onTap: () => context.push('/catalog/add'),
                    ),
                    const SizedBox(height: 10),
                    _profileActionTile(
                      icon: Icons.report_problem_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'File Return Damage Claim',
                      subtitle: 'Submit escrow dispute with photographic evidence',
                      onTap: () => context.push('/escrow/claim-new'),
                    ),
                    const SizedBox(height: 10),
                    _profileActionTile(
                      icon: Icons.qr_code_scanner,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Scan Contractor Handover Token',
                      subtitle: 'Verify equipment pickup & GPS location clearance',
                      onTap: () => context.push('/bookings/scan'),
                    ),
                  ],
                ),
              ),
            ],

            // Renter Workspace Section (Visible for Renter role)
            if (user.role == UserRole.renter) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
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
                          'RENTER WORKSPACE & PRIVILEGES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const StatusBadge(label: 'RENTER', style: BadgeStyle.success),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _profileActionTile(
                      icon: Icons.search,
                      iconColor: AppColors.primary,
                      title: 'Browse Machinery Catalog',
                      subtitle: 'Reserve heavy equipment, power tools & power generators',
                      onTap: () => context.go('/catalog'),
                    ),
                    const SizedBox(height: 10),
                    _profileActionTile(
                      icon: Icons.radar,
                      iconColor: const Color(0xFF10B981),
                      title: 'Nearby Machinery Map',
                      subtitle: 'Find equipment within your target radius in Sri Lanka',
                      onTap: () => context.push('/bookings/map'),
                    ),
                    const SizedBox(height: 10),
                    _profileActionTile(
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF6366F1),
                      title: 'Escrow Security Deposit Holds',
                      subtitle: 'View protected deposit accounts and dispute clearance',
                      onTap: () => context.push('/escrow'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

  String _tierForScore(int score) {
    if (score >= 90) return 'Tier A+';
    if (score >= 75) return 'Tier A';
    if (score >= 50) return 'Tier B';
    return 'Tier C';
  }

  Widget _profileActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
