import 'package:flutter_test/flutter_test.dart';
import 'package:rentatool_mobile/modules/catalog/models/equipment_model.dart';

void main() {
  group('Catalog Module - Component 2 Unit Tests', () {
    test('EquipmentModel detects 60-day wear lockout trigger correctly', () {
      final healthyJson = {
        'id': 'eq-1',
        'ownerId': 'owner-1',
        'title': 'Caterpillar 320D Excavator',
        'description': 'Heavy hydraulic rock breaker',
        'categoryId': 'cat-1',
        'categoryName': 'Heavy Machinery',
        'dailyRate': 32000.0,
        'replacementValue': 18000000.0,
        'status': 'Available',
        'location': 'Colombo 05',
        'totalRentalDaysAccumulated': 24,
        'requiresMaintenanceCheck': false,
      };

      final healthy = EquipmentModel.fromJson(healthyJson);
      expect(healthy.isWearLocked, isFalse);

      final lockedJson = {
        'id': 'eq-2',
        'ownerId': 'owner-2',
        'title': 'Komatsu PC200-8 Crawler Excavator',
        'description': 'Mandatory overhaul flagged',
        'categoryId': 'cat-1',
        'categoryName': 'Heavy Machinery',
        'dailyRate': 38000.0,
        'replacementValue': 22000000.0,
        'status': 'UnderMaintenance',
        'location': 'Kurunegala',
        'totalRentalDaysAccumulated': 62,
        'requiresMaintenanceCheck': true,
      };

      final locked = EquipmentModel.fromJson(lockedJson);
      expect(locked.isWearLocked, isTrue);
      expect(locked.totalRentalDaysAccumulated, 62);
    });
  });
}
