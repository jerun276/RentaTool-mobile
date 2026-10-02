import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/category_model.dart';
import '../providers/catalog_provider.dart';
import '../services/catalog_service.dart';

class AdminCategoryScreen extends ConsumerStatefulWidget {
  const AdminCategoryScreen({super.key});

  @override
  ConsumerState<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends ConsumerState<AdminCategoryScreen> {
  void _openCreateCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateCategoryBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category & Spec Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Categories',
            onPressed: () => ref.invalidate(categoryListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
        onPressed: () => _openCreateCategorySheet(context),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No categories defined yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first category and define dynamic specification fields.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: 'Create Category',
                    icon: Icons.add,
                    onPressed: () => _openCreateCategorySheet(context),
                  ),
                ],
              ),
            );
          }

          final totalSpecFields = categories.fold<int>(
            0,
            (acc, cat) => acc + cat.specificationSchema.length,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              // Summary Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF064E3B), const Color(0xFF0F172A)]
                        : [const Color(0xFFECFDF5), const Color(0xFFF1F5F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.tune, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dynamic Specification Engine',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Categories define dynamic input forms for listings. Each category has tailored technical attributes.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _statChip('${categories.length} Categories', Icons.folder_outlined),
                              const SizedBox(width: 8),
                              _statChip('$totalSpecFields Dynamic Fields', Icons.list_alt_outlined),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CONFIGURED CATEGORIES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    '${categories.length} items',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category Cards
              ...categories.map((category) => _buildCategoryCard(category, isDark)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load categories', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
              const SizedBox(height: 6),
              Text(err.toString(), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
              AppButton(
                text: 'Retry',
                icon: Icons.refresh,
                onPressed: () => ref.invalidate(categoryListProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, bool isDark) {
    final fields = category.specificationSchema;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.handyman_outlined, color: AppColors.primary, size: 22),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            StatusBadge(
              label: category.isActive ? 'ACTIVE' : 'INACTIVE',
              style: category.isActive ? BadgeStyle.success : BadgeStyle.error,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text(
                '${fields.length} dynamic specification fields',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.description.isNotEmpty) ...[
                  Text(
                    category.description,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                ],
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'SPECIFICATION SCHEMA FIELDS:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                if (fields.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No technical specification fields configured.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                    ),
                  )
                else
                  ...fields.map((f) => _buildSpecFieldRow(f, isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecFieldRow(CategorySpecFieldModel field, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              if (field.unit.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  '(${field.unit})',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _badgeColorForType(field.fieldType).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  field.fieldType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _badgeColorForType(field.fieldType),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (field.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'REQUIRED',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Key: ${field.key}',
            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMuted),
          ),
          if (field.options.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: field.options.map((opt) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(opt, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _badgeColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'number':
        return AppColors.info;
      case 'select':
        return AppColors.purple;
      default:
        return AppColors.primaryLight;
    }
  }
}

class _DraftField {
  final TextEditingController keyCtrl;
  final TextEditingController labelCtrl;
  final TextEditingController unitCtrl;
  final TextEditingController optionsCtrl;
  String fieldType;
  bool isRequired;

  _DraftField({
    String key = '',
    String label = '',
    String unit = '',
    String options = '',
    this.fieldType = 'text',
    this.isRequired = false,
  })  : keyCtrl = TextEditingController(text: key),
        labelCtrl = TextEditingController(text: label),
        unitCtrl = TextEditingController(text: unit),
        optionsCtrl = TextEditingController(text: options);

  void dispose() {
    keyCtrl.dispose();
    labelCtrl.dispose();
    unitCtrl.dispose();
    optionsCtrl.dispose();
  }
}

class _CreateCategoryBottomSheet extends ConsumerStatefulWidget {
  const _CreateCategoryBottomSheet();

  @override
  ConsumerState<_CreateCategoryBottomSheet> createState() => _CreateCategoryBottomSheetState();
}

class _CreateCategoryBottomSheetState extends ConsumerState<_CreateCategoryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<_DraftField> _draftFields = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Start with 2 sample field templates
    _addField(label: 'Model / Variant', key: 'modelVariant', fieldType: 'text', isRequired: false);
    _addField(label: 'Operating Capacity', key: 'operatingCapacity', unit: 'kg', fieldType: 'number', isRequired: true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final f in _draftFields) {
      f.dispose();
    }
    super.dispose();
  }

  void _addField({
    String label = '',
    String key = '',
    String unit = '',
    String options = '',
    String fieldType = 'text',
    bool isRequired = false,
  }) {
    setState(() {
      _draftFields.add(
        _DraftField(
          label: label,
          key: key,
          unit: unit,
          options: options,
          fieldType: fieldType,
          isRequired: isRequired,
        ),
      );
    });
  }

  void _removeField(int index) {
    setState(() {
      _draftFields[index].dispose();
      _draftFields.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    // Convert draft fields to CategorySpecFieldModel
    final schema = <CategorySpecFieldModel>[];
    for (final d in _draftFields) {
      final label = d.labelCtrl.text.trim();
      if (label.isEmpty) continue;

      var key = d.keyCtrl.text.trim();
      if (key.isEmpty) {
        // Auto-slugify label into camelCase key
        key = label
            .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
            .split(' ')
            .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
            .join();
        if (key.isNotEmpty) {
          key = key[0].toLowerCase() + key.substring(1);
        }
      }

      final opts = d.optionsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      schema.add(
        CategorySpecFieldModel(
          key: key,
          label: label,
          unit: d.unitCtrl.text.trim(),
          fieldType: d.fieldType,
          isRequired: d.isRequired,
          options: opts,
        ),
      );
    }

    setState(() => _isSaving = true);
    try {
      final service = ref.read(catalogServiceProvider);
      await service.createCategory(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        specificationSchema: schema,
      );

      ref.invalidate(categoryListProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category created successfully with dynamic specifications!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create category: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Machinery Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Configure dynamic specifications for listings',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _nameCtrl,
                      label: 'Category Name *',
                      hintText: 'e.g. Earthmoving & Excavation',
                      validator: (v) => v == null || v.trim().isEmpty ? 'Category name is required' : null,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      controller: _descCtrl,
                      label: 'Description',
                      hintText: 'e.g. Heavy equipment for digging, earth transport, and site grading...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // Specification Fields Builder Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SPECIFICATION SCHEMA FIELDS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _addField(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Field', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_draftFields.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'No specification fields added yet. Equipment in this category will not require custom technical specs.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ..._draftFields.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final field = entry.value;
                        return _buildDraftFieldCard(idx, field);
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            AppButton(
              text: 'Save & Publish Category',
              icon: Icons.check_circle_outline,
              isLoading: _isSaving,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftFieldCard(int index, _DraftField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Field #${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.primaryLight,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _removeField(index),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: field.labelCtrl,
                  label: 'Field Label *',
                  hintText: 'e.g. Engine Power',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField(
                  controller: field.unitCtrl,
                  label: 'Unit',
                  hintText: 'e.g. HP / kW',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Input Type',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: field.fieldType,
                          isExpanded: true,
                          dropdownColor: AppColors.surface,
                          items: const [
                            DropdownMenuItem(value: 'text', child: Text('Text', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'number', child: Text('Number', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'select', child: Text('Dropdown', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => field.fieldType = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Switch.adaptive(
                    value: field.isRequired,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => field.isRequired = val),
                  ),
                ],
              ),
            ],
          ),

          if (field.fieldType == 'select') ...[
            const SizedBox(height: 10),
            AppTextField(
              controller: field.optionsCtrl,
              label: 'Options (Comma separated)',
              hintText: 'e.g. 110V, 230V, 400V 3-Phase',
              validator: (v) {
                if (field.fieldType == 'select' && (v == null || v.trim().isEmpty)) {
                  return 'Options required for dropdown';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }
}
