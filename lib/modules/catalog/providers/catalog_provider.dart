import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equipment_model.dart';
import '../services/catalog_service.dart';

class CatalogState {
  final bool isLoading;
  final List<EquipmentModel> items;
  final String searchQuery;
  final String selectedCategory;
  final String? errorMessage;

  const CatalogState({
    this.isLoading = false,
    this.items = const [],
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.errorMessage,
  });

  CatalogState copyWith({
    bool? isLoading,
    List<EquipmentModel>? items,
    String? searchQuery,
    String? selectedCategory,
    String? errorMessage,
  }) {
    return CatalogState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorMessage: errorMessage,
    );
  }
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  final CatalogService _service;

  CatalogNotifier(this._service) : super(const CatalogState()) {
    fetchEquipment();
  }

  Future<void> fetchEquipment() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _service.getEquipment(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load equipment catalog. Check server connection.',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    fetchEquipment();
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }
}

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  final service = ref.watch(catalogServiceProvider);
  return CatalogNotifier(service);
});
