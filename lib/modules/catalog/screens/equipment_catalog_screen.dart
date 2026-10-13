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
import '../../identity/providers/auth_provider.dart';
import '../../identity/models/user_model.dart';

class EquipmentCatalogScreen extends ConsumerStatefulWidget {
  const EquipmentCatalogScreen({super.key});

  @override
  ConsumerState<EquipmentCatalogScreen> createState() => _EquipmentCatalogScreenState();
}

class _EquipmentCatalogScreenState extends ConsumerState<EquipmentCatalogScreen> {
  final _scrollController = ScrollController();

  static const List<String> _defaultCategories = [
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
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isOwnerOrAdmin = currentUser?.role == UserRole.owner || currentUser?.role == UserRole.admin;
    final isRenter = currentUser?.role == UserRole.renter;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnerOrAdmin ? 'Fleet Machinery Catalog' : 'Rent Machinery & Tools'),
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
          if (currentUser?.role == UserRole.owner)
            IconButton(
              icon: const Icon(Icons.precision_manufacturing_outlined, size: 22),
              tooltip: 'My Fleet Machineries',
              onPressed: () => context.push('/catalog/my-fleet'),
            ),
          if (isOwnerOrAdmin)
            IconButton(
              icon: const Icon(Icons.add, size: 22),
              tooltip: 'Add Machinery',
              onPressed: () => context.push('/catalog/add'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Modern Search Bar with Integrated Filter Trigger
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search excavators, tools, fleet...',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (val) {
                        ref.read(catalogProvider.notifier).setSearchQuery(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showFilterBottomSheet(context, catalogState),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: catalogState.selectedStatus != 'All'
                            ? (isDark ? AppColors.primary.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.12))
                            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: catalogState.selectedStatus != 'All'
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: catalogState.selectedStatus != 'All' ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: catalogState.selectedStatus != 'All'
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: catalogState.selectedStatus != 'All'
                                ? AppColors.primary
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                          if (catalogState.selectedStatus != 'All')
                            Positioned(
                              top: 9,
                              right: 9,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Owner Fleet Management Quick Access Banner
          if (currentUser?.role == UserRole.owner)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: InkWell(
                onTap: () => context.push('/catalog/my-fleet'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.precision_manufacturing_outlined,
                        size: 20,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fleet Owner Hub',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'Tap to view your listed units, wear gauges & dispatch logs',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Renter KYC Verification Alert Banner (if unverified)
          if (isRenter && !(currentUser?.isVerified ?? false))
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x22F59E0B) : const Color(0x15F59E0B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NIC Identity Verification Required',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Submit your NIC to reserve equipment and initiate escrow deposits.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.push('/kyc-submit'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFFF59E0B),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Verify Now'),
                  ),
                ],
              ),
            ),

          // Modern Category Carousel (Replaces dual stacked filter chips)
          Builder(
            builder: (context) {
              final categoriesAsync = ref.watch(categoryListProvider);
              final dynamicCategories = categoriesAsync.valueOrNull;
              final categoriesList = (dynamicCategories != null && dynamicCategories.isNotEmpty)
                  ? ['All', ...dynamicCategories.map((c) => c.name)]
                  : _defaultCategories;

              return SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categoriesList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categoriesList[index];
                    final isSelected = catalogState.selectedCategory == category;
                    final iconData = _getCategoryIcon(category);

                    return InkWell(
                      onTap: () {
                        ref.read(catalogProvider.notifier).setCategory(category);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              iconData,
                              size: 15,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Active Status Filter Pill (Shown only when non-default filter is applied)
          if (catalogState.selectedStatus != 'All') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catalogState.selectedStatus == 'UnderMaintenance'
                          ? (isDark ? const Color(0x33EF4444) : const Color(0x15EF4444))
                          : (isDark ? const Color(0x3310B981) : const Color(0x1510B981)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: catalogState.selectedStatus == 'UnderMaintenance'
                            ? const Color(0xFFEF4444)
                            : AppColors.primary,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          catalogState.selectedStatus == 'UnderMaintenance'
                              ? Icons.build_circle_outlined
                              : Icons.check_circle_outline,
                          size: 13,
                          color: catalogState.selectedStatus == 'UnderMaintenance'
                              ? const Color(0xFFEF4444)
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Filter: ${catalogState.selectedStatus == 'UnderMaintenance' ? 'Under Maintenance' : catalogState.selectedStatus}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: catalogState.selectedStatus == 'UnderMaintenance'
                                ? const Color(0xFFEF4444)
                                : (isDark ? AppColors.primaryLight : AppColors.primaryDark),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => ref.read(catalogProvider.notifier).setStatus('All'),
                          borderRadius: BorderRadius.circular(12),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: catalogState.selectedStatus == 'UnderMaintenance'
                                ? const Color(0xFFEF4444)
                                : (isDark ? AppColors.primaryLight : AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(catalogProvider.notifier).setStatus('All');
                      ref.read(catalogProvider.notifier).setCategory('All');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Reset All', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'heavy machinery':
        return Icons.precision_manufacturing_rounded;
      case 'power tools':
        return Icons.handyman_rounded;
      case 'generators & power':
        return Icons.bolt_rounded;
      case 'cleaning equipment':
        return Icons.cleaning_services_rounded;
      case 'all':
        return Icons.grid_view_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _showFilterBottomSheet(BuildContext context, CatalogState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final currentStatus = state.selectedStatus;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Fleet Machinery',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (currentStatus != 'All' || state.selectedCategory != 'All')
                      TextButton(
                        onPressed: () {
                          ref.read(catalogProvider.notifier).setStatus('All');
                          ref.read(catalogProvider.notifier).setCategory('All');
                          Navigator.pop(ctx);
                        },
                        child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Select equipment availability and operational status',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 18),

                // Status Options List
                ..._statusFilters.map((st) {
                  final isSelected = currentStatus == st;
                  String title;
                  String subtitle;
                  IconData icon;
                  Color accentColor;

                  switch (st) {
                    case 'Available':
                      title = 'Available for Rent';
                      subtitle = 'Ready for immediate dispatch and job-site reservations';
                      icon = Icons.check_circle_outline_rounded;
                      accentColor = const Color(0xFF10B981);
                      break;
                    case 'UnderMaintenance':
                      title = 'Under Maintenance';
                      subtitle = 'Equipment undergoing scheduled wear service or lockout';
                      icon = Icons.build_circle_outlined;
                      accentColor = const Color(0xFFEF4444);
                      break;
                    case 'Rented':
                      title = 'Currently Rented';
                      subtitle = 'Machinery currently deployed on active contractor sites';
                      icon = Icons.timelapse_rounded;
                      accentColor = const Color(0xFFF59E0B);
                      break;
                    default:
                      title = 'All Machinery';
                      subtitle = 'Show all equipment across the entire Sri Lanka fleet';
                      icon = Icons.apps_rounded;
                      accentColor = AppColors.primary;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () {
                        ref.read(catalogProvider.notifier).setStatus(st);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: isDark ? 0.2 : 0.1)
                              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? accentColor
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, color: accentColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_rounded, color: accentColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
