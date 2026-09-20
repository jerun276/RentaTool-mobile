import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../services/booking_service.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  final String? bookingId;

  const QrScannerScreen({super.key, this.bookingId});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final _manualTokenController = TextEditingController();
  final _bookingIdController = TextEditingController();
  bool _isProcessing = false;
  String _eventType = 'Pickup';

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      _bookingIdController.text = widget.bookingId!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _manualTokenController.dispose();
    _bookingIdController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken(String token) async {
    final bkgId = _bookingIdController.text.trim();
    if (bkgId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select a Booking ID')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final service = ref.read(bookingServiceProvider);
      final success = await service.verifyHandover(
        bookingId: bkgId,
        token: token.trim(),
        eventType: _eventType,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text('$_eventType Handover successfully verified!'),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.error,
              content: Text('Invalid or expired handover token'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Handover verification failed. Check credentials.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Handover QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, size: 20),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.camera_front, size: 20),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Event Type Chip Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Verify Pickup'),
                  selected: _eventType == 'Pickup',
                  onSelected: (val) {
                    if (val) setState(() => _eventType = 'Pickup');
                  },
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Verify Return'),
                  selected: _eventType == 'Return',
                  onSelected: (val) {
                    if (val) setState(() => _eventType = 'Return');
                  },
                ),
              ],
            ),
          ),

          // Camera Viewport
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    if (_isProcessing) return;
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _verifyToken(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
                // Target overlay box
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryLight, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),

          // Manual Code Entry Fallback
          Expanded(
            flex: 2,
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'CANNOT SCAN? ENTER DETAILS MANUALLY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (widget.bookingId == null) ...[
                      AppTextField(
                        controller: _bookingIdController,
                        hintText: 'Booking ID (e.g. 33333333-3333-...)',
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _manualTokenController,
                            hintText: 'Enter 6-char token code',
                          ),
                        ),
                        const SizedBox(width: 12),
                        AppButton(
                          text: 'Verify',
                          isLoading: _isProcessing,
                          onPressed: () => _verifyToken(_manualTokenController.text),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
