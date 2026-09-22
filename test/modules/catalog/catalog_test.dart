import 'package:flutter_test/flutter_test.dart';
import 'package:rentatool_mobile/modules/catalog/models/batch_availability_model.dart';
import 'package:rentatool_mobile/modules/catalog/models/equipment_history_model.dart';
import 'package:rentatool_mobile/modules/catalog/models/equipment_model.dart';
import 'package:rentatool_mobile/modules/catalog/models/inspection_log_model.dart';

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
        'images': [
          {'imageUrl': 'https://example.com/casing.jpg', 'angle': 'Casing', 'isPrimary': false},
          {'imageUrl': 'https://example.com/main.jpg', 'angle': 'General', 'isPrimary': true},
        ],
      };

      final healthy = EquipmentModel.fromJson(healthyJson);
      expect(healthy.isWearLocked, isFalse);
      expect(healthy.isWearLimitReached, isFalse);
      expect(healthy.daysUntilLockout, 36);
      expect(healthy.primaryImageUrl, 'https://example.com/main.jpg');
      expect(healthy.images.length, 2);

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
      expect(locked.isWearLimitReached, isTrue);
      expect(locked.daysUntilLockout, 0);
      expect(locked.totalRentalDaysAccumulated, 62);
    });

    test('InspectionLogModel parses multi-angle photos and severity', () {
      final json = {
        'id': 'insp-001',
        'equipmentId': 'eq-100',
        'bookingId': 'book-200',
        'inspectorUserId': 'user-inspector-1',
        'type': 'PreRental',
        'severity': 'Moderate',
        'conditionNotes': 'Slight abrasion observed on motor chassis, wiring intact.',
        'photos': [
          {
            'angle': 'Casing',
            'photoUrl': 'https://storage.rentatool.lk/insp1_casing.jpg',
            'observationNote': 'Minor surface scratching on outer enamel',
            'capturedAtUtc': '2026-09-22T08:30:00.000Z',
          },
          {
            'angle': 'Cord',
            'photoUrl': 'https://storage.rentatool.lk/insp1_cord.jpg',
            'observationNote': 'Double-insulated cord in pristine condition',
            'capturedAtUtc': '2026-09-22T08:31:00.000Z',
          },
          {
            'angle': 'Motor',
            'photoUrl': 'https://storage.rentatool.lk/insp1_motor.jpg',
            'observationNote': 'No fluid leakage detected, brushes operational',
            'capturedAtUtc': '2026-09-22T08:32:00.000Z',
          },
        ],
        'createdAtUtc': '2026-09-22T08:35:00.000Z',
      };

      final log = InspectionLogModel.fromJson(json);

      expect(log.id, 'insp-001');
      expect(log.equipmentId, 'eq-100');
      expect(log.bookingId, 'book-200');
      expect(log.inspectorId, 'user-inspector-1');
      expect(log.inspectionType, 'PreRental');
      expect(log.severity, 'Moderate');
      expect(log.isSevereOrCritical, isFalse);
      expect(log.photos.length, 3);
      expect(log.photos[0].angle, 'Casing');
      expect(log.photos[0].capturedAtUtc, isNotNull);
      expect(log.photos[1].angle, 'Cord');
      expect(log.photos[2].angle, 'Motor');
    });

    test('EquipmentHistoryTimelineModel correctly deserializes timeline records', () {
      final json = {
        'equipmentId': 'eq-777',
        'title': 'Hitachi ZX200-5G Excavator',
        'totalRentalDays': 64,
        'requiresMaintenance': true,
        'lastServicingDateUtc': '2026-07-15T10:00:00.000Z',
        'inspectionTimeline': [
          {
            'id': 'log-1',
            'equipmentId': 'eq-777',
            'inspectorUserId': 'u-1',
            'type': 'PostRental',
            'severity': 'Critical',
            'conditionNotes': 'Hydraulic hose rupture observed after trenching work.',
            'photos': [],
            'createdAtUtc': '2026-09-20T14:00:00.000Z',
          }
        ],
      };

      final history = EquipmentHistoryTimelineModel.fromJson(json);

      expect(history.equipmentId, 'eq-777');
      expect(history.totalRentalDays, 64);
      expect(history.isLockoutTriggered, isTrue);
      expect(history.inspectionTimeline.length, 1);
      expect(history.inspectionTimeline.first.isSevereOrCritical, isTrue);
    });

    test('BatchAvailabilityResultModel detects wear policy lockouts accurately', () {
      final json = {
        'totalRequested': 2,
        'totalAvailable': 1,
        'totalLockedOut': 1,
        'availableItems': [
          {
            'equipmentId': 'eq-avail',
            'title': 'Honda EU2200i Generator',
            'dailyRate': 8500.0,
            'accumulatedDays': 18,
            'isSafeForDispatch': true,
          }
        ],
        'lockedOutItems': [
          {
            'equipmentId': 'eq-locked',
            'title': 'Bomag BW120 Road Roller',
            'lockoutReason': 'Wear limit reached (61/60 days)',
            'requiredAction': 'Mandatory comprehensive safety servicing required before dispatch.',
            'accumulatedRentalDays': 61,
            'servicingMandatory': true,
          }
        ],
      };

      final result = BatchAvailabilityResultModel.fromJson(json);

      expect(result.totalRequested, 2);
      expect(result.totalAvailable, 1);
      expect(result.totalLockedOut, 1);
      expect(result.hasLockouts, isTrue);
      expect(result.availableItems.first.isSafeForDispatch, isTrue);
      expect(result.lockedOutItems.first.servicingMandatory, isTrue);
      expect(result.lockedOutItems.first.accumulatedRentalDays, 61);
    });
  });
}
