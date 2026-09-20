import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingState {
  final bool isLoading;
  final List<BookingModel> activeBookings;
  final String? errorMessage;

  const BookingState({
    this.isLoading = false,
    this.activeBookings = const [],
    this.errorMessage,
  });

  BookingState copyWith({
    bool? isLoading,
    List<BookingModel>? activeBookings,
    String? errorMessage,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      activeBookings: activeBookings ?? this.activeBookings,
      errorMessage: errorMessage,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final BookingService _service;

  BookingNotifier(this._service) : super(const BookingState()) {
    fetchActiveBookings();
  }

  Future<void> fetchActiveBookings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _service.getActiveBookings();
      state = state.copyWith(isLoading: false, activeBookings: items);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load bookings. Check server connection.',
      );
    }
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  final service = ref.watch(bookingServiceProvider);
  return BookingNotifier(service);
});
