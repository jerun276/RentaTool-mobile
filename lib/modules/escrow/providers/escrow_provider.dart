import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/damage_claim_model.dart';
import '../models/escrow_hold_model.dart';
import '../services/escrow_service.dart';
import '../../booking/providers/booking_provider.dart';

// ─── Escrow / Claims List State ───────────────────────────────────────────────

class EscrowState {
  final bool isLoading;
  final List<DamageClaimModel> claims;
  final List<EscrowHoldModel> holds;
  final String? errorMessage;

  const EscrowState({
    this.isLoading = false,
    this.claims = const [],
    this.holds = const [],
    this.errorMessage,
  });

  EscrowState copyWith({
    bool? isLoading,
    List<DamageClaimModel>? claims,
    List<EscrowHoldModel>? holds,
    String? errorMessage,
  }) {
    return EscrowState(
      isLoading: isLoading ?? this.isLoading,
      claims: claims ?? this.claims,
      holds: holds ?? this.holds,
      errorMessage: errorMessage,
    );
  }
}

class EscrowNotifier extends Notifier<EscrowState> {
  @override
  EscrowState build() {
    // Fetch claims & holds on init
    Future.microtask(() => fetchClaims());
    return const EscrowState();
  }

  Future<void> fetchClaims() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await ref.read(escrowServiceProvider).getClaims();

      // Fetch escrow holds for active bookings
      final bookingNotifier = ref.read(bookingProvider.notifier);
      await bookingNotifier.fetchActiveBookings();
      final activeList = ref.read(bookingProvider).activeBookings;

      final List<EscrowHoldModel> loadedHolds = [];
      for (final b in activeList) {
        final hold = await ref.read(escrowServiceProvider).getEscrowByBooking(b.id);
        if (hold != null) {
          loadedHolds.add(hold);
        }
      }

      state = state.copyWith(
        isLoading: false,
        claims: items,
        holds: loadedHolds,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapDioError(e),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load claims. Check server connection.',
      );
    }
  }

  Future<void> refreshHolds() async {
    final activeList = ref.read(bookingProvider).activeBookings;
    final List<EscrowHoldModel> loadedHolds = [];
    for (final b in activeList) {
      final hold = await ref.read(escrowServiceProvider).getEscrowByBooking(b.id);
      if (hold != null) {
        loadedHolds.add(hold);
      }
    }
    state = state.copyWith(holds: loadedHolds);
  }
}

final escrowProvider =
    NotifierProvider<EscrowNotifier, EscrowState>(EscrowNotifier.new);

// ─── Pre-Authorize State ─────────────────────────────────────────────────────

class PreAuthorizeState {
  final bool isLoading;
  final EscrowHoldModel? result;
  final String? errorMessage;
  final bool success;

  const PreAuthorizeState({
    this.isLoading = false,
    this.result,
    this.errorMessage,
    this.success = false,
  });

  PreAuthorizeState copyWith({
    bool? isLoading,
    EscrowHoldModel? result,
    String? errorMessage,
    bool? success,
  }) =>
      PreAuthorizeState(
        isLoading: isLoading ?? this.isLoading,
        result: result ?? this.result,
        errorMessage: errorMessage,
        success: success ?? this.success,
      );
}

class PreAuthorizeNotifier extends Notifier<PreAuthorizeState> {
  @override
  PreAuthorizeState build() {
    return const PreAuthorizeState();
  }

  Future<bool> preAuthorize({
    required String bookingId,
    required String renterId,
    required String ownerId,
    required double depositAmount,
    String? paymentMethodToken,
  }) async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    try {
      final result = await ref.read(escrowServiceProvider).preAuthorizeDeposit(
        bookingId: bookingId,
        renterId: renterId,
        ownerId: ownerId,
        depositAmount: depositAmount,
        paymentMethodToken: paymentMethodToken,
      );
      state = state.copyWith(isLoading: false, result: result, success: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _mapDioError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Pre-authorization failed.');
      return false;
    }
  }

  void reset() => state = const PreAuthorizeState();
}

final preAuthorizeProvider =
    NotifierProvider<PreAuthorizeNotifier, PreAuthorizeState>(
        PreAuthorizeNotifier.new);

// ─── Claim Detail State ───────────────────────────────────────────────────────

class ClaimDetailState {
  final bool isLoadingClaim;
  final bool isProcessingAction;
  final DamageClaimModel? claim;
  final PayoutClaimResponse? payoutResult;
  final String? errorMessage;
  final String? actionMessage;
  final bool actionSuccess;

  const ClaimDetailState({
    this.isLoadingClaim = false,
    this.isProcessingAction = false,
    this.claim,
    this.payoutResult,
    this.errorMessage,
    this.actionMessage,
    this.actionSuccess = false,
  });

  ClaimDetailState copyWith({
    bool? isLoadingClaim,
    bool? isProcessingAction,
    DamageClaimModel? claim,
    PayoutClaimResponse? payoutResult,
    String? errorMessage,
    String? actionMessage,
    bool? actionSuccess,
  }) =>
      ClaimDetailState(
        isLoadingClaim: isLoadingClaim ?? this.isLoadingClaim,
        isProcessingAction: isProcessingAction ?? this.isProcessingAction,
        claim: claim ?? this.claim,
        payoutResult: payoutResult ?? this.payoutResult,
        errorMessage: errorMessage,
        actionMessage: actionMessage,
        actionSuccess: actionSuccess ?? this.actionSuccess,
      );
}

class ClaimDetailNotifier
    extends FamilyNotifier<ClaimDetailState, String> {
  @override
  ClaimDetailState build(String arg) {
    Future.microtask(() => fetchClaim());
    return const ClaimDetailState();
  }

  Future<void> fetchClaim() async {
    state = state.copyWith(isLoadingClaim: true, errorMessage: null);
    try {
      final c = await ref.read(escrowServiceProvider).getClaimById(arg);
      state = state.copyWith(isLoadingClaim: false, claim: c);
    } on DioException catch (e) {
      state = state.copyWith(
          isLoadingClaim: false, errorMessage: _mapDioError(e));
    } catch (_) {
      state = state.copyWith(
          isLoadingClaim: false,
          errorMessage: 'Unable to load claim details.');
    }
  }

  /// Decision must be 'Approve', 'Revise', or 'Reject' (backend validates).
  Future<bool> adjudicate({
    required String decision,
    required String adjudicatorId,
    double? revisedDeduction,
    String? notes,
  }) async {
    if (state.isProcessingAction || state.claim == null) return false;
    state = state.copyWith(
        isProcessingAction: true, errorMessage: null, actionMessage: null);
    try {
      final updated = await ref.read(escrowServiceProvider).adjudicateClaim(
        claimId: state.claim!.claimId,
        decision: decision,
        adjudicatorId: adjudicatorId,
        revisedDeduction: revisedDeduction,
        notes: notes,
      );
      state = state.copyWith(
        isProcessingAction: false,
        claim: updated,
        actionMessage: 'Claim $decision successfully.',
        actionSuccess: true,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
          isProcessingAction: false, errorMessage: _mapDioError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
          isProcessingAction: false,
          errorMessage: 'Adjudication could not be completed.');
      return false;
    }
  }

  Future<bool> processPayout() async {
    if (state.isProcessingAction || state.claim == null) return false;
    // Prevent duplicate payout if already settled
    if (state.claim!.status == ClaimStatus.settled) return false;
    state = state.copyWith(
        isProcessingAction: true, errorMessage: null, actionMessage: null);
    try {
      final payout = await ref.read(escrowServiceProvider).processPayout(state.claim!.claimId);
      // Refresh claim to get updated settled status
      final updated = await ref.read(escrowServiceProvider).getClaimById(state.claim!.claimId);
      state = state.copyWith(
        isProcessingAction: false,
        claim: updated,
        payoutResult: payout,
        actionMessage: 'Payout settled. Ref: ${payout.settlementReference}',
        actionSuccess: true,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
          isProcessingAction: false, errorMessage: _mapDioError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
          isProcessingAction: false,
          errorMessage: 'Payout settlement failed.');
      return false;
    }
  }

  void clearMessages() => state = state.copyWith(
      errorMessage: null, actionMessage: null, actionSuccess: false);
}

final claimDetailProvider = NotifierProvider.family<ClaimDetailNotifier,
    ClaimDetailState, String>(ClaimDetailNotifier.new);

// ─── Error mapping helper ─────────────────────────────────────────────────────

String _mapDioError(DioException e) {
  final code = e.response?.statusCode;
  final msg = e.response?.data is Map
      ? (e.response!.data as Map)['error']?.toString()
      : null;
  switch (code) {
    case 400:
      return msg ?? 'Invalid request. Please check the details.';
    case 401:
      return 'Your session has expired. Please log in again.';
    case 403:
      return 'You are not authorised to perform this action.';
    case 404:
      return msg ?? 'The requested resource could not be found.';
    case 409:
      return msg ?? 'This action conflicts with the current state.';
    case 422:
      return msg ?? 'Validation failed. Please review your input.';
    case 429:
      return 'Too many requests. Please wait and try again.';
    case 500:
      return 'Server error. Please try again later.';
    default:
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Check your internet connection.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Unable to connect to the server.';
      }
      return 'An unexpected error occurred. Please try again.';
  }
}

