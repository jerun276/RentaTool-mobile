import 'package:flutter_test/flutter_test.dart';
import 'package:rentatool_mobile/modules/booking/models/booking_model.dart';
import 'package:rentatool_mobile/modules/booking/models/handover_token_model.dart';

void main() {
  group('Booking Module - Component 3 Unit Tests', () {
    test('BookingModel correctly deserializes from JSON', () {
      final json = {
        'id': 'book-123',
        'equipmentId': 'eq-456',
        'renterId': 'user-1',
        'ownerId': 'user-2',
        'startDate': '2026-09-20T10:00:00.000Z',
        'endDate': '2026-09-25T10:00:00.000Z',
        'totalRentalFee': 750.0,
        'status': 'Approved',
        'pickupVerified': true,
        'returnVerified': false,
      };

      final booking = BookingModel.fromJson(json);

      expect(booking.id, 'book-123');
      expect(booking.equipmentId, 'eq-456');
      expect(booking.renterId, 'user-1');
      expect(booking.ownerId, 'user-2');
      expect(booking.totalRentalFee, 750.0);
      expect(booking.status, 'Approved');
      expect(booking.pickupVerified, isTrue);
      expect(booking.returnVerified, isFalse);
    });

    test('BookingModel serializes to JSON correctly', () {
      final booking = BookingModel(
        id: 'book-999',
        equipmentId: 'eq-99',
        renterId: 'user-renter',
        ownerId: 'user-owner',
        startDate: DateTime.parse('2026-09-20T00:00:00.000Z'),
        endDate: DateTime.parse('2026-09-23T00:00:00.000Z'),
        totalRentalFee: 300.0,
        status: 'Active',
        pickupVerified: true,
        returnVerified: true,
      );

      final json = booking.toJson();

      expect(json['id'], 'book-999');
      expect(json['equipmentId'], 'eq-99');
      expect(json['totalRentalFee'], 300.0);
      expect(json['status'], 'Active');
      expect(json['pickupVerified'], isTrue);
      expect(json['returnVerified'], isTrue);
    });

    test('HandoverTokenModel parses QR token data properly', () {
      final json = {
        'bookingId': 'book-123',
        'token': 'jwt.token.here',
        'eventType': 'Pickup',
        'expiresAtUtc': '2026-09-20T12:00:00.000Z',
        'qrPayload': 'rentatool://handover?token=jwt.token.here',
      };

      final token = HandoverTokenModel.fromJson(json);

      expect(token.bookingId, 'book-123');
      expect(token.token, 'jwt.token.here');
      expect(token.eventType, 'Pickup');
      expect(token.expiresAtUtc, '2026-09-20T12:00:00.000Z');
      expect(token.qrPayload, 'rentatool://handover?token=jwt.token.here');
    });
  });
}
