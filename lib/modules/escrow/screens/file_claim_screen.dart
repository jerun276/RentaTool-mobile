import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../identity/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/escrow_provider.dart';
import '../services/escrow_service.dart';

class FileClaimScreen extends ConsumerStatefulWidget {
  final String? bookingId;

  const FileClaimScreen({super.key, this.bookingId});

  @override
  ConsumerState<FileClaimScreen> createState() => _FileClaimScreenState();
}

class _FileClaimScreenState extends ConsumerState<FileClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookingIdController = TextEditingController();
  final _userIdController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      _bookingIdController.text = widget.bookingId!;
    }
    final user = ref.read(authProvider).user;
    if (user != null) {
      _userIdController.text = user.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(escrowProvider.notifier).fetchClaims();
    });
  }

  @override
  void dispose() {
    _bookingIdController.dispose();
    _userIdController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(escrowServiceProvider);
      List<String> evidencePhotos = [];
      if (_selectedImage != null) {
        final uploadedUrl = await ref.read(cloudinaryServiceProvider).uploadImage(
          _selectedImage!.path,
          folder: 'rentatool/claims',
        );
        evidencePhotos = [uploadedUrl];
      }

      await service.fileClaim(
        bookingId: _bookingIdController.text.trim(),
        filedByUserId: _userIdController.text.trim(),
        damageDescription: _descController.text.trim(),
        evidencePhotos: evidencePhotos,
      );

      ref.read(escrowProvider.notifier).fetchClaims();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Damage dispute filed. AI evaluator initiated.'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to file damage claim. Check booking details.';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data['error'] != null) {
            errorMessage = data['error'].toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(errorMessage),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;

    final claims = ref.watch(escrowProvider).claims;
    final bookingIdText = _bookingIdController.text.trim();
    final existingClaim = bookingIdText.isNotEmpty
        ? claims.where((c) => c.bookingId.toLowerCase() == bookingIdText.toLowerCase()).firstOrNull
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Damage Dispute'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (existingClaim != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.error, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'A damage claim has already been filed for this booking (Status: ${existingClaim.status}). Duplicate claims cannot be generated.',
                          style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gavel_outlined, color: Color(0xFFFFB95F), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Claims are assessed against pre-rental inspection baseline images to differentiate normal 60-day wear from operator misuse.',
                        style: TextStyle(fontSize: 12, color: textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              AppTextField(
                controller: _bookingIdController,
                label: 'Rental Booking ID',
                hintText: 'Select or provide booking ID',
                readOnly: true,
                validator: (v) => v == null || v.isEmpty ? 'Booking ID is required' : null,
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _userIdController,
                label: 'Your User ID',
                hintText: 'User ID',
                readOnly: true,
                validator: (v) => v == null || v.isEmpty ? 'User ID is required' : null,
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _descController,
                label: 'Description of Damage & Incident',
                hintText: 'Describe damaged components, broken hydraulics, fractured housing, stripped chuck teeth...',
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? 'Damage details are required' : null,
              ),
              const SizedBox(height: 20),

              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Photo attached: ${_selectedImage!.name}',
                          style: const TextStyle(color: AppColors.success, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _selectedImage = null),
                      ),
                    ],
                  ),
                ),

              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Attach Damage Evidence Photos'),
                onPressed: () async {
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                    });
                  }
                },
              ),
              const SizedBox(height: 28),

              AppButton(
                text: existingClaim != null ? 'Claim Already Filed for Booking' : 'Submit Damage Claim',
                isLoading: _isSubmitting,
                onPressed: existingClaim != null ? null : _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

