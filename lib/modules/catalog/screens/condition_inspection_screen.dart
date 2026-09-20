import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../services/catalog_service.dart';

class ConditionInspectionScreen extends ConsumerStatefulWidget {
  final String equipmentId;

  const ConditionInspectionScreen({super.key, required this.equipmentId});

  @override
  ConsumerState<ConditionInspectionScreen> createState() => _ConditionInspectionScreenState();
}

class _ConditionInspectionScreenState extends ConsumerState<ConditionInspectionScreen> {
  final _notesController = TextEditingController();
  String _inspectionType = 'PreRental';
  bool _passed = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add inspection notes and condition details')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(catalogServiceProvider);
      await service.addInspectionLog(
        equipmentId: widget.equipmentId,
        inspectionType: _inspectionType,
        notes: _notesController.text.trim(),
        passed: _passed,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Condition inspection recorded successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record inspection log')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asset Condition Inspection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Inspection Type',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Pre-Rental'),
                  selected: _inspectionType == 'PreRental',
                  onSelected: (val) {
                    if (val) setState(() => _inspectionType = 'PreRental');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Post-Rental'),
                  selected: _inspectionType == 'PostRental',
                  onSelected: (val) {
                    if (val) setState(() => _inspectionType = 'PostRental');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Maintenance'),
                  selected: _inspectionType == 'Maintenance',
                  onSelected: (val) {
                    if (val) setState(() => _inspectionType = 'Maintenance');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pass / Fail Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Inspection Result',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  _passed ? 'Operational (Certified Safe)' : 'Defective (Requires Repair)',
                  style: TextStyle(
                    fontSize: 12,
                    color: _passed ? AppColors.success : AppColors.error,
                  ),
                ),
                value: _passed,
                activeColor: AppColors.primaryLight,
                onChanged: (val) => setState(() => _passed = val),
              ),
            ),
            const SizedBox(height: 20),

            AppTextField(
              controller: _notesController,
              label: 'Detailed Inspection Notes & Wear Observations',
              hintText: 'Describe physical state, motor sounds, casing scratches, fluid levels...',
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // Camera upload stub
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Capture Multi-Angle Condition Photos'),
              onPressed: () async {
                final picker = ImagePicker();
                await picker.pickImage(source: ImageSource.camera);
              },
            ),
            const SizedBox(height: 28),

            AppButton(
              text: 'Save Inspection Record',
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
