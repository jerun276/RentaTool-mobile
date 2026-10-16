import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Fetches authoritative escrow hold status for a specific booking from backend.
  Future<EscrowHoldModel?> getEscrowByBooking(String bookingId) async {
    try {
      final res = await _dio.get(
        '/escrow/booking/$bookingId',
        options: Options(validateStatus: (status) => status != null && status < 500),
      );
      if (res.statusCode == 200 && res.data != null && res.data is Map<String, dynamic>) {
        return EscrowHoldModel.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('getEscrowByBooking notice: $e');
    }
    return null;
  }

  /// Pre-authorizes and locks security deposit funds via gateway in backend.
  Future<EscrowHoldModel> preAuthorizeDeposit({
    required String bookingId,
    required String renterId,
    required String ownerId,
    required double depositAmount,
    String? paymentMethodToken,
  }) async {
    try {
      final res = await _dio.post('/escrow/pre-authorize', data: {
        'bookingId': bookingId,
        'renterId': renterId,
        'ownerId': ownerId,
        'depositAmount': depositAmount > 0 ? depositAmount : 15000.0,
        'paymentMethodToken': paymentMethodToken ?? 'GATEWAY-CARD-TEST',
      });
      if (res.data != null && res.data is Map<String, dynamic>) {
        return EscrowHoldModel.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Pre-authorization returned invalid response format.');
    } on DioException {
      rethrow;
    } catch (e) {
      debugPrint('preAuthorizeDeposit backend error: $e');
      rethrow;
    }
  }

  /// Retrieves all damage claims from authoritative backend.
  Future<List<DamageClaimModel>> getClaims() async {
    try {
      final res = await _dio.get('/claims');
      if (res.data != null && res.data is List) {
        return (res.data as List)
            .map((c) => DamageClaimModel.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      debugPrint('getClaims backend error: $e');
      rethrow;
    } catch (e) {
      debugPrint('getClaims notice: $e');
      return const [];
    }
  }

  /// Retrieves a specific damage claim with AI telemetry.
  Future<DamageClaimModel> getClaimById(String id) async {
    try {
      final res = await _dio.get('/claims/$id');
      if (res.data != null && res.data is Map<String, dynamic>) {
        return DamageClaimModel.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Claim not found.');
    } on DioException {
      rethrow;
    } catch (e) {
      debugPrint('getClaimById backend error: $e');
      rethrow;
    }
  }

  /// Files a photographic damage claim upon tool return.
  Future<DamageClaimModel> fileClaim({
    required String bookingId,
    required String filedByUserId,
    required String damageDescription,
    List<String> evidencePhotos = const [],
    double? claimAmount,
  }) async {
    try {
      final res = await _dio.post('/claims', data: {
        'bookingId': bookingId,
        'filedByUserId': filedByUserId,
        'damageDescription': damageDescription,
        'evidencePhotos': evidencePhotos,
        if (claimAmount != null && claimAmount > 0) 'claimAmount': claimAmount,
      });
      if (res.data != null && res.data is Map<String, dynamic>) {
        return DamageClaimModel.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Failed to file claim.');
    } on DioException {
      rethrow;
    } catch (e) {
      debugPrint('fileClaim backend notice: $e');
      rethrow;
    }
  }

  /// Adjudicates a claim via staff decision.
  Future<DamageClaimModel> adjudicateClaim({
    required String claimId,
    required String decision,
    double? revisedDeduction,
    required String adjudicatorId,
    String? notes,
  }) async {
    try {
      final res = await _dio.post('/claims/$claimId/adjudicate', data: {
        'decision': decision,
        'revisedDeduction': revisedDeduction,
        'adjudicatorId': adjudicatorId,
        'notes': notes,
      });
      if (res.data != null && res.data is Map<String, dynamic>) {
        return DamageClaimModel.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Failed to adjudicate claim.');
    } on DioException {
      rethrow;
    } catch (e) {
      debugPrint('adjudicateClaim backend notice: $e');
      rethrow;
    }
  }

  /// Disburses final settlement payments.
  Future<PayoutClaimResponse> processPayout(String claimId) async {
    try {
      final res = await _dio.post('/claims/$claimId/payout');
      if (res.data != null && res.data is Map<String, dynamic>) {
        return PayoutClaimResponse.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Failed to process payout.');
    } on DioException {
      rethrow;
    } catch (e) {
      debugPrint('processPayout backend notice: $e');
      rethrow;
    }
  }
}
