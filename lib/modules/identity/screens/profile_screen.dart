import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile & Trust'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EditProfileScreen(user: user),
              ),
            ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundImage: user.profilePhotoPath == null
                        ? null
                        : FileImage(File(user.profilePhotoPath!)),
                    child: user.profilePhotoPath != null
                        ? null
                        : Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            StatusBadge(
                              label: user.role.name,
                              style: BadgeStyle.purple,
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
                      const Text(
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
                      const Text(
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
                  const Text(
                    'Higher trust scores unlock reduced escrow pre-authorizations and automatic booking confirmations across Sri Lanka.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  if (trustScoreAsync.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text('Refreshing trust score...',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // KYC Action Card
            if (!user.isVerified)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete National Identity Verification',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFB95F),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Upload your Sri Lankan NIC photo to unlock unrestricted equipment rental access.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
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
        ),
      ),
    );
  }

  String _tierForScore(int score) {
    if (score >= 80) return 'Tier A';
    if (score >= 60) return 'Tier B';
    return 'Tier C';
  }
}
