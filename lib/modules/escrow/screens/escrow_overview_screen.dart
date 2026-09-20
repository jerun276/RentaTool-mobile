import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/damage_claim_model.dart';
import '../providers/escrow_provider.dart';

class EscrowOverviewScreen extends ConsumerWidget {
  const EscrowOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final escrowState = ref.watch(escrowProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'en_LK', symbol: 'LKR ', decimalDigits: 0);

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
            // Escrow Trust Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.primaryLight, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Automated Pre-Auth Escrow Vault',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryLight),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Security deposits are securely held in escrow until mutual handover verification. Any damage claim undergoes AI visual telemetry evaluation and fair human review.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Claims Header & Quick Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ACTIVE DAMAGE CLAIMS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('File Claim', style: TextStyle(fontSize: 12)),
                  onPressed: () => context.push('/escrow/claim-new'),
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
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.verified_outlined, size: 36, color: AppColors.success),
                          SizedBox(height: 8),
                          Text(
                            'Zero Unresolved Disputes',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'All current rentals are operating with clean handover telemetry.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                    return _claimCard(context, claim, currencyFormatter);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _claimCard(BuildContext context, DamageClaimModel claim, NumberFormat formatter) {
    BadgeStyle badgeStyle;
    switch (claim.status.toLowerCase()) {
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
                  StatusBadge(label: claim.status, style: badgeStyle),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                claim.damageDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROPOSED DEDUCTION',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      Text(
                        formatter.format(claim.proposedDeduction),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.warning),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
