import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/damage_claim_model.dart';
import '../providers/escrow_provider.dart';
import '../../identity/providers/auth_provider.dart';
import '../../identity/models/user_model.dart';

class EscrowOverviewScreen extends ConsumerWidget {
  const EscrowOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final escrowState = ref.watch(escrowProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'en_LK', symbol: 'LKR ', decimalDigits: 0);
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isOwnerOrAdmin = currentUser?.role == UserRole.owner || currentUser?.role == UserRole.admin;
    final isRenter = currentUser?.role == UserRole.renter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escrow & Damage Disputes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: () => ref.read(escrowProvider.notifier).fetchClaims(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Escrow Trust Banner (Tailored for Renter vs Owner/Admin)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: isDark ? AppColors.primaryLight : AppColors.primaryDark, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        isRenter ? 'Protected Renter Escrow Vault' : 'Automated Pre-Auth Escrow Vault',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRenter
                        ? 'Your rental security deposits are securely locked in pre-authorization escrow and automatically refunded in full upon safe return. Any owner claim is subject to AI telemetry evaluation and your fair rebuttal.'
                        : 'Contractor security deposits are securely held in escrow until mutual handover verification. As an equipment owner, you can file damage claims with photo evidence within the return inspection window.',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Claims Header & Role-Tailored Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACTIVE DAMAGE CLAIMS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: textMuted,
                  ),
                ),
                if (isOwnerOrAdmin)
                  TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('File Claim', style: TextStyle(fontSize: 12)),
                    onPressed: () => context.push('/escrow/claim-new'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x2210B981) : const Color(0x1510B981),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 12, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'DEPOSIT PROTECTED',
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
            ),
            const SizedBox(height: 8),

            // Claims List
            Builder(
              builder: (context) {
                if (escrowState.isLoading && escrowState.claims.isEmpty) {
                  return const LoadingIndicator(message: 'Loading disputes & claims...');
                }

                if (escrowState.errorMessage != null && escrowState.claims.isEmpty) {
                  return ErrorView(
                    message: escrowState.errorMessage!,
                    onRetry: () => ref.read(escrowProvider.notifier).fetchClaims(),
                  );
                }

                if (escrowState.claims.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.verified_outlined, size: 36, color: AppColors.success),
                          const SizedBox(height: 8),
                          Text(
                            'Zero Unresolved Disputes',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isRenter
                                ? 'Your equipment rentals operate with clean return telemetry. All security deposits are intact.'
                                : 'All current fleet rentals are operating with clean handover telemetry. No incident claims filed.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: escrowState.claims.length,
                  itemBuilder: (context, index) {
                    final claim = escrowState.claims[index];
                    return _claimCard(context, claim, currencyFormatter, textPrimary: textPrimary, textMuted: textMuted);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _claimCard(BuildContext context, DamageClaimModel claim, NumberFormat formatter, {required Color textPrimary, required Color textMuted}) {
    BadgeStyle badgeStyle;
    switch (claim.status.name.toLowerCase()) {
      case 'approved':
      case 'settled':
        badgeStyle = BadgeStyle.success;
        break;
      case 'underaievaluation':
        badgeStyle = BadgeStyle.purple;
        break;
      case 'pendingstaffapproval':
      case 'filed':
        badgeStyle = BadgeStyle.warning;
        break;
      case 'rejected':
        badgeStyle = BadgeStyle.error;
        break;
      default:
        badgeStyle = BadgeStyle.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/escrow/claim/${claim.claimId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CLAIM-${claim.claimId.isNotEmpty ? claim.claimId.substring(0, claim.claimId.length >= 4 ? 4 : claim.claimId.length).toUpperCase() : '0000'}',
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  StatusBadge(label: claim.status.displayLabel, style: badgeStyle),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                claim.damageDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROPOSED DEDUCTION',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textMuted),
                      ),
                      Text(
                        formatter.format(claim.proposedDeduction),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.warning),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
