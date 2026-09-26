import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/handover_verification_model.dart';
import '../providers/booking_provider.dart';
import '../services/booking_service.dart';
import '../services/location_service.dart';
import '../../identity/providers/auth_provider.dart';
import '../../identity/models/user_model.dart';

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
  Position? _currentGpsPosition;

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      _bookingIdController.text = widget.bookingId!;
    }
    _acquireGpsLocation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _manualTokenController.dispose();
    _bookingIdController.dispose();
    super.dispose();
  }

  Future<void> _acquireGpsLocation() async {
    try {
      final locService = ref.read(locationServiceProvider);
      final pos = await locService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentGpsPosition = pos;
        });
      }
    } catch (_) {}
  }

  Future<void> _verifyToken(String rawToken) async {
    final bkgId = _bookingIdController.text.trim();
    if (bkgId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a Booking ID for verification')),
      );
      return;
    }

    if (rawToken.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or scan a valid handover token')),
      );
      return;
    }

    if (_currentGpsPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('GPS verification required. Please enable location services to verify equipment handover.'),
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user != null && user.role == UserRole.renter && !user.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('NIC verification required before taking possession of equipment.'),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final lat = _currentGpsPosition!.latitude;
      final lng = _currentGpsPosition!.longitude;

      final request = VerifyHandoverRequestModel(
        token: rawToken.trim(),
        eventType: _eventType,
        latitude: lat,
        longitude: lng,
        addressLine: 'GPS Verified Handover Station',
        city: LocationService.defaultCity,
        postalCode: '00100',
      );

      final service = ref.read(bookingServiceProvider);
      final result = await service.verifyHandover(
        bookingId: bkgId,
        request: request,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        // Refresh active bookings state
        ref.read(bookingProvider.notifier).fetchActiveBookings();
        _showVerificationSuccessModal(result, lat, lng);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(result.message.isNotEmpty ? result.message : 'Handover verification failed.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errText = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(errText),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showVerificationSuccessModal(
    HandoverVerificationResponseModel result,
    double lat,
    double lng,
  ) {
    final timeFormatter = DateFormat('yyyy-MM-dd HH:mm:ss UTC');

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Icon(Icons.check_circle, color: AppColors.primaryLight, size: 54),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '${result.eventType.toUpperCase()} VERIFIED',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  result.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 20),

              // Metadata Table Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _metaRow('New Booking Status', result.newBookingStatus, isHighlight: true),
                    const Divider(height: 16),
                    _metaRow('Verified At', timeFormatter.format(result.verifiedAtUtc)),
                    const Divider(height: 16),
                    _metaRow(
                      'GPS Location Tagged',
                      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)} (Colombo)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                text: 'View Booking Details',
                icon: Icons.assignment_outlined,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/bookings/detail/${result.bookingId}');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metaRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.primaryLight : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Handover QR Token'),
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
          // 1. Event Type Chip Bar
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

          // 2. Camera Viewport
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
                      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                        _verifyToken(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
                // Aim overlay frame
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryLight, width: 2.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryLight),
                    ),
                  ),
              ],
            ),
          ),

          // 3. Manual Token Code Entry Fallback
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
                      'OR VERIFY MANUALLY VIA TOKEN CODE',
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
                            hintText: 'e.g. RT-8A9F-2B4C-1D3E',
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
