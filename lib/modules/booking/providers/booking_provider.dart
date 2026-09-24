import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingState {
  final bool isLoading;
  final List<BookingModel> activeBookings;
  final String selectedFilter;
  final String searchQuery;
  final String? errorMessage;

  const BookingState({
    this.isLoading = false,
    this.activeBookings = const [],
    this.selectedFilter = 'All',
    this.searchQuery = '',
    this.errorMessage,
  });

  /// Computed list based on active filter chip and search query
  List<BookingModel> get filteredBookings {
    return activeBookings.where((b) {
      // 1. Status Filter
      if (selectedFilter != 'All') {
        if (b.status.toLowerCase() != selectedFilter.toLowerCase()) {
          return false;
        }
      }

      // 2. Search Query filter (by ID, displayCode, or equipmentId)
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matchesId = b.id.toLowerCase().contains(q);
        final matchesCode = b.displayCode.toLowerCase().contains(q);
        final matchesEq = b.equipmentId.toLowerCase().contains(q);
        return matchesId || matchesCode || matchesEq;
      }

      return true;
    }).toList();
  }

  BookingState copyWith({
    bool? isLoading,
    List<BookingModel>? activeBookings,
    String? selectedFilter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      activeBookings: activeBookings ?? this.activeBookings,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
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
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  final service = ref.watch(bookingServiceProvider);
  return BookingNotifier(service);
});
