class CategorySpecFieldModel {
  final String key;
  final String label;
  final String unit;
  final String fieldType; // 'text', 'number', 'select'
  final bool isRequired;
  final List<String> options;

  const CategorySpecFieldModel({
    required this.key,
    required this.label,
    this.unit = '',
    this.fieldType = 'text',
    this.isRequired = false,
    this.options = const [],
  });

  factory CategorySpecFieldModel.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['options'] as List<dynamic>? ?? [];
    return CategorySpecFieldModel(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      unit: json['unit'] ?? '',
      fieldType: json['fieldType'] ?? 'text',
      isRequired: json['isRequired'] ?? false,
      options: rawOptions.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'unit': unit,
      'fieldType': fieldType,
      'isRequired': isRequired,
      'options': options,
    };
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final bool isActive;
  final String specificationSchemaJson;
  final List<CategorySpecFieldModel> specificationSchema;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.iconUrl = '',
    this.isActive = true,
    this.specificationSchemaJson = '[]',
    this.specificationSchema = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    var rawSchema = json['specificationSchema'] as List<dynamic>? ?? [];
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      isActive: json['isActive'] ?? true,
      specificationSchemaJson: json['specificationSchemaJson'] ?? '[]',
      specificationSchema: rawSchema
          .map((e) => CategorySpecFieldModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'isActive': isActive,
      'specificationSchemaJson': specificationSchemaJson,
      'specificationSchema': specificationSchema.map((e) => e.toJson()).toList(),
    };
  }
}
