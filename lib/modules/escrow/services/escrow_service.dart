import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/escrow_hold_model.dart';
import '../models/damage_claim_model.dart';

final escrowServiceProvider = Provider<EscrowService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return EscrowService(dio);
});

class EscrowService {
  // ignore: unused_field
  final Dio _dio;

  EscrowService(this._dio);

  static final List<DamageClaimModel> _mockClaims = [
    const DamageClaimModel(
      claimId: 'c_999001',
      bookingId: '33333333-3333-3333-3333-333333333301',
      filedByUserId: 'u_777',
      damageDescription: 'Initial mock claim for testing UI.',
      proposedDeduction: 150.0,
      status: ClaimStatus.filed,
      rawStatus: 'Filed',
    )
  ];

  Future<EscrowHoldModel?> getEscrowByBooking(String bookingId) async {
    await Future.delayed(const Duration(seconds: 1));
    return EscrowHoldModel(
      id: 'e_123',
      bookingId: bookingId,
      depositAmount: 500.0,
      preAuthTransactionId: 'txn_999',
      status: EscrowStatus.held,
      rawStatus: 'Held',
    );
  }

  Future<EscrowHoldModel> preAuthorizeDeposit({
    required String bookingId,
    required String renterId,
    required String ownerId,
    required double depositAmount,
    String? paymentMethodToken,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return EscrowHoldModel(
      id: 'e_123',
      bookingId: bookingId,
      depositAmount: depositAmount,
      preAuthTransactionId: 'txn_999',
      status: EscrowStatus.held,
      rawStatus: 'Held',
    );
  }

  Future<List<DamageClaimModel>> getClaims() async {
    await Future.delayed(const Duration(seconds: 1));
    return [..._mockClaims];
  }

  Future<DamageClaimModel> getClaimById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockClaims.firstWhere((c) => c.claimId == id);
  }

  Future<DamageClaimModel> fileClaim({
    required String bookingId,
    required String filedByUserId,
    required String damageDescription,
    List<String> evidencePhotos = const [],
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final newClaim = DamageClaimModel(
      claimId: 'c_${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      filedByUserId: filedByUserId,
      damageDescription: damageDescription,
      proposedDeduction: 0.0,
      evidencePhotos: evidencePhotos,
      status: ClaimStatus.underAIEvaluation,
      rawStatus: 'UnderAIEvaluation',
    );
    _mockClaims.add(newClaim);
    return newClaim;
  }

  Future<DamageClaimModel> adjudicateClaim({
    required String claimId,
    required String decision,
    double? revisedDeduction,
    required String adjudicatorId,
    String? notes,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final index = _mockClaims.indexWhere((c) => c.claimId == claimId);
    if (index == -1) throw Exception('Claim not found');
    
    final old = _mockClaims[index];
    final status = decision == 'Approve' ? ClaimStatus.approved : (decision == 'Reject' ? ClaimStatus.rejected : ClaimStatus.revised);
    
    final updated = DamageClaimModel(
      claimId: old.claimId,
      bookingId: old.bookingId,
      filedByUserId: old.filedByUserId,
      damageDescription: old.damageDescription,
      evidencePhotos: old.evidencePhotos,
      proposedDeduction: old.proposedDeduction,
      finalDeduction: revisedDeduction ?? old.proposedDeduction,
      status: status,
      rawStatus: status.name,
      adjudicationNotes: notes,
      adjudicatedByUserId: adjudicatorId,
      adjudicatedAtUtc: DateTime.now().toIso8601String(),
    );
    _mockClaims[index] = updated;
    return updated;
  }

  Future<PayoutClaimResponse> processPayout(String claimId) async {
    await Future.delayed(const Duration(seconds: 1));
    final index = _mockClaims.indexWhere((c) => c.claimId == claimId);
    if (index != -1) {
      final old = _mockClaims[index];
      _mockClaims[index] = DamageClaimModel(
        claimId: old.claimId,
        bookingId: old.bookingId,
        filedByUserId: old.filedByUserId,
        damageDescription: old.damageDescription,
        proposedDeduction: old.proposedDeduction,
        finalDeduction: old.finalDeduction,
        status: ClaimStatus.settled,
        rawStatus: 'Settled',
      );
    }
    return PayoutClaimResponse(
      claimId: claimId,
      bookingId: 'mock_booking',
      ownerPayoutAmount: 150.0,
      renterRefundAmount: 350.0,
      status: 'Settled',
      settlementReference: 'SET-${DateTime.now().millisecondsSinceEpoch}',
      settledAtUtc: DateTime.now().toIso8601String(),
    );
  }
}

