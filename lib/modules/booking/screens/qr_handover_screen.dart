import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../models/handover_token_model.dart';
import '../services/booking_service.dart';

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

  @override
  void initState() {
    super.initState();
    _generateToken();
  }

  Future<void> _generateToken() async {
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate single-use handover token.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Event Type Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Pickup Verification'),
                    selected: _eventType == 'Pickup',
                    onSelected: (val) {
                      if (val) {
                        setState(() => _eventType = 'Pickup');
                        _generateToken();
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Return Verification'),
                    selected: _eventType == 'Return',
                    onSelected: (val) {
                      if (val) {
                        setState(() => _eventType = 'Return');
                        _generateToken();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const LoadingIndicator(message: 'Generating encrypted handover token...')
              else if (_error != null)
                ErrorView(message: _error!, onRetry: _generateToken)
              else if (_tokenModel != null) ...[
                // QR Container Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _tokenModel!.qrPayload,
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
                const SizedBox(height: 24),

                Text(
                  '${_eventType.toUpperCase()} TOKEN CODE',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    _tokenModel!.token,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryLight,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Have the counter-party scan this QR code with their RentaTool app to cryptographically confirm the equipment handover.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),

                AppButton(
                  text: 'Refresh Token',
                  variant: AppButtonVariant.outline,
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
