import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/batch_availability_model.dart';
import '../models/category_model.dart';
import '../models/equipment_history_model.dart';
import '../models/equipment_model.dart';
import '../services/catalog_service.dart';

class CatalogState {
  final bool isLoading;
  final bool isRefreshing;
  final List<EquipmentModel> items;
  final String searchQuery;
  final String selectedCategory;
  final String selectedStatus;
  final int page;
  final bool hasMore;
  final String? errorMessage;

  const CatalogState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.items = const [],
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.selectedStatus = 'All',
    this.page = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  CatalogState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    List<EquipmentModel>? items,
    String? searchQuery,
    String? selectedCategory,
    String? selectedStatus,
    int? page,
    bool? hasMore,
    String? errorMessage,
  }) {
    return CatalogState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  final CatalogService _service;

  CatalogNotifier(this._service) : super(const CatalogState()) {
    fetchEquipment();
  }

  Future<void> fetchEquipment({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, errorMessage: null, page: 1, hasMore: true);
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final items = await _service.getEquipment(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        status: state.selectedStatus != 'All' ? state.selectedStatus : null,
        page: 1,
        pageSize: 20,
      );

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        items: items,
        page: 1,
        hasMore: items.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: 'Failed to load equipment catalog. Please check connection.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.page + 1;
    try {
      final newItems = await _service.getEquipment(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        status: state.selectedStatus != 'All' ? state.selectedStatus : null,
        page: nextPage,
        pageSize: 20,
      );

      if (newItems.isEmpty) {
        state = state.copyWith(hasMore: false);
      } else {
        state = state.copyWith(
          items: [...state.items, ...newItems],
          page: nextPage,
          hasMore: newItems.length >= 20,
        );
      }
    } catch (_) {
      // Keep existing items if loadMore fails
    }
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
    fetchEquipment();
  }

  void setCategory(String category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category);
  }

  void setStatus(String status) {
    if (state.selectedStatus == status) return;
    state = state.copyWith(selectedStatus: status);
    fetchEquipment();
  }
}

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  final service = ref.watch(catalogServiceProvider);
  return CatalogNotifier(service);
});

/// Individual Equipment detail provider
final equipmentDetailProvider = FutureProvider.family<EquipmentModel, String>((ref, equipmentId) async {
  final service = ref.watch(catalogServiceProvider);
  return service.getEquipmentById(equipmentId);
});

/// Equipment history and inspection timeline provider
final equipmentHistoryProvider = FutureProvider.family<EquipmentHistoryTimelineModel, String>((ref, equipmentId) async {
  final service = ref.watch(catalogServiceProvider);
  return service.getEquipmentHistory(equipmentId);
});

/// Equipment wear lockout check provider
final batchAvailabilityCheckProvider = FutureProvider.family<BatchAvailabilityResultModel, ({List<String> ids, DateTime start, DateTime end})>((ref, params) async {
  final service = ref.watch(catalogServiceProvider);
  return service.checkBatchAvailability(
    equipmentIds: params.ids,
    desiredStartDate: params.start,
    desiredEndDate: params.end,
  );
});

/// Dynamic categories provider
final categoryListProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final service = ref.watch(catalogServiceProvider);
  return service.getCategories(activeOnly: true);
});
