import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_card.dart';
import '../../identity/providers/auth_provider.dart';
import '../../identity/models/user_model.dart';

class ActiveBookingsScreen extends ConsumerStatefulWidget {
  const ActiveBookingsScreen({super.key});

  @override
  ConsumerState<ActiveBookingsScreen> createState() => _ActiveBookingsScreenState();
}

class _ActiveBookingsScreenState extends ConsumerState<ActiveBookingsScreen> {
  final _searchController = TextEditingController();

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
    final bookingState = ref.watch(bookingProvider);
    final notifier = ref.read(bookingProvider.notifier);
    final filtered = bookingState.filteredBookings;
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isOwner = currentUser?.role == UserRole.owner;
    final isRenter = currentUser?.role == UserRole.renter;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isOwner
              ? 'Fleet Dispatches & Returns'
              : (isRenter ? 'My Equipment Rentals' : 'Rental Tracker & Bookings'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, size: 22),
            tooltip: 'Interactive Radius Map',
            onPressed: () => context.push('/bookings/map'),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, size: 22),
            tooltip: 'Scan Handover QR',
            onPressed: () => context.push('/bookings/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: () => notifier.fetchActiveBookings(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'map_radius_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.radar),
        label: const Text('Nearby Map Search', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/bookings/map'),
      ),
      body: Column(
        children: [
          // Contextual Role Subheader Banner
          if (isOwner)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x223B82F6) : const Color(0x153B82F6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.outbox_outlined, color: Color(0xFF3B82F6), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Owner Fleet Dispatches',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Oversee incoming contractor rentals, scan pickup handover QR codes, and log return condition checks.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (isRenter)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x2210B981) : const Color(0x1510B981),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.handyman_outlined, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Job-Site Rentals',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Track your reserved machinery, present pickup verification QR tokens, and review return deadlines.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // 1. Search Bar & Status Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Booking Code or ID...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) => notifier.setSearchQuery(val),
                ),
                const SizedBox(height: 10),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Confirmed', 'Active', 'Completed'].map((filter) {
                      final isSelected = bookingState.selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (_) => notifier.setFilter(filter),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Content View
          Expanded(
            child: Builder(
              builder: (context) {
                if (bookingState.isLoading && bookingState.activeBookings.isEmpty) {
                  return const LoadingIndicator(message: 'Loading active rental reservations...');
                }

                if (bookingState.errorMessage != null && bookingState.activeBookings.isEmpty) {
                  return ErrorView(
                    message: bookingState.errorMessage!,
                    onRetry: () => notifier.fetchActiveBookings(),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            bookingState.activeBookings.isEmpty
                                ? (isOwner
                                    ? 'No Fleet Dispatches Found'
                                    : (isRenter
                                        ? 'No Active Equipment Rentals'
                                        : 'No Active Bookings'))
                                : 'No Matching Bookings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bookingState.activeBookings.isEmpty
                                ? (isOwner
                                    ? 'No contractors have currently reserved your machinery. List more equipment or check back soon.'
                                    : 'Browse the equipment catalog or locate nearby machinery on the interactive map.')
                                : 'Try changing your search term or status filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isOwner)
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Machinery'),
                                  onPressed: () => context.push('/catalog/add'),
                                )
                              else
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.search, size: 18),
                                  label: const Text('Browse Catalog'),
                                  onPressed: () => context.go('/catalog'),
                                ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text('Radius Map'),
                                onPressed: () => context.push('/bookings/map'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primaryLight,
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  onRefresh: () => notifier.fetchActiveBookings(),
                  child: ListView.builder(
                    key: ValueKey('bookings_list_${isDark ? 'dark' : 'light'}'),
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return BookingCard(
                        key: ValueKey('${item.id}_${isDark ? 'dark' : 'light'}'),
                        booking: item,
                        onTap: () => context.push('/bookings/detail/${item.id}'),
                        onShowQR: isOwner ? () => context.push('/bookings/qr/${item.id}') : null,
                        onScanQR: isRenter ? () => context.push('/bookings/scan?bookingId=${item.id}') : null,
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
