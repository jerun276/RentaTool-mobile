import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../services/identity_service.dart';

class KycSubmissionScreen extends ConsumerStatefulWidget {
  const KycSubmissionScreen({super.key});

  @override
  ConsumerState<KycSubmissionScreen> createState() => _KycSubmissionScreenState();
}

class _KycSubmissionScreenState extends ConsumerState<KycSubmissionScreen> {
  final _number = TextEditingController();
  final _picker = ImagePicker();
  File? _front;
  File? _back;
  String _documentType = 'NIC';
  bool _submitting = false;
  String? _message;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isFront, ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image != null && mounted) {
      setState(() {
        if (isFront) {
          _front = File(image.path);
        } else {
          _back = File(image.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    final number = _number.text.trim().toUpperCase();
    final isValidNIC = RegExp(r'^([0-9]{9}[VvXx]|[0-9]{12})$').hasMatch(number);
    final isValidDL = RegExp(r'^[A-Z0-9]{6,15}$').hasMatch(number);

    if (_documentType == 'NIC' && !isValidNIC) {
      setState(() => _message = 'Please enter a valid Sri Lankan NIC number (e.g. 884210992V or 198842109923).');
      return;
    }
    if (_documentType == 'DrivingLicense' && !isValidDL) {
      setState(() => _message = 'Please enter a valid Driving Licence number.');
      return;
    }
    if (_front == null) {
      setState(() => _message = 'Front image of the document is required.');
      return;
    }
    if (_documentType == 'NIC' && _back == null) {
      setState(() => _message = 'Back image of the NIC is required.');
      return;
    }
    setState(() {
      _submitting = true;
      _message = null;
    });

    try {
      await ref.read(identityServiceProvider).submitKyc(
        documentNumber: number,
        documentType: _documentType,
        frontImagePath: _front!.path,
        backImagePath: _back?.path,
      );

      if (mounted) {
        setState(() => _message = 'Document submitted successfully! Awaiting administrator verification.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('NIC submitted! Administrator will review your document.'),
          ),
        );
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Failed to submit document: ${e.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Submission failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _imageCard({
    required String label,
    required bool isFront,
    required File? image,
    required bool requiredImage,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label${requiredImage ? ' *' : ' (optional)'}',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: image == null
                ? Center(
                    child: Icon(Icons.badge_outlined, size: 42, color: AppColors.textMuted),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(image, width: double.infinity, fit: BoxFit.cover),
                  ),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _pick(isFront, ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Camera'),
              ),
              TextButton.icon(
                onPressed: () => _pick(isFront, ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ],
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAlreadyVerified = user?.isVerified ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification (NIC)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: AppColors.primaryLight),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Verified users enjoy zero pre-auth deposit hold restrictions and priority booking approvals.',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isAlreadyVerified) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your document is verified. You are authorized to rent and receive machinery.',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security_outlined, color: AppColors.primaryLight, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Renter Verification Rule: You must submit and validate a valid Sri Lankan NIC or Driving Licence before you can rent and receive equipment.',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            DropdownButtonFormField<String>(
              value: _documentType,
              decoration: const InputDecoration(labelText: 'Document type'),
              items: const [
                DropdownMenuItem(value: 'NIC', child: Text('National Identity Card (NIC)')),
                DropdownMenuItem(value: 'DrivingLicense', child: Text('Driving Licence')),
              ],
              onChanged: (value) => setState(() => _documentType = value!),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _number,
              label: _documentType == 'NIC' ? 'NIC Number' : 'Driving Licence Number',
              hintText: _documentType == 'NIC' ? '198842109923 or 884210992V' : 'e.g. B1234567',
              prefixIcon: const Icon(Icons.credit_card_outlined, size: 18),
            ),
            const SizedBox(height: 22),
            _imageCard(label: 'Front Image', isFront: true, image: _front, requiredImage: true),
            const SizedBox(height: 12),
            _imageCard(label: 'Back Image', isFront: false, image: _back, requiredImage: _documentType == 'NIC'),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _message!.contains('verified') || _message!.contains('validated')
                        ? AppColors.success
                        : AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            AppButton(
              text: isAlreadyVerified
                  ? 'Identity Verified ✓'
                  : 'Submit & Validate Document',
              isLoading: _submitting,
              icon: isAlreadyVerified ? Icons.check_circle : Icons.verified_outlined,
              onPressed: isAlreadyVerified ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}