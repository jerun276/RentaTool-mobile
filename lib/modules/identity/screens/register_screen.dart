import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../services/local_profile_photo_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _photoService = LocalProfilePhotoService();
  String _role = 'Renter';
  String? _photoPath;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authProvider.notifier);
    final success = await notifier.register(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      phoneNumber: _phone.text.trim(),
      role: _role,
    );
    if (success && mounted) {
      if (_photoPath != null) await notifier.saveLocalProfilePhoto(_photoPath!);
      if (mounted) context.go('/catalog');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(children: [
                  Stack(alignment: Alignment.bottomRight, children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.surfaceLight,
                      backgroundImage: _photoPath == null
                          ? null
                          : FileImage(File(_photoPath!)),
                      child: _photoPath == null
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
                    label: Text(_photoPath == null
                        ? 'Add profile photo'
                        : 'Change photo'),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              const Text('Account type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              RadioGroup<String>(
                groupValue: _role,
                onChanged: (value) => setState(() => _role = value!),
                child: const Column(
                  children: [
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Machinery renter'),
                      value: 'Renter',
                    ),
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Equipment owner'),
                      value: 'Owner',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _name,
                label: _role == 'Owner'
                    ? 'Full name / business name'
                    : 'Full name',
                hintText: 'e.g. Kasun Kalhara',
                prefixIcon: const Icon(Icons.person_outline, size: 18),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  if (v.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(v.trim())) {
                    return 'Please enter a valid name (letters only)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _email,
                label: 'Email address',
                hintText: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, size: 18),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                      .hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _phone,
                label: 'Sri Lankan mobile number',
                hintText: '0771234567 or +94771234567',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Mobile number is required';
                  }
                  final cleaned = v.replaceAll(RegExp(r'[\s-]'), '');
                  if (!RegExp(r'^(?:\+94|0)7[0-9]{8}$').hasMatch(cleaned)) {
                    return 'Enter a valid 10-digit Sri Lankan number (e.g. 0771234567)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _password,
                label: 'Password',
                hintText: 'Min 8 chars with letter & number',
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  if (!RegExp(r'[a-zA-Z]').hasMatch(v)) {
                    return 'Must include at least one letter';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(v)) {
                    return 'Must include at least one number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _confirmPassword,
                label: 'Confirm Password',
                hintText: 'Re-enter your password',
                obscureText: _obscureConfirmPassword,
                prefixIcon: const Icon(Icons.lock_reset_outlined, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != _password.text) return 'Passwords do not match';
                  return null;
                },
              ),
              if (auth.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(auth.errorMessage!,
                      style: const TextStyle(color: AppColors.error)),
                ),
              const SizedBox(height: 20),
              AppButton(
                  text: 'Create account',
                  isLoading: auth.isLoading,
                  onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
