import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentatool_mobile/modules/catalog/models/category_model.dart';

void main() {
  group('Category & Dynamic Specification Schema Unit Tests', () {
    test('CategorySpecFieldModel parses text and number fields properly', () {
      final json = {
        'key': 'operatingWeight',
        'label': 'Operating Weight',
        'unit': 'kg',
        'fieldType': 'number',
        'isRequired': true,
        'options': [],
      };

      final field = CategorySpecFieldModel.fromJson(json);

      expect(field.key, equals('operatingWeight'));
      expect(field.label, equals('Operating Weight'));
      expect(field.unit, equals('kg'));
      expect(field.fieldType, equals('number'));
      expect(field.isRequired, isTrue);
      expect(field.options, isEmpty);

      final serialized = field.toJson();
      expect(serialized['key'], equals('operatingWeight'));
      expect(serialized['unit'], equals('kg'));
    });

    test('CategorySpecFieldModel parses select dropdown options', () {
      final json = {
        'key': 'powerSource',
        'label': 'Power Source',
        'unit': 'V',
        'fieldType': 'select',
        'isRequired': false,
        'options': ['110V', '230V Single-Phase', '400V 3-Phase'],
      };

      final field = CategorySpecFieldModel.fromJson(json);

      expect(field.fieldType, equals('select'));
      expect(field.options.length, equals(3));
      expect(field.options, contains('400V 3-Phase'));
    });

    test('CategoryModel correctly parses specificationSchema array from API', () {
      final json = {
        'id': 'b25c3bf2-9d33-4df4-b3c9-02660a92d244',
        'name': 'Power Tools',
        'description': 'Portable electric and battery equipment',
        'iconUrl': 'https://rentatool.lk/icons/power-tools.png',
        'isActive': true,
        'specificationSchemaJson': '[{"key":"powerSource","label":"Power Source","fieldType":"select","options":["Corded","Cordless"]}]',
        'specificationSchema': [
          {
            'key': 'powerSource',
            'label': 'Power Source',
            'unit': '',
            'fieldType': 'select',
            'isRequired': true,
            'options': ['Corded', 'Cordless'],
          },
          {
            'key': 'ratedPower',
            'label': 'Rated Power',
            'unit': 'Watts',
            'fieldType': 'number',
            'isRequired': false,
            'options': [],
          }
        ],
      };

      final cat = CategoryModel.fromJson(json);

      expect(cat.id, equals('b25c3bf2-9d33-4df4-b3c9-02660a92d244'));
      expect(cat.name, equals('Power Tools'));
      expect(cat.specificationSchema.length, equals(2));
      expect(cat.specificationSchema[0].key, equals('powerSource'));
      expect(cat.specificationSchema[0].options, contains('Cordless'));
      expect(cat.specificationSchema[1].unit, equals('Watts'));

      final serialized = cat.toJson();
      expect(serialized['name'], equals('Power Tools'));
      expect(serialized['specificationSchema'], isA<List>());
    });

    test('Dynamic specifications serialize cleanly into equipment specificationsJson', () {
      final fields = [
        const CategorySpecFieldModel(key: 'power', label: 'Power Rating', unit: 'kW', fieldType: 'number'),
        const CategorySpecFieldModel(key: 'fuel', label: 'Fuel Type', fieldType: 'select', options: ['Diesel', 'Petrol']),
      ];

      final values = <String, String>{
        'power': '15',
        'fuel': 'Diesel',
      };

      final specsMap = <String, dynamic>{};
      for (final f in fields) {
        final val = values[f.key];
        if (val != null && val.isNotEmpty) {
          final formatted = f.unit.isNotEmpty ? '$val ${f.unit}' : val;
          specsMap[f.label] = formatted;
        }
      }

      final specsJson = jsonEncode(specsMap);
      expect(specsJson, contains('"Power Rating":"15 kW"'));
      expect(specsJson, contains('"Fuel Type":"Diesel"'));

      final decoded = jsonDecode(specsJson) as Map<String, dynamic>;
      expect(decoded['Power Rating'], equals('15 kW'));
      expect(decoded['Fuel Type'], equals('Diesel'));
    });
  });
}
