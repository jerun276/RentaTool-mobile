import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/escrow_hold_model.dart';
import '../models/damage_claim_model.dart';

final escrowServiceProvider = Provider<EscrowService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return EscrowService(dio);
});

class EscrowService {
  final Dio _dio;

  EscrowService(this._dio);

  Future<EscrowHoldModel?> getEscrowByBooking(String bookingId) async {
    try {
      final response = await _dio.get(ApiConstants.escrowByBooking(bookingId));
      return EscrowHoldModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<EscrowHoldModel> preAuthorizeDeposit({
    required String bookingId,
    required double depositAmount,
    required String paymentMethodId,
  }) async {
    final response = await _dio.post(
      ApiConstants.escrowPreAuthorize,
      data: {
        'bookingId': bookingId,
        'depositAmount': depositAmount,
        'paymentMethodId': paymentMethodId,
      },
    );
    return EscrowHoldModel.fromJson(response.data);
  }

  Future<List<DamageClaimModel>> getClaims() async {
    final response = await _dio.get(ApiConstants.claims);
    final List<dynamic> items = response.data is List ? response.data : [];
    return items.map((e) => DamageClaimModel.fromJson(e)).toList();
  }

  Future<DamageClaimModel> getClaimById(String id) async {
    final response = await _dio.get(ApiConstants.claimById(id));
    return DamageClaimModel.fromJson(response.data);
  }

  Future<DamageClaimModel> fileClaim({
    required String bookingId,
    required String damageDescription,
    required double proposedDeduction,
    List<String> evidencePhotos = const [],
  }) async {
    final response = await _dio.post(
      ApiConstants.claims,
      data: {
        'bookingId': bookingId,
        'damageDescription': damageDescription,
        'proposedDeduction': proposedDeduction,
        'evidencePhotos': evidencePhotos,
      },
    );
    return DamageClaimModel.fromJson(response.data);
  }

  Future<DamageClaimModel> adjudicateClaim({
    required String claimId,
    required String decision, // 'Approved', 'Revised', 'Rejected'
    double? revisedDeduction,
    String? adjudicationNotes,
  }) async {
    final response = await _dio.post(
      ApiConstants.claimAdjudicate(claimId),
      data: {
        'decision': decision,
        if (revisedDeduction != null) 'revisedDeduction': revisedDeduction,
        if (adjudicationNotes != null) 'adjudicationNotes': adjudicationNotes,
      },
    );
    return DamageClaimModel.fromJson(response.data);
  }

  Future<bool> processPayout(String claimId) async {
    final response = await _dio.post(ApiConstants.claimPayout(claimId));
    return response.statusCode == 200;
  }
}
