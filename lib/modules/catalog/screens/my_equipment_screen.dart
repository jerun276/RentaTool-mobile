import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../../identity/providers/auth_provider.dart';
import '../models/equipment_model.dart';
import '../providers/catalog_provider.dart';
import '../widgets/wear_progress_bar.dart';

/// Screen allowing equipment owners to monitor and manage their machinery fleet.
class MyEquipmentScreen extends ConsumerStatefulWidget {
  const MyEquipmentScreen({super.key});

  @override
  ConsumerState<MyEquipmentScreen> createState() => _MyEquipmentScreenState();
}

class _MyEquipmentScreenState extends ConsumerState<MyEquipmentScreen> {
  String _selectedStatusFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogProvider.notifier).fetchEquipment();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final catalogState = ref.watch(catalogProvider);
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    // Filter items owned by the logged-in owner
    final myEquipment = catalogState.items.where((e) {
      if (currentUser == null) return false;
      return e.ownerId.toLowerCase() == currentUser.id.toLowerCase();
    }).toList();

    // Secondary filtering by status & search
    final filtered = myEquipment.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.categoryName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.location.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatusFilter == 'All' ||
          (_selectedStatusFilter == 'Available' && e.status == 'Available' && !e.isWearLocked) ||
          (_selectedStatusFilter == 'Rented' && e.status == 'Rented') ||
          (_selectedStatusFilter == 'Maintenance' && e.isWearLocked);

      return matchesSearch && matchesStatus;
    }).toList();

    // Statistics
    final totalUnits = myEquipment.length;
    final availableUnits = myEquipment.where((e) => e.status == 'Available' && !e.isWearLocked).length;
    final rentedUnits = myEquipment.where((e) => e.status == 'Rented').length;
    final maintenanceUnits = myEquipment.where((e) => e.isWearLocked).length;

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_LK',
      symbol: 'LKR ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Machinery Fleet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 24),
            tooltip: 'Add Machinery',
            onPressed: () => context.push('/catalog/add'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh Fleet',
            onPressed: () => ref.read(catalogProvider.notifier).fetchEquipment(isRefresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(catalogProvider.notifier).fetchEquipment(isRefresh: true);
        },
        child: catalogState.isLoading && catalogState.items.isEmpty
            ? const Center(child: LoadingIndicator(message: 'Loading your fleet...'))
            : catalogState.errorMessage != null && catalogState.items.isEmpty
                ? Center(
                    child: ErrorView(
                      message: catalogState.errorMessage!,
                      onRetry: () => ref.read(catalogProvider.notifier).fetchEquipment(isRefresh: true),
                    ),
                  )
                : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Header Stats Panel
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // KPI Cards Grid
                              Row(
                                children: [
                                  _buildStatCard(
                                    label: 'TOTAL UNITS',
                                    value: '$totalUnits',
                                    color: AppColors.primaryLight,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatCard(
                                    label: 'AVAILABLE',
                                    value: '$availableUnits',
                                    color: AppColors.success,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatCard(
                                    label: 'ON RENTAL',
                                    value: '$rentedUnits',
                                    color: const Color(0xFF3B82F6),
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatCard(
                                    label: 'LOCKOUT',
                                    value: '$maintenanceUnits',
                                    color: AppColors.warning,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Search Bar
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(color: textPrimary, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Search my machinery by title or category...',
                                    hintStyle: TextStyle(
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      fontSize: 12,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      size: 18,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 16),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  onChanged: (val) {
                                    setState(() => _searchQuery = val.trim());
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Status Filter Chips
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip('All', isDark),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('Available', isDark),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('Rented', isDark),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('Maintenance', isDark),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Fleet List or Empty State
                      if (myEquipment.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.precision_manufacturing_outlined,
                                      size: 56,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No Machinery Listed Yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Publish your excavators, generators, or power tools to start earning rental yields across Sri Lanka.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  AppButton(
                                    text: 'List New Machinery',
                                    icon: Icons.add,
                                    onPressed: () => context.push('/catalog/add'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (filtered.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.search_off, size: 40, color: AppColors.textMuted),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No machinery matched "$_searchQuery"',
                                    style: TextStyle(color: textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = filtered[index];
                                return _buildOwnerEquipmentCard(
                                  context: context,
                                  equipment: item,
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  currencyFormatter: currencyFormatter,
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String status, bool isDark) {
    final isSelected = _selectedStatusFilter == status;
    return ChoiceChip(
      label: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkSurfaceLight : const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(
        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedStatusFilter = status);
      },
    );
  }

  Widget _buildOwnerEquipmentCard({
    required BuildContext context,
    required EquipmentModel equipment,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required NumberFormat currencyFormatter,
  }) {
    final isLocked = equipment.isWearLocked;
    final primaryImg = equipment.primaryImageUrl;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLocked
              ? AppColors.warning.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/catalog/detail/${equipment.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Preview & Badges
            Container(
              height: 130,
              width: double.infinity,
              color: isDark ? AppColors.darkSurfaceLight : const Color(0xFFE2E8F0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (primaryImg.isNotEmpty)
                    Image.network(
                      primaryImg,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackPlaceholder(),
                    )
                  else
                    _fallbackPlaceholder(),
                  // Top Status Badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: StatusBadge(
                      label: isLocked
                          ? (equipment.isWearLimitReached ? 'LOCKOUT (60D+)' : 'MAINTENANCE')
                          : equipment.status,
                      style: isLocked ? BadgeStyle.error : BadgeStyle.success,
                    ),
                  ),
                  // Category Pill
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xCC000000),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        equipment.categoryName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          equipment.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.primaryLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          equipment.location,
                          style: TextStyle(fontSize: 12, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Pricing row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DAILY RATE', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                          Text(
                            currencyFormatter.format(equipment.dailyRate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('DEPOSIT VALUE', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                          Text(
                            currencyFormatter.format(equipment.replacementValue),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 60-Day Wear Progress Bar
                  WearProgressBar(daysAccumulated: equipment.totalRentalDaysAccumulated),
                  const SizedBox(height: 14),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.history, size: 15),
                          label: const Text('History'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => context.push('/catalog/history/${equipment.id}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.fact_check_outlined, size: 15),
                          label: const Text('Inspect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => context.push('/catalog/inspection/${equipment.id}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.precision_manufacturing_outlined, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 4),
          Text('No Image', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
