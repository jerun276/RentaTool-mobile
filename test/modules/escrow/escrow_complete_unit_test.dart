import 'package:flutter_test/flutter_test.dart';
import 'package:rentatool_mobile/modules/escrow/models/damage_claim_model.dart';
import 'package:rentatool_mobile/modules/escrow/models/escrow_hold_model.dart';

void main() {
  group('EscrowStatus', () {
    test('parses supported statuses without case sensitivity', () {
      expect(EscrowStatus.fromString('Held'), EscrowStatus.held);
      expect(EscrowStatus.fromString('DISBURSED'), EscrowStatus.disbursed);
      expect(EscrowStatus.fromString('Refunded'), EscrowStatus.refunded);
      expect(EscrowStatus.fromString('Disputed'), EscrowStatus.disputed);
    });

    test('uses unknown for missing or unrecognized status', () {
      expect(EscrowStatus.fromString(null), EscrowStatus.unknown);
      expect(EscrowStatus.fromString('released'), EscrowStatus.unknown);
      expect(EscrowStatus.unknown.displayLabel, 'Unknown');
    });
  });

  group('EscrowHoldModel', () {
    test('parses API fields and numeric amounts', () {
      final hold = EscrowHoldModel.fromJson({
        'id': 'hold-1',
        'bookingId': 'booking-1',
        'depositAmount': 125.5,
        'preAuthTransactionId': 'tx-1',
        'status': 'Held',
        'heldAtUtc': '2026-10-01T10:00:00Z',
      });

      expect(hold.id, 'hold-1');
      expect(hold.bookingId, 'booking-1');
      expect(hold.depositAmount, 125.5);
      expect(hold.status, EscrowStatus.held);
      expect(hold.heldAtUtc, '2026-10-01T10:00:00Z');
      expect(hold.settledAtUtc, isNull);
    });

    test('supports backend casing and fallback ID key', () {
      final hold = EscrowHoldModel.fromJson({
        'escrowId': 'hold-2',
        'bookingId': 'booking-2',
        'DepositAmount': 75,
        'Status': 'Disputed',
      });

      expect(hold.id, 'hold-2');
      expect(hold.depositAmount, 75.0);
      expect(hold.status, EscrowStatus.disputed);
    });

    test('uses safe defaults for an empty response', () {
      final hold = EscrowHoldModel.fromJson({});

      expect(hold.id, isEmpty);
      expect(hold.depositAmount, 0.0);
      expect(hold.status, EscrowStatus.held);
      expect(hold.rawStatus, 'Held');
    });

    test('serializes all fields while preserving raw status', () {
      const hold = EscrowHoldModel(
        id: 'hold-3',
        bookingId: 'booking-3',
        depositAmount: 80,
        preAuthTransactionId: 'tx-3',
        status: EscrowStatus.unknown,
        rawStatus: 'Released',
        heldAtUtc: 'held-time',
        settledAtUtc: 'settled-time',
      );

      expect(hold.toJson(), {
        'id': 'hold-3',
        'bookingId': 'booking-3',
        'depositAmount': 80.0,
        'preAuthTransactionId': 'tx-3',
        'status': 'Released',
        'heldAtUtc': 'held-time',
        'settledAtUtc': 'settled-time',
      });
    });
  });

  group('ClaimStatus', () {
    test('parses statuses and formats labels', () {
      expect(ClaimStatus.fromString('UnderAIEvaluation'),
          ClaimStatus.underAIEvaluation);
      expect(ClaimStatus.fromString('under_ai_evaluation'),
          ClaimStatus.underAIEvaluation);
      expect(ClaimStatus.fromString('PendingStaffApproval'),
          ClaimStatus.pendingStaffApproval);
      expect(ClaimStatus.pendingStaffApproval.displayLabel, 'Pending Review');
      expect(ClaimStatus.fromString(null), ClaimStatus.unknown);
    });

    test('exposes terminal, adjudication, and payout rules', () {
      expect(ClaimStatus.rejected.isTerminal, isTrue);
      expect(ClaimStatus.settled.isTerminal, isTrue);
      expect(ClaimStatus.approved.isTerminal, isFalse);
      expect(ClaimStatus.filed.canAdjudicate, isTrue);
      expect(ClaimStatus.underAIEvaluation.canAdjudicate, isTrue);
      expect(ClaimStatus.pendingStaffApproval.canAdjudicate, isTrue);
      expect(ClaimStatus.approved.canPayout, isTrue);
      expect(ClaimStatus.revised.canPayout, isTrue);
      expect(ClaimStatus.filed.canPayout, isFalse);
    });
  });

  group('DamageClaimModel', () {
    test('parses claim data, evidence, and deductions', () {
      final claim = DamageClaimModel.fromJson({
        'claimId': 'claim-1',
        'bookingId': 'booking-1',
        'filedByUserId': 'owner-1',
        'damageDescription': 'Cracked casing',
        'evidencePhotos': ['photo-a', 'photo-b'],
        'proposedDeduction': 100,
        'finalDeduction': 80.5,
        'status': 'Approved',
        'adjudicationNotes': 'Adjusted after review',
      });

      expect(claim.claimId, 'claim-1');
      expect(claim.evidencePhotos, ['photo-a', 'photo-b']);
      expect(claim.proposedDeduction, 100.0);
      expect(claim.finalDeduction, 80.5);
      expect(claim.status, ClaimStatus.approved);
    });

    test('supports fallback ID and safe defaults', () {
      final claim = DamageClaimModel.fromJson({'id': 'claim-2'});

      expect(claim.claimId, 'claim-2');
      expect(claim.status, ClaimStatus.filed);
      expect(claim.proposedDeduction, 0.0);
      expect(claim.evidencePhotos, isEmpty);
      expect(claim.finalDeduction, isNull);
    });

    test('serializes the claim API fields', () {
      const claim = DamageClaimModel(
        claimId: 'claim-3',
        bookingId: 'booking-3',
        filedByUserId: 'owner-3',
        damageDescription: 'Bent frame',
        evidencePhotos: ['photo-c'],
        proposedDeduction: 50,
        finalDeduction: 40,
        status: ClaimStatus.revised,
        rawStatus: 'Revised',
        adjudicationNotes: 'Reduced amount',
      );

      expect(claim.toJson(), {
        'claimId': 'claim-3',
        'bookingId': 'booking-3',
        'filedByUserId': 'owner-3',
        'damageDescription': 'Bent frame',
        'evidencePhotos': ['photo-c'],
        'proposedDeduction': 50.0,
        'finalDeduction': 40.0,
        'status': 'Revised',
        'adjudicationNotes': 'Reduced amount',
      });
    });
  });

  group('PayoutClaimResponse', () {
    test('parses the settlement response', () {
      final payout = PayoutClaimResponse.fromJson({
        'claimId': 'claim-4',
        'bookingId': 'booking-4',
        'ownerPayoutAmount': 70,
        'renterRefundAmount': 30.5,
        'status': 'Settled',
        'settlementReference': 'settlement-4',
        'settledAtUtc': '2026-10-01T12:00:00Z',
      });

      expect(payout.ownerPayoutAmount, 70.0);
      expect(payout.renterRefundAmount, 30.5);
      expect(payout.settlementReference, 'settlement-4');
    });

    test('applies safe defaults for an empty response', () {
      final payout = PayoutClaimResponse.fromJson({});

      expect(payout.claimId, isEmpty);
      expect(payout.ownerPayoutAmount, 0.0);
      expect(payout.renterRefundAmount, 0.0);
      expect(payout.status, 'Settled');
    });
  });
}
