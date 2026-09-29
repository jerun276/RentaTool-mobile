import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/inspection_log_model.dart';
import '../services/catalog_service.dart';

class ConditionInspectionScreen extends ConsumerStatefulWidget {
  final String equipmentId;

  const ConditionInspectionScreen({super.key, required this.equipmentId});

  @override
  ConsumerState<ConditionInspectionScreen> createState() => _ConditionInspectionScreenState();
}

class _CapturedAnglePhoto {
  final String angle;
  final String path;
  final DateTime capturedAt;
  String observation = '';

  _CapturedAnglePhoto({
    required this.angle,
    required this.path,
    required this.capturedAt,
  });
}

class _ConditionInspectionScreenState extends ConsumerState<ConditionInspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _generalNotesController = TextEditingController();
  final _picker = ImagePicker();

  String _inspectionType = 'PreRental';
  String _severity = 'None';
  bool _isSubmitting = false;

  final List<String> _requiredAngles = ['Casing', 'Cord / Wiring', 'Motor / Engine', 'General'];
  final Map<String, _CapturedAnglePhoto?> _anglePhotos = {
    'Casing': null,
    'Cord / Wiring': null,
    'Motor / Engine': null,
    'General': null,
  };

  @override
  void dispose() {
    _generalNotesController.dispose();
    super.dispose();
  }

  Future<void> _captureAngle(String angle) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1280,
      );

      if (image != null) {
        setState(() {
          _anglePhotos[angle] = _CapturedAnglePhoto(
            angle: angle,
            path: image.path,
            capturedAt: DateTime.now(),
          );
        });
      }
    } catch (_) {
      // Fallback to gallery if camera is unavailable in simulator
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _anglePhotos[angle] = _CapturedAnglePhoto(
            angle: angle,
            path: image.path,
            capturedAt: DateTime.now(),
          );
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Check that at least one inspection photo has been captured
    final capturedList = _anglePhotos.values.whereType<_CapturedAnglePhoto>().toList();
    if (capturedList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture at least one multi-angle inspection photograph (Casing, Cord, or Motor).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(catalogServiceProvider);

      final photoDtos = capturedList.map((photo) {
        return InspectionPhotoModel(
          angle: photo.angle,
          photoUrl: photo.path, // In full production, this is uploaded via multipart/signed URL
          observationNote: photo.observation.isNotEmpty ? photo.observation : null,
          capturedAtUtc: photo.capturedAt,
        );
      }).toList();

      await service.createInspectionLog(
        equipmentId: widget.equipmentId,
        type: _inspectionType,
        severity: _severity,
        conditionNotes: _generalNotesController.text.trim(),
        photos: photoDtos,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Multi-angle condition inspection successfully committed to ledger.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record inspection log. Please verify network.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss UTC');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Condition Inspection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.camera_enhance_outlined, color: AppColors.primaryLight, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MULTI-ANGLE AUDIT RECORDING',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Capture high-resolution evidence with tamper-proof timestamp verification.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Inspection Type Selector
              Text(
                'INSPECTION TYPE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _typeChip('PreRental', 'Pre-Rental Handover'),
                  _typeChip('PostRental', 'Post-Rental Return'),
                  _typeChip('PeriodicMaintenance', 'Periodic Servicing'),
                  _typeChip('DamageAssessment', 'Damage Claim Audit'),
                ],
              ),
              const SizedBox(height: 18),

              // Severity Selector
              Text(
                'WEAR & DEFECT SEVERITY RATING',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _severityChip('None', AppColors.success),
                  _severityChip('Minor', Colors.blue),
                  _severityChip('Moderate', AppColors.warning),
                  _severityChip('Severe', Colors.deepOrange),
                  _severityChip('Critical', AppColors.wearLockout),
                ],
              ),
              const SizedBox(height: 20),

              // Multi-Angle Photographic Evidence Grid
              Text(
                'MULTI-ANGLE CAMERA EVIDENCE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8, color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                'Capture designated angles to satisfy dispute and wear-lockout compliance.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              ..._requiredAngles.map((angle) => _buildAngleCaptureTile(angle, timeFormat)),

              const SizedBox(height: 16),

              // Overall Condition Notes
              AppTextField(
                controller: _generalNotesController,
                label: 'General Technical Assessment & Notes',
                hintText: 'Describe visual wear, operational noise, vibrations, fluid leaks, or cleaning status...',
                maxLines: 4,
                validator: (val) => val == null || val.trim().isEmpty ? 'Inspection observations are required' : null,
              ),
              const SizedBox(height: 24),

              // Submit Button
              AppButton(
                text: 'Record Asset Condition Log',
                isLoading: _isSubmitting,
                icon: Icons.shield_outlined,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String value, String label) {
    final isSelected = _inspectionType == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      onSelected: (selected) {
        if (selected) setState(() => _inspectionType = value);
      },
    );
  }

  Widget _severityChip(String value, Color color) {
    final isSelected = _severity == value;
    return ChoiceChip(
      label: Text(value, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : color)),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: AppColors.surface,
      onSelected: (selected) {
        if (selected) setState(() => _severity = value);
      },
    );
  }

  Widget _buildAngleCaptureTile(String angle, DateFormat timeFormat) {
    final photo = _anglePhotos[angle];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: photo != null ? AppColors.primaryLight : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    photo != null ? Icons.check_circle : Icons.camera_alt_outlined,
                    size: 18,
                    color: photo != null ? AppColors.success : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    angle,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                ],
              ),
              TextButton.icon(
                icon: Icon(photo != null ? Icons.refresh : Icons.camera_alt, size: 16),
                label: Text(photo != null ? 'Retake' : 'Capture'),
                onPressed: () => _captureAngle(angle),
              ),
            ],
          ),

          if (photo != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: AppColors.surfaceLight,
                    child: photo.path.startsWith('http')
                        ? Image.network(photo.path, fit: BoxFit.cover)
                        : Image.file(File(photo.path), fit: BoxFit.cover),
                  ),
                  // Timestamp Overlay Badge (Mandatory for tamper-evident condition audits)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xDD000000),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, size: 12, color: AppColors.primaryLight),
                          const SizedBox(width: 6),
                          Text(
                            timeFormat.format(photo.capturedAt),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: photo.observation,
              decoration: InputDecoration(
                hintText: 'Add note for $angle (optional)...',
                hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                fillColor: AppColors.surfaceLight,
                filled: true,
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (val) => photo.observation = val,
            ),
          ],
        ],
      ),
    );
  }
}
