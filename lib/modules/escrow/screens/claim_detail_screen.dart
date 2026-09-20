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
import '../services/escrow_service.dart';

class ClaimDetailScreen extends ConsumerStatefulWidget {
  final String claimId;

  const ClaimDetailScreen({super.key, required this.claimId});

  @override
  ConsumerState<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends ConsumerState<ClaimDetailScreen> {
  DamageClaimModel? _claim;
  bool _isLoading = true;
  String? _error;
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _fetchClaim();
  }

  Future<void> _fetchClaim() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(escrowServiceProvider);
      final item = await service.getClaimById(widget.claimId);
      setState(() {
        _claim = item;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load damage dispute dossier.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAdjudicate(String decision) async {
    if (_claim == null) return;
    setState(() => _isProcessingAction = true);
    try {
      final service = ref.read(escrowServiceProvider);
      final updated = await service.adjudicateClaim(
        claimId: _claim!.claimId,
        decision: decision,
        adjudicationNotes: 'Adjudicated as $decision via Mobile Arbitration Desk',
      );
      setState(() {
        _claim = updated;
        _isProcessingAction = false;
      });
      ref.read(escrowProvider.notifier).fetchClaims();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Claim successfully $decision')),
        );
      }
    } catch (e) {
      setState(() => _isProcessingAction = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action could not be completed')),
        );
      }
    }
  }

  Future<void> _handlePayout() async {
    if (_claim == null) return;
    setState(() => _isProcessingAction = true);
    try {
      final service = ref.read(escrowServiceProvider);
      await service.processPayout(_claim!.claimId);
      _fetchClaim();
      ref.read(escrowProvider.notifier).fetchClaims();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Escrow payout settled. Funds disbursed.'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessingAction = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payout settlement failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dispute Dossier')),
        body: const LoadingIndicator(message: 'Loading arbitration telemetry...'),
      );
    }

    if (_error != null || _claim == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dispute Dossier')),
        body: ErrorView(message: _error ?? 'Claim not found', onRetry: _fetchClaim),
      );
    }

    final c = _claim!;
    final currencyFormatter = NumberFormat.currency(locale: 'en_LK', symbol: 'LKR ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Claim #${c.claimId.substring(0, c.claimId.length >= 6 ? 6 : c.claimId.length).toUpperCase()}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
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
                        'DISPUTE STATUS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.status.toUpperCase(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryLight),
                      ),
                    ],
                  ),
                  StatusBadge(label: c.status, style: BadgeStyle.warning),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Damage Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REPORTED DAMAGE OBSERVATIONS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.damageDescription,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Financial Deductions Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FINANCIAL DEDUCTION ASSESSMENT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Owner Proposed Deduction:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text(
                        currencyFormatter.format(c.proposedDeduction),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.warning),
                      ),
                    ],
                  ),
                  if (c.finalDeduction != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Adjudicated Final Deduction:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text(
                          currencyFormatter.format(c.finalDeduction!),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // AI Arbitration Notes
            if (c.adjudicationNotes != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.purple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFFD0BCFF), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'AI Arbiter & Telemetry Findings',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD0BCFF), fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.adjudicationNotes!,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Adjudication Controls (Component 4 requirement)
            const Text(
              'Administrative Adjudication Controls',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Approve Claim',
                    variant: AppButtonVariant.primary,
                    isLoading: _isProcessingAction,
                    onPressed: () => _handleAdjudicate('Approved'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Reject Claim',
                    variant: AppButtonVariant.destructive,
                    isLoading: _isProcessingAction,
                    onPressed: () => _handleAdjudicate('Rejected'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            AppButton(
              text: 'Disburse Payout & Settle Escrow',
              variant: AppButtonVariant.secondary,
              icon: Icons.payments_outlined,
              isLoading: _isProcessingAction,
              onPressed: _handlePayout,
            ),
          ],
        ),
      ),
    );
  }
}
