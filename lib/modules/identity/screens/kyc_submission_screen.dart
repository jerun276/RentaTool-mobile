import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/token_storage_service.dart';
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
  String _kycStatus = 'none'; // 'none', 'Pending', 'Approved', 'Rejected'
  String? _rejectionReason;
  bool _loadingStatus = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentKycStatus();
    });
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentKycStatus() async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      if (mounted) setState(() => _loadingStatus = false);
      return;
    }

    if (user.isVerified) {
      if (mounted) {
        setState(() {
          _kycStatus = 'Approved';
          _loadingStatus = false;
        });
      }
      return;
    }

    // 1. Try to query backend
    try {
      final sub = await ref.read(identityServiceProvider).getMyKycSubmission(user.id);
      if (sub != null && mounted) {
        setState(() {
          _kycStatus = sub.status;
          _rejectionReason = sub.rejectionReason;
          if (sub.documentNumber.isNotEmpty) {
            _number.text = sub.documentNumber;
          }
          if (sub.documentType.isNotEmpty) {
            _documentType = sub.documentType;
          }
          _loadingStatus = false;
        });
        await ref.read(tokenStorageServiceProvider).saveKycStatus(
          user.id,
          sub.status,
          rejectionReason: sub.rejectionReason,
          documentNumber: sub.documentNumber,
        );
        return;
      }
    } catch (_) {}

    // 2. Fallback to local storage
    final localStatus = await ref.read(tokenStorageServiceProvider).getKycStatus(user.id);
    final localReason = await ref.read(tokenStorageServiceProvider).getKycRejectionReason(user.id);
    final localDocNum = await ref.read(tokenStorageServiceProvider).getKycDocumentNumber(user.id);

    if (mounted) {
      setState(() {
        _kycStatus = localStatus ?? 'none';
        _rejectionReason = localReason;
        if (localDocNum != null && localDocNum.isNotEmpty) {
          _number.text = localDocNum;
        }
        _loadingStatus = false;
      });
    }
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

      final user = ref.read(authProvider).user;
      if (user != null) {
        await ref.read(tokenStorageServiceProvider).saveKycStatus(
          user.id,
          'Pending',
          documentNumber: number,
        );
      }

      if (mounted) {
        setState(() {
          _kycStatus = 'Pending';
          _rejectionReason = null;
        });

        // Show prominent modal popup
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Document Submitted!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your NIC document has been uploaded for administrative verification.',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Status: Pending Admin Review',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Our compliance officers will review your submission. You will receive unrestricted rental access once approved.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (mounted) Navigator.of(context).pop(true);
                  },
                  child: const Text('Back to Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
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
    final isAlreadyVerified = user?.isVerified ?? false || _kycStatus == 'Approved';
    final isPending = _kycStatus == 'Pending';
    final isRejected = _kycStatus == 'Rejected';

    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification (NIC)')),
      body: _loadingStatus
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  ] else if (isPending) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Document Under Review: Your submission has been received and is currently being inspected by compliance administrators.',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else if (isRejected) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'NIC Re-upload Requested',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _rejectionReason != null && _rejectionReason!.isNotEmpty
                                ? 'Admin note: $_rejectionReason\nPlease upload clear, high-quality replacement photographs below.'
                                : 'Your previous document was declined by compliance. Please review the document requirements and re-upload.',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              height: 1.3,
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

                  // Document Type selector
                  IgnorePointer(
                    ignoring: isPending || isAlreadyVerified,
                    child: Opacity(
                      opacity: (isPending || isAlreadyVerified) ? 0.7 : 1.0,
                      child: DropdownButtonFormField<String>(
                        value: _documentType,
                        decoration: const InputDecoration(labelText: 'Document type'),
                        items: const [
                          DropdownMenuItem(value: 'NIC', child: Text('National Identity Card (NIC)')),
                          DropdownMenuItem(value: 'DrivingLicense', child: Text('Driving Licence')),
                        ],
                        onChanged: (value) => setState(() => _documentType = value!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Document Number
                  IgnorePointer(
                    ignoring: isPending || isAlreadyVerified,
                    child: Opacity(
                      opacity: (isPending || isAlreadyVerified) ? 0.7 : 1.0,
                      child: AppTextField(
                        controller: _number,
                        label: _documentType == 'NIC' ? 'NIC Number' : 'Driving Licence Number',
                        hintText: _documentType == 'NIC' ? '198842109923 or 884210992V' : 'e.g. B1234567',
                        prefixIcon: const Icon(Icons.credit_card_outlined, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Image Cards
                  if (!isPending && !isAlreadyVerified) ...[
                    _imageCard(label: 'Front Image', isFront: true, image: _front, requiredImage: true),
                    const SizedBox(height: 12),
                    _imageCard(label: 'Back Image', isFront: false, image: _back, requiredImage: _documentType == 'NIC'),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.photo_library_outlined, color: AppColors.textMuted, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isAlreadyVerified
                                  ? 'Front & Back photographs verified and archived in compliance vault.'
                                  : 'Photographs uploaded and queued for administrative inspection.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
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
                  const SizedBox(height: 20),

                  AppButton(
                    text: isAlreadyVerified
                        ? 'Identity Verified ✓'
                        : (isPending
                            ? 'Under Administrative Review ⏳'
                            : (isRejected ? 'Re-submit NIC Document' : 'Submit & Validate Document')),
                    isLoading: _submitting,
                    icon: isAlreadyVerified
                        ? Icons.check_circle
                        : (isPending
                            ? Icons.hourglass_top_rounded
                            : (isRejected ? Icons.replay_outlined : Icons.verified_outlined)),
                    onPressed: (isAlreadyVerified || isPending) ? null : _submit,
                  ),
                ],
              ),
            ),
    );
  }
}