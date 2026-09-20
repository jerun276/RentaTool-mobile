import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/catalog_provider.dart';
import '../widgets/equipment_card.dart';

class EquipmentCatalogScreen extends ConsumerWidget {
  const EquipmentCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogProvider);
    final categories = ['All', 'Heavy Machinery', 'Power Tools', 'Cleaning Equipment', 'Generators & Power'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            tooltip: 'Add Equipment',
            onPressed: () => context.push('/catalog/add'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: () => ref.read(catalogProvider.notifier).fetchEquipment(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search excavators, rollers, drills...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppColors.surface,
              ),
              onChanged: (val) {
                ref.read(catalogProvider.notifier).setSearchQuery(val);
              },
            ),
          ),

          // Category Chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = catalogState.selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    backgroundColor: AppColors.surface,
                    checkmarkColor: AppColors.primaryLight,
                    onSelected: (selected) {
                      ref.read(catalogProvider.notifier).setCategory(category);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Equipment List
          Expanded(
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

                final filteredItems = catalogState.selectedCategory == 'All'
                    ? catalogState.items
                    : catalogState.items
                        .where((e) => e.categoryName.toLowerCase() == catalogState.selectedCategory.toLowerCase())
                        .toList();

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No equipment found matching criteria.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primaryLight,
                  backgroundColor: AppColors.surface,
                  onRefresh: () => ref.read(catalogProvider.notifier).fetchEquipment(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return EquipmentCard(
                        equipment: item,
                        onTap: () => context.push('/catalog/detail/${item.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
