import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../../booking/providers/booking_provider.dart';
import '../models/damage_claim_model.dart';
import '../models/escrow_hold_model.dart';
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
    final bookingState = ref.watch(bookingProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'en_LK', symbol: 'LKR ', decimalDigits: 0);
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isOwnerOrAdmin = currentUser?.role == UserRole.owner || currentUser?.role == UserRole.admin;
    final isRenter = currentUser?.role == UserRole.renter;

    // Check if there are active bookings that don't have an escrow hold yet
    final unheldBookings = bookingState.activeBookings.where((b) {
      return !escrowState.holds.any((h) => h.bookingId == b.id);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escrow Vault & Disputes'),
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

            // ─── 1. Active Escrow Security Deposits (Held) ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACTIVE ESCROW DEPOSITS (HELD)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: textMuted,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x2210B981) : const Color(0x1510B981),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        '${escrowState.holds.length} VAULT HOLDS',
                        style: const TextStyle(
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
            const SizedBox(height: 10),

            // Render Active Escrow Holds
            if (escrowState.holds.isNotEmpty)
              ...escrowState.holds.map((hold) => _escrowHoldCard(
                    context,
                    hold,
                    currencyFormatter,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    textSecondary: textSecondary,
                  )),

            // Pending Pre-Authorization Action Cards for active bookings without holds
            if (unheldBookings.isNotEmpty)
              ...unheldBookings.map((b) => _unheldBookingCard(
                    context,
                    ref,
                    b,
                    currencyFormatter,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  )),

            // Empty state if no holds and no pending bookings
            if (escrowState.holds.isEmpty && unheldBookings.isEmpty)
              _emptyEscrowVaultCard(isDark, textPrimary, textSecondary, isRenter),

            const SizedBox(height: 24),

            // ─── 2. Active Damage Claims & Disputes ───
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

  Widget _escrowHoldCard(
    BuildContext context,
    EscrowHoldModel hold,
    NumberFormat formatter, {
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color textSecondary,
  }) {
    final shortBooking = hold.bookingId.length > 8 ? hold.bookingId.substring(0, 8) : hold.bookingId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield, color: Color(0xFF10B981), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking #$shortBooking',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                      ),
                      Text(
                        'Security Deposit Pre-Auth',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              StatusBadge(
                label: hold.rawStatus.toUpperCase(),
                style: BadgeStyle.success,
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Locked Deposit in Vault', style: TextStyle(fontSize: 12, color: textMuted)),
              Text(
                formatter.format(hold.depositAmount),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gateway Transaction Ref', style: TextStyle(fontSize: 11, color: textMuted)),
              Text(
                hold.preAuthTransactionId.isNotEmpty ? hold.preAuthTransactionId : 'PA-LK-SECURE-VAULT',
                style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Deposit is safely held in escrow and released back to renter upon clean post-rental return verification.',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unheldBookingCard(
    BuildContext context,
    WidgetRef ref,
    dynamic b,
    NumberFormat formatter, {
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final displayCode = b.displayCode.isNotEmpty ? b.displayCode : (b.id.length > 8 ? b.id.substring(0, 8) : b.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Booking #$displayCode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
              const StatusBadge(label: 'PRE-AUTH READY', style: BadgeStyle.warning),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Security deposit pre-authorization is required before equipment handover.',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.lock_open, size: 16),
              label: const Text('Authorize Security Deposit (LKR 15,000)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final ok = await ref.read(preAuthorizeProvider.notifier).preAuthorize(
                  bookingId: b.id,
                  renterId: b.renterId,
                  ownerId: b.ownerId,
                  depositAmount: 15000.0,
                );
                if (ok) {
                  ref.read(escrowProvider.notifier).fetchClaims();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text('Security deposit pre-authorized and locked in Escrow vault!'),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyEscrowVaultCard(bool isDark, Color textPrimary, Color textSecondary, bool isRenter) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.lock_clock_outlined, size: 36, color: AppColors.primaryLight),
            const SizedBox(height: 8),
            Text(
              'No Active Escrow Holds',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              isRenter
                  ? 'When you reserve equipment, your refundable security deposit will appear here in Held status until handover return.'
                  : 'All fleet security deposits will be displayed here once contractors initiate rental reservations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 12),
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
