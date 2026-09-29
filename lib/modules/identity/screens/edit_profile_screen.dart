import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/local_profile_photo_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _photoService = LocalProfilePhotoService();
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final saved = await ref.read(authProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );
    if (!mounted) return;

    if (saved) {
      if (_photoPath != null) {
        await ref
            .read(authProvider.notifier)
            .saveLocalProfilePhoto(_photoPath!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
      Navigator.of(context).pop();
      return;
    }

    final message = ref.read(authProvider).errorMessage ??
        'Could not save your profile. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _choosePhoto() async {
    try {
      final path = await _photoService.chooseAndSave();
      if (path != null && mounted) setState(() => _photoPath = path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open your photo gallery.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(children: [
                    Stack(alignment: Alignment.bottomRight, children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.surfaceLight,
                        backgroundImage: (_photoPath ??
                                    widget.user.profilePhotoPath) ==
                                null
                            ? null
                            : FileImage(File(
                                _photoPath ?? widget.user.profilePhotoPath!)),
                        child:
                            (_photoPath ?? widget.user.profilePhotoPath) == null
                                ? Icon(Icons.person_outline,
                                    size: 44, color: AppColors.textSecondary)
                                : null,
                      ),
                      IconButton.filled(
                        tooltip: 'Choose profile photo',
                        onPressed: _choosePhoto,
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      ),
                    ]),
                    TextButton.icon(
                      onPressed: _choosePhoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose photo from gallery'),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                Text(
                  'Update your contact details. Your role and verified email stay unchanged.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _nameController,
                  label: widget.user.role == UserRole.owner
                      ? 'Full name / business name'
                      : 'Full name',
                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return 'Name is required';
                    if (name.length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    if (name.length > 120) {
                      return 'Name must be 120 characters or fewer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phoneController,
                  label: 'Sri Lankan mobile number',
                  hintText: '0771234567 or +94771234567',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Mobile number is required';
                    }
                    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
                    if (!RegExp(r'^(?:\+94|0)7[0-9]{8}$').hasMatch(cleaned)) {
                      return 'Enter a valid Sri Lankan mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(widget.user.email),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Account type'),
                  subtitle: Text(widget.user.role.displayName),
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Save changes',
                  icon: Icons.check,
                  isLoading: auth.isLoading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
