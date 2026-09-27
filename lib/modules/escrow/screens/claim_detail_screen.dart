import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/damage_claim_model.dart';
import '../providers/escrow_provider.dart';

class ClaimDetailScreen extends ConsumerWidget {
  final String claimId;

  const ClaimDetailScreen({super.key, required this.claimId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(claimDetailProvider(claimId));

    // Surface snackbar messages reactively
    ref.listen(claimDetailProvider(claimId), (prev, next) {
      if (next.actionMessage != null && next.actionMessage != prev?.actionMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: next.actionSuccess ? AppColors.success : AppColors.error,
            content: Text(next.actionMessage!),
          ),
        );
        ref.read(claimDetailProvider(claimId).notifier).clearMessages();
        // Refresh the claim list
        ref.read(escrowProvider.notifier).fetchClaims();
      }
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(next.errorMessage!),
          ),
        );
        ref.read(claimDetailProvider(claimId).notifier).clearMessages();
      }
    });

    if (state.isLoadingClaim) {
      return Scaffold(
        appBar: AppBar(title: const Text('Claim Details')),
        body: const LoadingIndicator(message: 'Loading claim details...'),
      );
    }

    if (state.claim == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Claim Details')),
        body: ErrorView(
          message: state.errorMessage ?? 'Claim not found.',
          onRetry: () =>
              ref.read(claimDetailProvider(claimId).notifier).fetchClaim(),
        ),
      );
    }

    final c = state.claim!;
    final currency = NumberFormat.currency(
        locale: 'en_LK', symbol: 'LKR ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Claim #${c.claimId.length >= 8 ? c.claimId.substring(0, 8).toUpperCase() : c.claimId.toUpperCase()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () =>
                ref.read(claimDetailProvider(claimId).notifier).fetchClaim(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status Card ──────────────────────────────────────────────
            _InfoCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CLAIM STATUS',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.status.displayLabel.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryLight),
                      ),
                      if (c.createdAtUtc != null)
                        Text(
                          'Filed: ${_formatDate(c.createdAtUtc)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                  StatusBadge(
                      label: c.status.displayLabel,
                      style: _badgeStyleFor(c.status)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Booking Reference ────────────────────────────────────────
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('BOOKING REFERENCE'),
                  const SizedBox(height: 6),
                  Text(
                    c.bookingId,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Damage Description ───────────────────────────────────────
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('DAMAGE DESCRIPTION'),
                  const SizedBox(height: 8),
                  Text(
                    c.damageDescription,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Evidence Photos ──────────────────────────────────────────
            if (c.evidencePhotos.isNotEmpty) ...[
              _InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('EVIDENCE (${c.evidencePhotos.length})'),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: c.evidencePhotos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          return _EvidenceThumbnail(url: c.evidencePhotos[i]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Financial Breakdown ──────────────────────────────────────
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('FINANCIAL BREAKDOWN'),
                  const SizedBox(height: 12),
                  _FinancialRow(
                    label: 'Proposed Deduction',
                    value: currency.format(c.proposedDeduction),
                    valueColor: AppColors.warning,
                  ),
                  if (c.finalDeduction != null) ...[
                    const Divider(color: AppColors.border, height: 20),
                    _FinancialRow(
                      label: 'Adjudicated Deduction',
                      value: currency.format(c.finalDeduction!),
                      valueColor: AppColors.primaryLight,
                      bold: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Adjudication Notes ───────────────────────────────────────
            if (c.adjudicationNotes != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Color(0xFFD0BCFF), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Adjudication Notes',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD0BCFF),
                              fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.adjudicationNotes!,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          height: 1.4),
                    ),
                    if (c.adjudicatedAtUtc != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Adjudicated: ${_formatDate(c.adjudicatedAtUtc)}',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Payout Result ────────────────────────────────────────────
            if (state.payoutResult != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.success, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Settlement Complete',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                              fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _FinancialRow(
                        label: 'Owner Payout',
                        value: currency
                            .format(state.payoutResult!.ownerPayoutAmount)),
                    _FinancialRow(
                        label: 'Renter Refund',
                        value: currency
                            .format(state.payoutResult!.renterRefundAmount)),
                    const SizedBox(height: 4),
                    Text(
                      'Ref: ${state.payoutResult!.settlementReference}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Actions ──────────────────────────────────────────────────
            if (c.status.canAdjudicate) ...[
              _SectionLabel('ADJUDICATION CONTROLS'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Approve',
                      variant: AppButtonVariant.primary,
                      isLoading: state.isProcessingAction,
                      onPressed: state.isProcessingAction
                          ? null
                          : () => _confirmAdjudicate(
                              context, ref, 'Approve', c.claimId),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      text: 'Reject',
                      variant: AppButtonVariant.destructive,
                      isLoading: state.isProcessingAction,
                      onPressed: state.isProcessingAction
                          ? null
                          : () => _confirmAdjudicate(
                              context, ref, 'Reject', c.claimId),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppButton(
                text: 'Revise Deduction',
                variant: AppButtonVariant.secondary,
                icon: Icons.edit_outlined,
                isLoading: state.isProcessingAction,
                onPressed: state.isProcessingAction
                    ? null
                    : () => _showReviseDialog(context, ref, c.claimId),
              ),
              const SizedBox(height: 16),
            ],

            if (c.status.canPayout) ...[
              AppButton(
                text: 'Disburse Payout & Settle Escrow',
                variant: AppButtonVariant.secondary,
                icon: Icons.payments_outlined,
                isLoading: state.isProcessingAction,
                onPressed: state.isProcessingAction
                    ? null
                    : () => _confirmPayout(context, ref),
              ),
              const SizedBox(height: 16),
            ],

            if (c.status.isTerminal)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c.status == ClaimStatus.settled
                      ? 'This claim has been fully settled.'
                      : 'This claim has been rejected. No payout will be made.',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAdjudicate(
    BuildContext context,
    WidgetRef ref,
    String decision,
    String claimId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('$decision Claim?'),
        content: Text(
          'Are you sure you want to $decision this damage claim? '
          'This action cannot be undone.',
          style:
              const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: decision == 'Approve'
                  ? AppColors.success
                  : AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(decision,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(claimDetailProvider(claimId).notifier).adjudicate(
          decision: decision,
          adjudicatorId: 'system',
        );
  }

  Future<void> _showReviseDialog(
      BuildContext context, WidgetRef ref, String claimId) async {
    final ctrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Revise Deduction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Revised Deduction (LKR)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Revise',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final amount = double.tryParse(ctrl.text.trim());
    if (amount == null || amount < 0) return;
    await ref.read(claimDetailProvider(claimId).notifier).adjudicate(
          decision: 'Revise',
          adjudicatorId: 'system',
          revisedDeduction: amount,
          notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
        );
  }

  Future<void> _confirmPayout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirm Payout'),
        content: const Text(
          'This will disburse the settlement payments to the owner and refund '
          'the remaining deposit to the renter. This action cannot be reversed.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Payout',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(claimDetailProvider(claimId).notifier).processPayout();
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _formatDate(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  try {
    final dt = DateTime.parse(raw).toLocal();
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  } catch (_) {
    return raw;
  }
}

BadgeStyle _badgeStyleFor(ClaimStatus status) {
  switch (status) {
    case ClaimStatus.settled:
      return BadgeStyle.success;
    case ClaimStatus.approved:
    case ClaimStatus.revised:
      return BadgeStyle.info;
    case ClaimStatus.underAIEvaluation:
      return BadgeStyle.purple;
    case ClaimStatus.filed:
    case ClaimStatus.pendingStaffApproval:
      return BadgeStyle.warning;
    case ClaimStatus.rejected:
      return BadgeStyle.error;
    default:
      return BadgeStyle.info;
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: AppColors.textMuted),
    );
  }
}

class _FinancialRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  const _FinancialRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.w600,
                fontSize: 14)),
      ],
    );
  }
}

class _EvidenceThumbnail extends StatelessWidget {
  final String url;
  const _EvidenceThumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullImage(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: url.startsWith('http')
            ? Image.network(
                url,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : (url.isNotEmpty)
                ? Image.file(
                    File(url),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.surfaceLight,
      child: const Icon(Icons.image_outlined,
          color: AppColors.textMuted, size: 28),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    if (url.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: url.startsWith('http')
              ? Image.network(url, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white54))
              : Image.file(File(url), fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white54)),
        ),
      ),
    );
  }
}
