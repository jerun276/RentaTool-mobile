import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/sri_lanka_locations.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/category_model.dart';
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

  // Dynamic spec controllers & dropdown selections
  final Map<String, TextEditingController> _dynamicControllers = {};
  final Map<String, String> _dynamicDropdownValues = {};

  final _picker = ImagePicker();
  final List<_AddEquipmentPhoto> _photos = [];

  String? _selectedCategoryId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dailyRateController.dispose();
    _replacementValController.dispose();
    _locationController.dispose();
    for (final c in _dynamicControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initCategorySpecs(CategoryModel category) {
    for (final field in category.specificationSchema) {
      if (field.fieldType == 'select') {
        if (!_dynamicDropdownValues.containsKey(field.key)) {
          _dynamicDropdownValues[field.key] =
              field.options.isNotEmpty ? field.options.first : '';
        }
      } else {
        _dynamicControllers.putIfAbsent(field.key, () => TextEditingController());
      }
    }
  }

  void _onCategoryChanged(CategoryModel category) {
    setState(() {
      _selectedCategoryId = category.id;
      for (final c in _dynamicControllers.values) {
        c.dispose();
      }
      _dynamicControllers.clear();
      _dynamicDropdownValues.clear();
      _initCategorySpecs(category);
    });
  }

  Future<void> _pickLocation() async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final items = SriLankaLocations.all
                .where((l) => l.toLowerCase().contains(query.toLowerCase()))
                .toList();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.7,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'Select Base Depot Location',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search city or province',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (v) => setSheetState(() => query = v),
                        ),
                      ),
                      Expanded(
                        child: items.isEmpty
                            ? const Center(child: Text('No matching locations'))
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: items.length,
                                itemBuilder: (_, i) {
                                  final loc = items[i];
                                  final isSelected = loc == _locationController.text;
                                  return ListTile(
                                    leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                                    title: Text(loc),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                                        : null,
                                    onTap: () => Navigator.of(ctx).pop(loc),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (selected != null) {
      setState(() => _locationController.text = selected);
    }
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

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an equipment category')),
      );
      return;
    }

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

    final categories = ref.read(categoryListProvider).valueOrNull ?? [];
    final selectedCategory = categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => CategoryModel(id: _selectedCategoryId!, name: ''),
    );

    // Validate required dynamic fields
    for (final field in selectedCategory.specificationSchema) {
      if (field.isRequired) {
        if (field.fieldType == 'select') {
          final val = _dynamicDropdownValues[field.key];
          if (val == null || val.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${field.label} is required')),
            );
            return;
          }
        } else {
          final val = _dynamicControllers[field.key]?.text.trim() ?? '';
          if (val.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${field.label} is required')),
            );
            return;
          }
        }
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(catalogServiceProvider);

      // Serialize dynamic specs to JSON with human-readable labels and units
      final specsMap = <String, dynamic>{};
      for (final field in selectedCategory.specificationSchema) {
        if (field.fieldType == 'select') {
          final val = _dynamicDropdownValues[field.key];
          if (val != null && val.trim().isNotEmpty) {
            specsMap[field.label] = val;
          }
        } else {
          final text = _dynamicControllers[field.key]?.text.trim() ?? '';
          if (text.isNotEmpty) {
            String formatted = text;
            if (field.unit.isNotEmpty && !formatted.toLowerCase().endsWith(field.unit.toLowerCase())) {
              formatted = '$formatted ${field.unit}';
            }
            specsMap[field.label] = formatted;
          }
        }
      }
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
        categoryId: _selectedCategoryId!,
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
    final categoriesAsync = ref.watch(categoryListProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    CategoryModel? selectedCategory;
    if (categories.isNotEmpty) {
      selectedCategory = categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => categories.first,
      );
      if (_selectedCategoryId != selectedCategory.id) {
        _selectedCategoryId = selectedCategory.id;
      }
      _initCategorySpecs(selectedCategory);
    }

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

              // Category Selector (Dynamic)
              Text(
                'EQUIPMENT CATEGORY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              categoriesAsync.when(
                data: (cats) {
                  if (cats.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text('No categories configured in system.', style: TextStyle(color: AppColors.warning)),
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategoryId ?? cats.first.id,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        items: cats.map((cat) {
                          return DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final cat = cats.firstWhere((c) => c.id == val);
                            _onCategoryChanged(cat);
                          }
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Failed to load categories', style: TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: () => ref.invalidate(categoryListProvider),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _pickLocation,
                behavior: HitTestBehavior.opaque,
                child: AbsorbPointer(
                  child: AppTextField(
                    controller: _locationController,
                    label: 'Base Depot Location',
                    hintText: 'Tap to select a location',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20, color: AppColors.textMuted),
                    suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null,
                  ),
                ),
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

              // Section 3: Dynamic Technical Specs
              _sectionHeader('3. DYNAMIC TECHNICAL SPECIFICATIONS'),
              const SizedBox(height: 4),
              Text(
                selectedCategory != null && selectedCategory.specificationSchema.isNotEmpty
                    ? 'Specification fields configured for ${selectedCategory.name}:'
                    : 'No dynamic specifications configured for this category.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              if (selectedCategory != null && selectedCategory.specificationSchema.isNotEmpty)
                _buildDynamicSpecificationFields(selectedCategory)
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No dynamic fields required. You can add extra details in the overview description.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildDynamicSpecificationFields(CategoryModel category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: category.specificationSchema.map((field) {
        if (field.fieldType == 'select') {
          final currentValue = _dynamicDropdownValues[field.key] ??
              (field.options.isNotEmpty ? field.options.first : null);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      field.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (field.isRequired)
                      const Text(
                        ' *',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                      ),
                    if (field.unit.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text('(${field.unit})', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: field.options.contains(currentValue) ? currentValue : null,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      hint: Text(
                        field.options.isNotEmpty ? 'Select ${field.label}' : 'No options configured',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                      items: field.options.map((opt) {
                        return DropdownMenuItem<String>(
                          value: opt,
                          child: Text(opt, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _dynamicDropdownValues[field.key] = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final isNumber = field.fieldType == 'number';
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AppTextField(
            controller: _dynamicControllers[field.key],
            label: field.isRequired ? '${field.label} *' : field.label,
            hintText: field.unit.isNotEmpty
                ? 'Enter ${field.label.toLowerCase()} (${field.unit})'
                : 'Enter ${field.label.toLowerCase()}',
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            suffixIcon: field.unit.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      widthFactor: 1.0,
                      child: Text(
                        field.unit,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                : null,
            validator: field.isRequired
                ? (v) => v == null || v.trim().isEmpty ? '${field.label} is required' : null
                : null,
          ),
        );
      }).toList(),
    );
  }
}
