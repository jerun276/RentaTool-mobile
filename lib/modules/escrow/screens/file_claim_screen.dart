import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
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
      await service.fileClaim(
        bookingId: _bookingIdController.text.trim(),
        filedByUserId: _userIdController.text.trim(),
        damageDescription: _descController.text.trim(),
        evidencePhotos: _selectedImage != null ? [_selectedImage!.path] : [],
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to file damage claim. Check booking details.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.gavel_outlined, color: Color(0xFFFFB95F), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Claims are assessed against pre-rental inspection baseline images to differentiate normal 60-day wear from operator misuse.',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              AppTextField(
                controller: _bookingIdController,
                label: 'Rental Booking ID',
                hintText: 'e.g. 33333333-3333-3333-3333-333333333301',
                validator: (v) => v == null || v.isEmpty ? 'Booking ID is required' : null,
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _userIdController,
                label: 'Your User ID',
                hintText: 'e.g. 11111111-1111-1111-1111-111111111101',
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
                text: 'Submit Damage Claim',
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

