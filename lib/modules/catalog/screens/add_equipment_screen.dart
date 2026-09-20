import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/catalog_provider.dart';
import '../services/catalog_service.dart';

class AddEquipmentScreen extends ConsumerStatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  ConsumerState<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends ConsumerState<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _replacementValController = TextEditingController();
  final _locationController = TextEditingController(text: 'Colombo');
  String _categoryId = '352ea07e-bd97-481b-a287-027036658902'; // Heavy Machinery
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dailyRateController.dispose();
    _replacementValController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(catalogServiceProvider);
      await service.createEquipment(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        categoryId: _categoryId,
        dailyRate: double.parse(_dailyRateController.text),
        replacementValue: double.parse(_replacementValController.text),
        location: _locationController.text.trim(),
      );

      ref.read(catalogProvider.notifier).fetchEquipment();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipment listing published successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to publish listing. Please check inputs.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Machinery Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _titleController,
                label: 'Equipment Title & Model',
                hintText: 'e.g. Caterpillar 320D Excavator',
                validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _descController,
                label: 'Specifications & Condition',
                hintText: 'Enter technical specifications, operating hours, etc.',
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _categoryId,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(value: '352ea07e-bd97-481b-a287-027036658902', child: Text('Heavy Machinery')),
                  DropdownMenuItem(value: '6550f572-d602-4ec8-88e5-d3183a807787', child: Text('Power Tools')),
                  DropdownMenuItem(value: '5fcc78e0-06b4-4db7-b6bf-31c3fac5524d', child: Text('Cleaning Equipment')),
                  DropdownMenuItem(value: '62886944-85b4-4d2f-a700-382319ab2ddf', child: Text('Generators & Power')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _categoryId = val);
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _dailyRateController,
                      label: 'Daily Rate (LKR)',
                      hintText: 'e.g. 15000',
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Enter rate' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _replacementValController,
                      label: 'Replacement (LKR)',
                      hintText: 'e.g. 5000000',
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Enter value' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _locationController,
                label: 'Depot / Yard Location',
                hintText: 'e.g. Colombo 05 / Gampaha',
                validator: (v) => v == null || v.isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 28),

              AppButton(
                text: 'Publish Listing',
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
