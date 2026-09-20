import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/damage_claim_model.dart';
import '../services/escrow_service.dart';

class EscrowState {
  final bool isLoading;
  final List<DamageClaimModel> claims;
  final String? errorMessage;

  const EscrowState({
    this.isLoading = false,
    this.claims = const [],
    this.errorMessage,
  });

  EscrowState copyWith({
    bool? isLoading,
    List<DamageClaimModel>? claims,
    String? errorMessage,
  }) {
    return EscrowState(
      isLoading: isLoading ?? this.isLoading,
      claims: claims ?? this.claims,
      errorMessage: errorMessage,
    );
  }
}

class EscrowNotifier extends StateNotifier<EscrowState> {
  final EscrowService _service;

  EscrowNotifier(this._service) : super(const EscrowState()) {
    fetchClaims();
  }

  Future<void> fetchClaims() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _service.getClaims();
      state = state.copyWith(isLoading: false, claims: items);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load damage disputes. Check server connection.',
      );
    }
  }
}

final escrowProvider = StateNotifierProvider<EscrowNotifier, EscrowState>((ref) {
  final service = ref.watch(escrowServiceProvider);
  return EscrowNotifier(service);
});
