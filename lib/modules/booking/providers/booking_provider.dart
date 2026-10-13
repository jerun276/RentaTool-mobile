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

  static int _statusRank(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return 0; // needs owner action - show first
      case 'confirmed':
        return 1;
      case 'active':
        return 2;
      case 'disputed':
        return 3;
      case 'completed':
        return 4;
      case 'cancelled':
        return 5;
      default:
        return 6;
    }
  }

  /// Computed list based on active filter chip and search query,
  /// ordered by status priority (Requested first) then newest first.
  List<BookingModel> get filteredBookings {
    final list = activeBookings.where((b) {
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

    list.sort((a, b) {
      final byStatus = _statusRank(a.status).compareTo(_statusRank(b.status));
      if (byStatus != 0) return byStatus;
      final aCreated = DateTime.tryParse(a.createdAtUtc ?? '') ?? a.startDate;
      final bCreated = DateTime.tryParse(b.createdAtUtc ?? '') ?? b.startDate;
      return bCreated.compareTo(aCreated);
    });
    return list;
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
