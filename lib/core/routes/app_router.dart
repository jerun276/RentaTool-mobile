import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/main_shell_screen.dart';

// Component 1 (Identity)
import '../../modules/identity/screens/login_screen.dart';
import '../../modules/identity/screens/register_screen.dart';
import '../../modules/identity/screens/profile_screen.dart';
import '../../modules/identity/screens/kyc_submission_screen.dart';
import '../../modules/identity/providers/auth_provider.dart';

// Component 2 (Catalog)
import '../../modules/catalog/screens/equipment_catalog_screen.dart';
import '../../modules/catalog/screens/admin_category_screen.dart';
import '../../modules/catalog/screens/equipment_detail_screen.dart';
import '../../modules/catalog/screens/add_equipment_screen.dart';
import '../../modules/catalog/screens/condition_inspection_screen.dart';
import '../../modules/catalog/screens/equipment_history_screen.dart';
import '../../modules/catalog/screens/my_equipment_screen.dart';

// Component 3 (Booking)
import '../../modules/booking/screens/active_bookings_screen.dart';
import '../../modules/booking/screens/booking_detail_screen.dart';
import '../../modules/booking/screens/qr_handover_screen.dart';
import '../../modules/booking/screens/qr_scanner_screen.dart';
import '../../modules/booking/screens/create_booking_screen.dart';
import '../../modules/booking/screens/booking_map_screen.dart';
import '../../modules/catalog/models/equipment_model.dart';

// Component 4 (Escrow)
import '../../modules/escrow/screens/escrow_overview_screen.dart';
import '../../modules/escrow/screens/claim_detail_screen.dart';
import '../../modules/escrow/screens/file_claim_screen.dart';
import '../../modules/escrow/screens/pre_authorize_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = _buildRouter();

  // Auto-logout: when an authenticated session is dropped (e.g. expired JWT),
  // send the user straight to the login screen.
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous != null && previous.isAuthenticated && !next.isAuthenticated) {
      router.go('/login');
    }
  });

  return router;
});

GoRouter _buildRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/catalog',
    routes: [
      // Auth Routes (Outside Bottom Nav Shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/kyc-submit',
        builder: (context, state) => const KycSubmissionScreen(),
      ),
      GoRoute(
        path: '/admin/categories',
        builder: (context, state) => const AdminCategoryScreen(),
      ),

      // Main Navigation Shell (4 Component Branches)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Catalog (Component 2 - Student 2)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/catalog',
                builder: (context, state) => const EquipmentCatalogScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return EquipmentDetailScreen(equipmentId: id);
                    },
                  ),
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddEquipmentScreen(),
                  ),
                  GoRoute(
                    path: 'inspection/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return ConditionInspectionScreen(equipmentId: id);
                    },
                  ),
                  GoRoute(
                    path: 'history/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return EquipmentHistoryScreen(equipmentId: id);
                    },
                  ),
                  GoRoute(
                    path: 'my-fleet',
                    builder: (context, state) => const MyEquipmentScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return EquipmentDetailScreen(equipmentId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Bookings (Component 3 - Student 3)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                builder: (context, state) {
                  if (state.extra is EquipmentModel) {
                    return CreateBookingScreen(equipment: state.extra as EquipmentModel);
                  }
                  return const ActiveBookingsScreen();
                },
                routes: [
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return BookingDetailScreen(bookingId: id);
                    },
                  ),
                  GoRoute(
                    path: 'qr/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return QrHandoverScreen(bookingId: id);
                    },
                  ),
                  GoRoute(
                    path: 'scan',
                    builder: (context, state) {
                      final bId = state.uri.queryParameters['bookingId'] ??
                          (state.extra is String ? state.extra as String : null);
                      return QrScannerScreen(bookingId: bId);
                    },
                  ),
                  GoRoute(
                    path: 'scan/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      return QrScannerScreen(bookingId: id);
                    },
                  ),
                  GoRoute(
                    path: 'create',
                    builder: (context, state) {
                      final equipment = state.extra is EquipmentModel ? state.extra as EquipmentModel : null;
                      return CreateBookingScreen(equipment: equipment);
                    },
                  ),
                  GoRoute(
                    path: 'map',
                    builder: (context, state) => const BookingMapScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Escrow & Claims (Component 4 - Student 4)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/escrow',
                builder: (context, state) => const EscrowOverviewScreen(),
                routes: [
                  GoRoute(
                    path: 'claim/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return ClaimDetailScreen(claimId: id);
                    },
                  ),
                  GoRoute(
                    path: 'claim-new',
                    builder: (context, state) => const FileClaimScreen(),
                  ),
                  GoRoute(
                    path: 'pre-authorize',
                    builder: (context, state) {
                      final bId = state.uri.queryParameters['bookingId'];
                      final rId = state.uri.queryParameters['renterId'];
                      final oId = state.uri.queryParameters['ownerId'];
                      final dep = double.tryParse(state.uri.queryParameters['deposit'] ?? '');
                      return PreAuthorizeScreen(
                        bookingId: bId,
                        renterId: rId,
                        ownerId: oId,
                        depositAmount: dep,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 4: Profile & Trust (Component 1 - Student 1)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
