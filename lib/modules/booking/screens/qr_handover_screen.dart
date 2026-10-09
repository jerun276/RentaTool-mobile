import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../models/handover_token_model.dart';
import '../services/booking_service.dart';
import '../providers/booking_provider.dart';

class QrHandoverScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const QrHandoverScreen({super.key, required this.bookingId});

  @override
  ConsumerState<QrHandoverScreen> createState() => _QrHandoverScreenState();
}

class _QrHandoverScreenState extends ConsumerState<QrHandoverScreen> {
  HandoverTokenModel? _tokenModel;
  bool _isLoading = true;
  String? _error;
  String _eventType = 'Pickup';
  Timer? _countdownTimer;
  int _secondsRemaining = 900; // 15 minutes default

  @override
  void initState() {
    super.initState();
    final bookings = ref.read(bookingProvider).activeBookings;
    try {
      final booking = bookings.firstWhere((b) => b.id == widget.bookingId);
      if (!booking.pickupVerified) {
        _eventType = 'Pickup';
      } else if (!booking.returnVerified) {
        _eventType = 'Return';
      }
    } catch (_) {}
    _generateToken();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_tokenModel == null) return;

      final rem = _tokenModel!.remainingSeconds;
      if (mounted) {
        setState(() {
          _secondsRemaining = rem;
        });
      }

      if (rem <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> _generateToken() async {
    _countdownTimer?.cancel();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(bookingServiceProvider);
      final token = await service.generateHandoverToken(
        bookingId: widget.bookingId,
        eventType: _eventType,
      );
      setState(() {
        _tokenModel = token;
        _secondsRemaining = token.remainingSeconds;
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_tokenModel == null) return;
    Clipboard.setData(ClipboardData(text: _tokenModel!.token));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Row(
          children: [
            const Icon(Icons.check, color: AppColors.primaryLight, size: 18),
            const SizedBox(width: 8),
            Text('Token code copied: ${_tokenModel!.token}'),
          ],
        ),
      ),
    );
  }

  String get _formattedTime {
    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _secondsRemaining <= 0;
    final bookings = ref.watch(bookingProvider).activeBookings;
    bool showPickup = true;
    bool showReturn = true;
    
    try {
      final booking = bookings.firstWhere((b) => b.id == widget.bookingId);
      showPickup = booking.canGeneratePickupToken;
      showReturn = booking.canGenerateReturnToken;
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Handover QR Verification'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Event Type Selector Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.border),
                ),
                child: Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (showPickup)
                      ChoiceChip(
                        label: const Text('Pickup Verification'),
                        selected: _eventType == 'Pickup',
                        onSelected: (val) {
                          if (val && _eventType != 'Pickup') {
                            setState(() => _eventType = 'Pickup');
                            _generateToken();
                          }
                        },
                      ),
                    if (showReturn)
                      ChoiceChip(
                        label: const Text('Return Verification'),
                        selected: _eventType == 'Return',
                        onSelected: (val) {
                          if (val && _eventType != 'Return') {
                            setState(() => _eventType = 'Return');
                            _generateToken();
                          }
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Loading State
              if (_isLoading)
                const LoadingIndicator(message: 'Generating cryptographically hashed handover token...')
              // 3. Error View
              else if (_error != null)
                ErrorView(message: _error!, onRetry: _generateToken)
              // 4. Token & QR Card
              else if (_tokenModel != null) ...[
                // Expiration Countdown Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isExpired ? AppColors.error.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isExpired ? AppColors.error : AppColors.primaryLight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                        size: 16,
                        color: isExpired ? AppColors.error : AppColors.primaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isExpired ? 'TOKEN EXPIRED' : 'EXPIRES IN: $_formattedTime',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isExpired ? AppColors.error : AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // QR Code Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.grey.shade300 : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: (isExpired ? Colors.grey : AppColors.primary).withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Opacity(
                    opacity: isExpired ? 0.35 : 1.0,
                    child: QrImageView(
                      data: jsonEncode({
                        'bookingId': widget.bookingId.isNotEmpty ? widget.bookingId : _tokenModel!.bookingId,
                        'token': _tokenModel!.token,
                        'eventType': _eventType,
                      }),
                      version: QrVersions.auto,
                      size: 220.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0F131C),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0F131C),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Token Hex Representation with Copy Action
                Text(
                  '${_eventType.toUpperCase()} CRYPTOGRAPHIC TOKEN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _copyToClipboard,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _tokenModel!.token,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.copy, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Instructions Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    isExpired
                        ? 'This single-use token has expired. Please regenerate a new token for handover verification.'
                        : 'Have the counterparty scan this QR code with their RentaTool app. The transaction will be cryptographically logged with GPS verification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isExpired ? AppColors.error : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Regenerate / Refresh Button
                AppButton(
                  text: isExpired ? 'Generate New Token' : 'Refresh Token',
                  variant: isExpired ? AppButtonVariant.primary : AppButtonVariant.outline,
                  icon: Icons.refresh,
                  onPressed: _generateToken,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
