import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_card.dart';

class ActiveBookingsScreen extends ConsumerWidget {
  const ActiveBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Tracker & Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, size: 22),
            tooltip: 'Scan Handover QR',
            onPressed: () => context.push('/bookings/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: () => ref.read(bookingProvider.notifier).fetchActiveBookings(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (bookingState.isLoading && bookingState.activeBookings.isEmpty) {
            return const LoadingIndicator(message: 'Loading active rental reservations...');
          }

          if (bookingState.errorMessage != null && bookingState.activeBookings.isEmpty) {
            return ErrorView(
              message: bookingState.errorMessage!,
              onRetry: () => ref.read(bookingProvider.notifier).fetchActiveBookings(),
            );
          }

          if (bookingState.activeBookings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    const Text(
                      'No Active Bookings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Browse the equipment catalog to reserve machinery with verified smart handovers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Explore Catalog'),
                      onPressed: () => context.go('/catalog'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primaryLight,
            backgroundColor: AppColors.surface,
            onRefresh: () => ref.read(bookingProvider.notifier).fetchActiveBookings(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookingState.activeBookings.length,
              itemBuilder: (context, index) {
                final item = bookingState.activeBookings[index];
                return BookingCard(
                  booking: item,
                  onTap: () => context.push('/bookings/detail/${item.id}'),
                  onShowQR: () => context.push('/bookings/qr/${item.id}'),
                  onScanQR: () => context.push('/bookings/scan'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
