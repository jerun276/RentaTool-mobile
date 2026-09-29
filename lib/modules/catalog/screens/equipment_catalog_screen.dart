import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/catalog_provider.dart';
import '../widgets/batch_availability_dialog.dart';
import '../widgets/equipment_card.dart';

class EquipmentCatalogScreen extends ConsumerStatefulWidget {
  const EquipmentCatalogScreen({super.key});

  @override
  ConsumerState<EquipmentCatalogScreen> createState() => _EquipmentCatalogScreenState();
}

class _EquipmentCatalogScreenState extends ConsumerState<EquipmentCatalogScreen> {
  final _scrollController = ScrollController();

  final List<String> _categories = [
    'All',
    'Heavy Machinery',
    'Power Tools',
    'Generators & Power',
    'Cleaning Equipment',
  ];

  final List<String> _statusFilters = [
    'All',
    'Available',
    'UnderMaintenance',
    'Rented',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(catalogProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catalogState = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Machinery Catalog'),
        actions: [
          // Fleet Wear & Dispatch Safety Dialog Button
          IconButton(
            icon: const Icon(Icons.verified_user_outlined, size: 22),
            tooltip: 'Verify Fleet Wear & Safety',
            onPressed: () {
              if (catalogState.items.isNotEmpty) {
                BatchAvailabilityDialog.show(context, catalogState.items);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Catalog is loading... please wait.')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            tooltip: 'Add Machinery',
            onPressed: () => context.push('/catalog/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search excavators, rollers, generators...',
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              ),
              onChanged: (val) {
                ref.read(catalogProvider.notifier).setSearchQuery(val);
              },
            ),
          ),

          // Category Chips Bar
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = catalogState.selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? (isDark ? AppColors.primaryLight : AppColors.primaryDark)
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: isDark ? const Color(0x3310B981) : const Color(0x2210B981),
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    checkmarkColor: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                    side: BorderSide(
                      color: isSelected
                          ? (isDark ? AppColors.primaryLight : AppColors.primary)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    onSelected: (_) {
                      ref.read(catalogProvider.notifier).setCategory(category);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Status Filters (All, Available, Under Maintenance)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _statusFilters.map((st) {
                final isSelected = catalogState.selectedStatus == st;
                final label = st == 'UnderMaintenance' ? 'Maintenance' : st;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? (st == 'UnderMaintenance'
                                ? Colors.white
                                : (isDark ? Colors.black : Colors.white))
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: st == 'UnderMaintenance' ? AppColors.wearLockout : AppColors.primary,
                    backgroundColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceLight,
                    onSelected: (val) {
                      if (val) ref.read(catalogProvider.notifier).setStatus(st);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Equipment List Feed
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(catalogProvider.notifier).fetchEquipment(isRefresh: true),
              color: AppColors.primaryLight,
              child: Builder(
                builder: (context) {
                  if (catalogState.isLoading && catalogState.items.isEmpty) {
                    return const LoadingIndicator(message: 'Loading fleet equipment...');
                  }

                  if (catalogState.errorMessage != null && catalogState.items.isEmpty) {
                    return ErrorView(
                      message: catalogState.errorMessage!,
                      onRetry: () => ref.read(catalogProvider.notifier).fetchEquipment(),
                    );
                  }

                  // Filter in-memory by category if "All" is not selected
                  final items = catalogState.selectedCategory == 'All'
                      ? catalogState.items
                      : catalogState.items
                          .where((e) => e.categoryName.toLowerCase() == catalogState.selectedCategory.toLowerCase())
                          .toList();

                  if (items.isEmpty) {
                    return ListView(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(48),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_outlined, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 16),
                              Text(
                                'No matching machinery found',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try clearing filters or publishing a new tool listing.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    key: ValueKey('catalog_list_${isDark ? 'dark' : 'light'}'),
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length + (catalogState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final equipment = items[index];
                      return EquipmentCard(
                        key: ValueKey('${equipment.id}_${isDark ? 'dark' : 'light'}'),
                        equipment: equipment,
                        onTap: () => context.push('/catalog/${equipment.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
