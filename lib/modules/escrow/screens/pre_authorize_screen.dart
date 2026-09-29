import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/escrow_provider.dart';
import '../models/escrow_hold_model.dart';

class PreAuthorizeScreen extends ConsumerStatefulWidget {
  /// Optional pre-filled values from booking context via route parameters.
  final String? bookingId;
  final String? renterId;
  final String? ownerId;
  final double? depositAmount;

  const PreAuthorizeScreen({
    super.key,
    this.bookingId,
    this.renterId,
    this.ownerId,
    this.depositAmount,
  });

  @override
  ConsumerState<PreAuthorizeScreen> createState() =>
      _PreAuthorizeScreenState();
}

class _PreAuthorizeScreenState extends ConsumerState<PreAuthorizeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bookingIdCtrl;
  late final TextEditingController _renterIdCtrl;
  late final TextEditingController _ownerIdCtrl;
  late final TextEditingController _depositAmountCtrl;
  final _paymentTokenCtrl = TextEditingController();

  final _formatter = NumberFormat.currency(
      locale: 'en_LK', symbol: 'LKR ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _bookingIdCtrl =
        TextEditingController(text: widget.bookingId ?? '');
    _renterIdCtrl =
        TextEditingController(text: widget.renterId ?? '');
    _ownerIdCtrl =
        TextEditingController(text: widget.ownerId ?? '');
    _depositAmountCtrl = TextEditingController(
        text: widget.depositAmount != null
            ? widget.depositAmount!.toStringAsFixed(2)
            : '');
  }

  @override
  void dispose() {
    _bookingIdCtrl.dispose();
    _renterIdCtrl.dispose();
    _ownerIdCtrl.dispose();
    _depositAmountCtrl.dispose();
    _paymentTokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_depositAmountCtrl.text.trim()) ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirm Deposit Hold'),
        content: Text(
          'A security deposit of ${_formatter.format(amount)} will be pre-authorised '
          'and held against your payment method. No funds will be permanently '
          'charged until the rental is settled.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Authorise',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await ref.read(preAuthorizeProvider.notifier).preAuthorize(
          bookingId: _bookingIdCtrl.text.trim(),
          renterId: _renterIdCtrl.text.trim(),
          ownerId: _ownerIdCtrl.text.trim(),
          depositAmount: amount,
          paymentMethodToken: _paymentTokenCtrl.text.trim().isNotEmpty
              ? _paymentTokenCtrl.text.trim()
              : null,
        );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content:
              Text('Security deposit pre-authorised and held successfully.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(preAuthorizeProvider);

    // Show success state
    if (state.success && state.result != null) {
      return _SuccessView(
        escrow: state.result!,
        formatter: _formatter,
        onDone: () {
          ref.read(preAuthorizeProvider.notifier).reset();
          Navigator.of(context).pop();
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Authorise Security Deposit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Info Banner ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.escrowHeld.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.escrowHeld.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline,
                        color: AppColors.escrowHeld, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Escrow Pre-Authorization',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.escrowHeld,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A temporary hold will be placed on your payment method '
                            'for the security deposit amount. No funds are permanently '
                            'deducted until the rental is completed and reviewed.',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Booking Details ──────────────────────────────────────
              const _SectionHeader(label: 'Rental Details'),
              const SizedBox(height: 12),
              AppTextField(
                controller: _bookingIdCtrl,
                label: 'Booking ID',
                hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Booking ID is required'
                        : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _renterIdCtrl,
                label: 'Renter User ID',
                hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Renter ID is required'
                        : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _ownerIdCtrl,
                label: 'Owner User ID',
                hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Owner ID is required'
                        : null,
              ),
              const SizedBox(height: 24),

              // ── Deposit Amount ───────────────────────────────────────
              const _SectionHeader(label: 'Security Deposit'),
              const SizedBox(height: 12),
              AppTextField(
                controller: _depositAmountCtrl,
                label: 'Deposit Amount (LKR)',
                hintText: 'e.g. 15000.00',
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                prefixIcon: Icon(Icons.payments_outlined,
                    color: AppColors.textMuted, size: 18),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Deposit amount is required';
                  }
                  final d = double.tryParse(v.trim());
                  if (d == null || d <= 0) {
                    return 'Enter a valid positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _paymentTokenCtrl,
                label: 'Payment Method Token (optional)',
                hintText: 'Simulator token or leave blank',
              ),

              // ── Error ────────────────────────────────────────────────
              if (state.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),

              AppButton(
                text: 'Authorise Security Deposit',
                icon: Icons.lock_outlined,
                isLoading: state.isLoading,
                onPressed: state.isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final EscrowHoldModel escrow;
  final NumberFormat formatter;
  final VoidCallback onDone;

  const _SuccessView({
    required this.escrow,
    required this.formatter,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deposit Authorised')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 64),
            const SizedBox(height: 20),
            Text(
              'Security Deposit Held',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Your deposit of ${formatter.format(escrow.depositAmount)} has been '
              'pre-authorised and placed in escrow.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 28),
            _InfoRow(
                label: 'Escrow ID',
                value: escrow.id.length >= 8
                    ? escrow.id.substring(0, 8).toUpperCase()
                    : escrow.id.toUpperCase()),
            _InfoRow(label: 'Status', value: escrow.status.displayLabel),
            _InfoRow(
                label: 'Transaction Ref',
                value: escrow.preAuthTransactionId),
            const SizedBox(height: 32),
            AppButton(text: 'Done', onPressed: onDone),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: AppColors.textMuted,
      ),
    );
  }
}
