import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  ImageProvider? _resolveAvatarImage(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final trustScore = trustScoreAsync.valueOrNull?.score ?? user.trustScore;
    final trustTier =
        trustScoreAsync.valueOrNull?.tier ?? _tierForScore(trustScore);

    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile & Trust'),
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundImage: _resolveAvatarImage(user.profilePhotoPath),
                    child: user.profilePhotoPath != null && user.profilePhotoPath!.isNotEmpty
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
                        Row(
                          children: [
                            StatusBadge(
                              label: user.role.displayName.toUpperCase(),
                              style: user.role == UserRole.owner
                                  ? BadgeStyle.info
                                  : (user.role == UserRole.admin
                                      ? BadgeStyle.purple
                                      : BadgeStyle.success),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              label: user.isVerified
                                  ? 'KYC VERIFIED'
                                  : 'PENDING KYC',
                              style: user.isVerified
                                  ? BadgeStyle.success
                                  : BadgeStyle.warning,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!user.isVerified) ...[
              const SizedBox(height: 16),
              // KYC Action Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_ind_outlined,
                          color: isDarkMode
                              ? const Color(0xFFF87171)
                              : const Color(0xFFDC2626),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Complete NIC Verification',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? const Color(0xFFF87171)
                                : const Color(0xFFDC2626),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Upload your Sri Lankan NIC photo to unlock unrestricted equipment rental access.',
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'Submit NIC Documents',
                      variant: AppButtonVariant.primary,
                      icon: Icons.upload_file_outlined,
                      onPressed: () => context.push('/kyc-submit'),
                    ),
                  ],
                ),
              ),
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
    );
  }

  String _tierForScore(int score) {
    if (score >= 80) return 'Tier A';
    if (score >= 60) return 'Tier B';
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
