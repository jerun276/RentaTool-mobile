import 'package:flutter_test/flutter_test.dart';
import 'package:rentatool_mobile/modules/escrow/models/escrow_hold_model.dart';
import 'package:rentatool_mobile/modules/escrow/models/damage_claim_model.dart';

void main() {
  group('Escrow Module - Component 4 Unit Tests', () {
    test('EscrowHoldModel parses correctly from JSON', () {
      final json = {
        'id': 'hold-999',
        'bookingId': 'book-123',
        'depositAmount': 350.0,
        'preAuthTransactionId': 'stripe_ch_34892019',
        'status': 'Held',
        'heldAtUtc': '2026-09-20T08:00:00.000Z',
        'settledAtUtc': null,
      };

      final hold = EscrowHoldModel.fromJson(json);

      expect(hold.id, 'hold-999');
      expect(hold.bookingId, 'book-123');
      expect(hold.depositAmount, 350.0);
      expect(hold.preAuthTransactionId, 'stripe_ch_34892019');
      expect(hold.status, EscrowStatus.held);
      expect(hold.rawStatus, 'Held');
      expect(hold.heldAtUtc, '2026-09-20T08:00:00.000Z');
      expect(hold.settledAtUtc, isNull);
    });

    test('EscrowHoldModel serializes to JSON accurately', () {
      const hold = EscrowHoldModel(
        id: 'hold-111',
        bookingId: 'book-222',
        depositAmount: 500.0,
        preAuthTransactionId: 'tx-stripe-test',
        status: EscrowStatus.disbursed,
        status: EscrowStatus.refunded,
        rawStatus: 'Released',
      );

      final json = hold.toJson();

      expect(json['id'], 'hold-111');
      expect(json['depositAmount'], 500.0);
      expect(json['status'], 'Released');
    });

    test('DamageClaimModel parses correctly from JSON', () {
      final json = {
        'claimId': 'claim-001',
        'bookingId': 'book-123',
        'filedByUserId': 'user-owner',
        'damageDescription': 'Cracked outer motor chassis and missing safety cap.',
        'evidencePhotos': [
          'https://example.com/dmg1.jpg',
          'https://example.com/dmg2.jpg'
        ],
        'proposedDeduction': 150.0,
        'finalDeduction': null,
        'status': 'UnderAIEvaluation',
        'adjudicationNotes': null,
        'createdAtUtc': '2026-09-20T14:30:00.000Z',
      };

      final claim = DamageClaimModel.fromJson(json);

      expect(claim.claimId, 'claim-001');
      expect(claim.bookingId, 'book-123');
      expect(claim.proposedDeduction, 150.0);
      expect(claim.evidencePhotos.length, 2);
      expect(claim.status, ClaimStatus.underAIEvaluation);
      expect(claim.rawStatus, 'UnderAIEvaluation');
      expect(claim.finalDeduction, isNull);
    });

    test('DamageClaimModel serializes to JSON correctly', () {
      const claim = DamageClaimModel(
        claimId: 'claim-002',
        bookingId: 'book-456',
        filedByUserId: 'user-77',
        damageDescription: 'Scratch on blade',
        evidencePhotos: ['https://example.com/scratch.png'],
        proposedDeduction: 75.0,
        finalDeduction: 60.0,
        status: ClaimStatus.approved,
        rawStatus: 'Approved',
        adjudicationNotes: 'Reduced deduction based on prior inspection log.',
      );

      final json = claim.toJson();

      expect(json['claimId'], 'claim-002');
      expect(json['proposedDeduction'], 75.0);
      expect(json['finalDeduction'], 60.0);
      expect(json['status'], 'Approved');
      expect(json['adjudicationNotes'], contains('Reduced deduction'));
    });
  });
}
