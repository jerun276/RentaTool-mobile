import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/equipment_model.dart';
import '../providers/catalog_provider.dart';
import '../services/catalog_service.dart';

class AddEquipmentScreen extends ConsumerStatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  ConsumerState<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentPhoto {
  final String angle;
  final String path;
  bool isPrimary;

  _AddEquipmentPhoto({
    required this.angle,
    required this.path,
    this.isPrimary = false,
  });
}

class _AddEquipmentScreenState extends ConsumerState<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _replacementValController = TextEditingController();
  final _locationController = TextEditingController(text: 'Colombo, Western Province');

  // Spec fields
  final _powerOutputController = TextEditingController();
  final _weightController = TextEditingController();
  final _voltageController = TextEditingController();
  final _fuelTypeController = TextEditingController();

  final _picker = ImagePicker();
  final List<_AddEquipmentPhoto> _photos = [];

  // Known categories from backend seed
  final Map<String, String> _categories = {
    '352ea07e-bd97-481b-a287-027036658902': 'Heavy Machinery',
    'b25c3bf2-9d33-4df4-b3c9-02660a92d244': 'Power Tools',
    '64949df2-eb06-4447-920a-f0fbf1fa000a': 'Generators & Power',
    '8ca549e3-2fc5-48b3-aa2d-aa5d15a7cf93': 'Cleaning Equipment',
  };

  late String _selectedCategoryId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = _categories.keys.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dailyRateController.dispose();
    _replacementValController.dispose();
    _locationController.dispose();
    _powerOutputController.dispose();
    _weightController.dispose();
    _voltageController.dispose();
    _fuelTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String angle) async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1280,
      );
      if (img != null) {
        setState(() {
          _photos.add(_AddEquipmentPhoto(
            angle: angle,
            path: img.path,
            isPrimary: _photos.isEmpty,
          ));
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final dailyRate = double.tryParse(_dailyRateController.text.replaceAll(',', ''));
    if (dailyRate == null || dailyRate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid daily rate')),
      );
      return;
    }

    final replacementValue = double.tryParse(_replacementValController.text.replaceAll(',', ''));
    if (replacementValue == null || replacementValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid replacement value')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(catalogServiceProvider);

      // Serialize specs to JSON
      final specsMap = <String, dynamic>{};
      if (_powerOutputController.text.isNotEmpty) specsMap['PowerOutput'] = _powerOutputController.text.trim();
      if (_weightController.text.isNotEmpty) specsMap['OperatingWeight'] = _weightController.text.trim();
      if (_voltageController.text.isNotEmpty) specsMap['Voltage'] = _voltageController.text.trim();
      if (_fuelTypeController.text.isNotEmpty) specsMap['FuelType'] = _fuelTypeController.text.trim();
      final specsJson = jsonEncode(specsMap);

      final cloudinary = ref.read(cloudinaryServiceProvider);
      final toolImages = await Future.wait(_photos.map((p) async {
        final uploadedUrl = await cloudinary.uploadImage(
          p.path,
          folder: 'rentatool/equipment',
        );
        return ToolImageModel(
          imageUrl: uploadedUrl,
          angle: p.angle,
          isPrimary: p.isPrimary,
        );
      }));

      await service.createEquipment(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        categoryId: _selectedCategoryId,
        dailyRate: dailyRate,
        replacementValue: replacementValue,
        location: _locationController.text.trim(),
        specificationsJson: specsJson,
        images: toolImages,
      );

      ref.read(catalogProvider.notifier).fetchEquipment();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment listing published successfully to catalog.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to publish listing. Please check inputs and server connection.'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Machinery Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Core Details
              _sectionHeader('1. BASIC EQUIPMENT DETAILS'),
              const SizedBox(height: 12),

              AppTextField(
                controller: _titleController,
                label: 'Equipment Title & Model',
                hintText: 'e.g. Caterpillar 320D Hydraulic Excavator',
                validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _descController,
                label: 'Overview & Capabilities',
                hintText: 'Describe machine condition, capabilities, operating limits, and features...',
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              // Category Selector
              Text('EQUIPMENT CATEGORY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategoryId,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    items: _categories.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategoryId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _locationController,
                label: 'Base Depot Location',
                hintText: 'e.g. Colombo 05, Sri Lanka',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20, color: AppColors.textMuted),
                validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 24),

              // Section 2: Pricing & Deposit
              _sectionHeader('2. PRICING & ESCROW VALUATION'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _dailyRateController,
                      label: 'Daily Rate (LKR)',
                      hintText: '18,500',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.payments_outlined, size: 18, color: AppColors.primaryLight),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _replacementValController,
                      label: 'Replacement (LKR)',
                      hintText: '2,500,000',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.shield_outlined, size: 18, color: AppColors.warning),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section 3: Technical Specs
              _sectionHeader('3. TECHNICAL SPECIFICATIONS'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _powerOutputController,
                      label: 'Power Rating',
                      hintText: 'e.g. 105 kW / 140 HP',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _weightController,
                      label: 'Operating Weight',
                      hintText: 'e.g. 21,500 kg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _voltageController,
                      label: 'Voltage / Source',
                      hintText: 'e.g. 3-Phase 400V',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _fuelTypeController,
                      label: 'Fuel / Energy Type',
                      hintText: 'e.g. Diesel / Electric',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section 4: Multi-Angle Imagery
              _sectionHeader('4. MULTI-ANGLE EQUIPMENT PHOTOS'),
              const SizedBox(height: 4),
              Text(
                'Upload designated angles for initial asset baseline inspection.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                children: [
                  _addPhotoChip('General'),
                  _addPhotoChip('Casing'),
                  _addPhotoChip('Cord / Wiring'),
                  _addPhotoChip('Motor / Engine'),
                ],
              ),
              const SizedBox(height: 12),

              if (_photos.isNotEmpty)
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    itemBuilder: (context, idx) {
                      final p = _photos[idx];
                      return Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: p.isPrimary ? AppColors.primaryLight : AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            p.path.startsWith('http')
                                ? Image.network(p.path, fit: BoxFit.cover)
                                : Image.file(File(p.path), fit: BoxFit.cover),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => setState(() => _photos.removeAt(idx)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: const Color(0xCC000000),
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  p.angle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 32),

              // Publish Button
              AppButton(
                text: 'Publish Machinery Listing',
                isLoading: _isSubmitting,
                icon: Icons.publish,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: AppColors.primaryLight,
      ),
    );
  }

  Widget _addPhotoChip(String angle) {
    return ActionChip(
      avatar: const Icon(Icons.add_a_photo_outlined, size: 14, color: AppColors.primaryLight),
      label: Text(angle, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: AppColors.border),
      onPressed: () => _pickImage(angle),
    );
  }
}
