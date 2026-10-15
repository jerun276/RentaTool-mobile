import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_card.dart';
import '../models/booking_model.dart';
import '../../identity/providers/auth_provider.dart';
import '../../identity/models/user_model.dart';
import '../../escrow/providers/escrow_provider.dart';
import '../../escrow/models/escrow_hold_model.dart';

class ActiveBookingsScreen extends ConsumerStatefulWidget {
  const ActiveBookingsScreen({super.key});

  @override
  ConsumerState<ActiveBookingsScreen> createState() => _ActiveBookingsScreenState();
}

class _ActiveBookingsScreenState extends ConsumerState<ActiveBookingsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(escrowProvider.notifier).fetchClaims();
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
    final bookingState = ref.watch(bookingProvider);
    final notifier = ref.read(bookingProvider.notifier);
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isOwner = currentUser?.role == UserRole.owner;
    final isRenter = currentUser?.role == UserRole.renter;
    final isAdmin = currentUser?.role == UserRole.admin;
    final escrowState = ref.watch(escrowProvider);

    bool checkIsDisputed(BookingModel b) {
      final isHoldDisputed = escrowState.holds.any((h) =>
          h.bookingId.toLowerCase() == b.id.toLowerCase() &&
          (h.status == EscrowStatus.disputed || h.rawStatus.toLowerCase() == 'disputed'));
      final hasClaim = escrowState.claims.any((c) =>
          c.bookingId.toLowerCase() == b.id.toLowerCase());
      return b.isDisputed || isHoldDisputed || hasClaim;
    }

    final userActiveBookings = isAdmin
        ? bookingState.activeBookings
        : bookingState.activeBookings.where((b) => b.renterId == currentUser?.id || b.ownerId == currentUser?.id).toList();

    final filtered = userActiveBookings.where((b) {
      // 1. Status Filter
      if (bookingState.selectedFilter != 'All') {
        final filterLower = bookingState.selectedFilter.toLowerCase();
        if (filterLower == 'disputed') {
          if (!checkIsDisputed(b)) return false;
        } else if (filterLower == 'active') {
          if (!b.isActive || checkIsDisputed(b)) return false;
        } else {
          if (b.status.toLowerCase() != filterLower) return false;
        }
      }

      // 2. Search Query filter (by ID, displayCode, equipment, or renter)
      if (bookingState.searchQuery.trim().isNotEmpty) {
        final q = bookingState.searchQuery.trim().toLowerCase();
        final matchesId = b.id.toLowerCase().contains(q);
        final matchesCode = b.displayCode.toLowerCase().contains(q);
        final matchesEq = b.equipmentId.toLowerCase().contains(q);
        final matchesTitle = b.equipmentTitle?.toLowerCase().contains(q) ?? false;
        final matchesCat = b.equipmentCategory?.toLowerCase().contains(q) ?? false;
        final matchesRenter = b.renterName?.toLowerCase().contains(q) ?? false;
        final matchesRenterEmail = b.renterEmail?.toLowerCase().contains(q) ?? false;
        final matchesRenterPhone = b.renterPhone?.toLowerCase().contains(q) ?? false;
        return matchesId ||
            matchesCode ||
            matchesEq ||
            matchesTitle ||
            matchesCat ||
            matchesRenter ||
            matchesRenterEmail ||
            matchesRenterPhone;
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isOwner
              ? 'Fleet Dispatches & Returns'
              : (isRenter ? 'My Equipment Rentals' : 'Rental Tracker & Bookings'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: () {
              notifier.fetchActiveBookings();
              ref.read(escrowProvider.notifier).fetchClaims();
            },
          ),
        ],
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
                    children: ['All', 'Requested', 'Confirmed', 'Active', 'Completed', 'Disputed'].map((filter) {
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
                if (bookingState.isLoading && userActiveBookings.isEmpty) {
                  return const LoadingIndicator(message: 'Loading active rental reservations...');
                }

                if (bookingState.errorMessage != null && userActiveBookings.isEmpty) {
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
                            userActiveBookings.isEmpty
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
                            userActiveBookings.isEmpty
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
                  onRefresh: () async {
                    await Future.wait([
                      notifier.fetchActiveBookings(),
                      ref.read(escrowProvider.notifier).fetchClaims(),
                    ]);
                  },
                  child: ListView.builder(
                    key: ValueKey('bookings_list_${isDark ? 'dark' : 'light'}'),
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isPickup = item.status.toLowerCase() == 'confirmed';
                      final isReturn = item.status.toLowerCase() == 'active';
                      final bool isItemOwner = (currentUser != null && currentUser.id == item.ownerId) || isOwner;
                      final bool isItemRenter = (currentUser != null && currentUser.id == item.renterId) || isRenter;
                      final bool isAdmin = currentUser?.role == UserRole.admin;

                      final bool canUseQR = isPickup || isReturn;

                      // Owner always shows QR (Pickup when Confirmed, Return when Active).
                      // Renter always scans QR (Pickup when Confirmed, Return when Active).
                      final bool canShow = canUseQR && (isItemOwner || isAdmin);
                      final bool canScan = canUseQR && (isItemRenter || isAdmin);

                      final bool isDisputed = checkIsDisputed(item);

                      return BookingCard(
                        key: ValueKey('${item.id}_${isDark ? 'dark' : 'light'}'),
                        booking: item,
                        isDisputed: isDisputed,
                        onTap: () => context.push('/bookings/detail/${item.id}'),
                        onShowQR: canShow && !isDisputed ? () => context.push('/bookings/qr/${item.id}') : null,
                        onScanQR: canScan && !isDisputed ? () => context.push('/bookings/scan?bookingId=${item.id}') : null,
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
