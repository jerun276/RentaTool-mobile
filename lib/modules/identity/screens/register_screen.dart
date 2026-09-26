import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

/// Two-step account creation: role first, then personal and login details.
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
  int _step = 0;
  String _role = 'Renter';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).register(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      phoneNumber: _phone.text.trim(),
      role: _role,
    );
    if (success && mounted) context.go('/catalog');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Stepper(
          currentStep: _step,
          onStepCancel: _step == 0 ? () => context.pop() : () => setState(() => _step--),
          onStepContinue: _step == 0 ? () => setState(() => _step = 1) : _submit,
          controlsBuilder: (context, details) => Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: _step == 0 ? 'Continue' : 'Create account',
                    isLoading: auth.isLoading,
                    onPressed: details.onStepContinue,
                  ),
                ),
                if (_step > 0) ...[const SizedBox(width: 12), TextButton(onPressed: details.onStepCancel, child: const Text('Back'))],
              ],
            ),
          ),
          steps: [
            Step(
              title: const Text('Choose your account type'),
              isActive: _step >= 0,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Choose how you will use RentaTool LK.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ChoiceChip(
                    label: const Text('Machinery renter'),
                    selected: _role == 'Renter',
                    onSelected: (_) => setState(() => _role = 'Renter'),
                  ),
                  const SizedBox(height: 10),
                  ChoiceChip(
                    label: const Text('Equipment owner'),
                    selected: _role == 'Owner',
                    onSelected: (_) => setState(() => _role = 'Owner'),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Your details'),
              isActive: _step >= 1,
              content: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _name,
                      label: _role == 'Owner' ? 'Full name / business name' : 'Full name',
                      hintText: 'e.g. Kasun Kalhara',
                      prefixIcon: const Icon(Icons.person_outline, size: 18),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Full name is required';
                        if (v.trim().length < 3) return 'Name must be at least 3 characters';
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
                        final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                        if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
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
                        if (v == null || v.trim().isEmpty) return 'Mobile number is required';
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
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 8) return 'Password must be at least 8 characters';
                        if (!RegExp(r'[a-zA-Z]').hasMatch(v)) return 'Must include at least one letter';
                        if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must include at least one number';
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
                          _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm your password';
                        if (v != _password.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    if (auth.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(auth.errorMessage!, style: const TextStyle(color: AppColors.error)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
