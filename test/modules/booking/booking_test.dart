import 'package:flutter_test/flutter_test.dart';
import 'package:rentatool_mobile/modules/booking/models/booking_model.dart';
import 'package:rentatool_mobile/modules/booking/models/create_booking_request.dart';
import 'package:rentatool_mobile/modules/booking/models/handover_token_model.dart';
import 'package:rentatool_mobile/modules/booking/models/handover_verification_model.dart';
import 'package:rentatool_mobile/modules/booking/models/schedule_extension_model.dart';

void main() {
  group('Booking Module - Component 3 Unit Tests', () {
    test('BookingModel correctly deserializes from JSON with dailyRate', () {
      final json = {
        'id': 'book-12345678',
        'equipmentId': 'eq-456',
        'renterId': 'user-1',
        'ownerId': 'user-2',
        'startDate': '2026-09-20T10:00:00.000Z',
        'endDate': '2026-09-25T10:00:00.000Z',
        'dailyRate': 150.0,
        'totalRentalFee': 750.0,
        'status': 'Confirmed',
        'pickupVerified': true,
        'returnVerified': false,
      };

      final booking = BookingModel.fromJson(json);

      expect(booking.id, 'book-12345678');
      expect(booking.equipmentId, 'eq-456');
      expect(booking.renterId, 'user-1');
      expect(booking.ownerId, 'user-2');
      expect(booking.dailyRate, 150.0);
      expect(booking.totalRentalFee, 750.0);
      expect(booking.status, 'Confirmed');
      expect(booking.pickupVerified, isTrue);
      expect(booking.returnVerified, isFalse);
      expect(booking.displayCode, 'BKG-BOOK-123');
      expect(booking.durationInDays, 6);
      expect(booking.isConfirmed, isTrue);
      expect(booking.isActive, isFalse);
      expect(booking.canGeneratePickupToken, isFalse); // Already verified
      expect(booking.canExtendSchedule, isTrue);
    });

    test('BookingModel computes dailyRate when omitted in summary DTO', () {
      final json = {
        'id': 'bkg-summary-01',
        'equipmentId': 'eq-999',
        'renterId': 'user-renter',
        'ownerId': 'user-owner',
        'startDate': '2026-10-01T00:00:00.000Z',
        'endDate': '2026-10-04T00:00:00.000Z',
        'totalRentalFee': 4000.0,
        'status': 'Active',
      };

      final booking = BookingModel.fromJson(json);

      expect(booking.durationInDays, 4);
      expect(booking.dailyRate, 1000.0); // 4000 / 4
      expect(booking.isActive, isTrue);
      expect(booking.canGenerateReturnToken, isTrue);
      expect(booking.canDispute, isTrue);
    });

    test('CreateBookingRequestModel calculates duration and fee correctly', () {
      final start = DateTime.parse('2026-10-01T00:00:00.000Z');
      final end = DateTime.parse('2026-10-05T00:00:00.000Z');
      final request = CreateBookingRequestModel(
        equipmentId: 'eq-100',
        ownerId: 'owner-200',
        startDate: start,
        endDate: end,
        dailyRate: 2500.0,
      );

      expect(request.durationInDays, 5);
      expect(request.estimatedTotalFee, 12500.0);

      final json = request.toJson();
      expect(json['equipmentId'], 'eq-100');
      expect(json['ownerId'], 'owner-200');
      expect(json['dailyRate'], 2500.0);
    });

    test('HandoverTokenModel parses countdown & TTL correctly', () {
      final now = DateTime.now().toUtc();
      final expires = now.add(const Duration(minutes: 10, seconds: 30));

      final json = {
        'bookingId': 'book-123',
        'token': 'RT-8A9F-2B4C-1D3E',
        'eventType': 'Pickup',
        'expiresAtUtc': expires.toIso8601String(),
        'instructions': 'Scan to complete pickup.',
      };

      final token = HandoverTokenModel.fromJson(json);

      expect(token.bookingId, 'book-123');
      expect(token.token, 'RT-8A9F-2B4C-1D3E');
      expect(token.eventType, 'Pickup');
      expect(token.isExpired, isFalse);
      expect(token.remainingSeconds, greaterThan(600));
      expect(token.formattedRemainingTime, contains(':'));
    });

    test('VerifyHandoverRequestModel serializes with GPS and eventType integer', () {
      const request = VerifyHandoverRequestModel(
        token: 'RT-8A9F-2B4C-1D3E',
        eventType: 'Return',
        latitude: 6.9271,
        longitude: 79.8612,
        addressLine: 'Central Depot',
        city: 'Colombo',
        postalCode: '00100',
      );

      expect(request.eventTypeInt, 2); // 2 for Return

      final json = request.toJson();
      expect(json['token'], 'RT-8A9F-2B4C-1D3E');
      expect(json['eventType'], 2);
      expect(json['latitude'], 6.9271);
      expect(json['longitude'], 79.8612);
      expect(json['city'], 'Colombo');
    });

    test('HandoverVerificationResponseModel parses backend confirmation', () {
      final json = {
        'bookingId': 'book-123',
        'eventType': 'Pickup',
        'verifiedAtUtc': '2026-09-24T12:00:00.000Z',
        'newBookingStatus': 'Active',
        'isSuccess': true,
        'message': 'Handover Pickup successfully verified.',
      };

      final response = HandoverVerificationResponseModel.fromJson(json);

      expect(response.bookingId, 'book-123');
      expect(response.eventType, 'Pickup');
      expect(response.newBookingStatus, 'Active');
      expect(response.isSuccess, isTrue);
    });

    test('ExtendScheduleResponseModel parses dynamic surge pricing', () {
      final json = {
        'bookingId': 'book-123',
        'previousEndDate': '2026-09-25T23:59:59.000Z',
        'newEndDate': '2026-09-27T23:59:59.000Z',
        'extendedDays': 2,
        'baseDailyRate': 3000.0,
        'surgeMultiplier': 1.25,
        'surgeDailyRate': 3750.0,
        'additionalFee': 7500.0,
        'newTotalRentalFee': 22500.0,
        'reason': 'High Weekend Demand (+25%)',
      };

      final response = ExtendScheduleResponseModel.fromJson(json);

      expect(response.extendedDays, 2);
      expect(response.baseDailyRate, 3000.0);
      expect(response.surgeMultiplier, 1.25);
      expect(response.hasSurge, isTrue);
      expect(response.surgePercentageString, '+25%');
      expect(response.additionalFee, 7500.0);
      expect(response.reason, contains('Weekend'));
    });
  });
}
