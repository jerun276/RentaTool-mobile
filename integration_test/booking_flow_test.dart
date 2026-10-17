import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rentatool_mobile/core/theme/theme_provider.dart';
import 'package:rentatool_mobile/core/routes/app_router.dart';
import 'package:rentatool_mobile/core/theme/app_theme.dart';
import 'package:rentatool_mobile/modules/booking/services/booking_service.dart';
import 'package:rentatool_mobile/modules/catalog/services/catalog_service.dart';
import 'package:rentatool_mobile/modules/booking/models/booking_model.dart';
import 'package:rentatool_mobile/modules/booking/screens/booking_detail_screen.dart';
import 'package:rentatool_mobile/modules/booking/screens/qr_handover_screen.dart';
import 'package:rentatool_mobile/modules/booking/screens/qr_scanner_screen.dart';
import 'package:rentatool_mobile/modules/booking/screens/booking_map_screen.dart';
import 'package:rentatool_mobile/modules/booking/models/handover_token_model.dart';
import 'package:rentatool_mobile/core/services/token_storage_service.dart';

class MockBookingService extends Mock implements BookingService {}
class MockCatalogService extends Mock implements CatalogService {}

class FakeTokenStorageService implements TokenStorageService {
  final Map<String, String> _storage = {'token': 'dummy_token'};

  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {}
  @override
  Future<String?> getAccessToken() async => _storage['token'];
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> saveUser({required String userId, required String role, String? name, String? email}) async {}
  @override
  Future<String?> getUserId() async => 'test_user_id';
  @override
  Future<String?> getUserRole() async => 'renter';
  @override
  Future<String?> getUserName() async => 'Test User';
  @override
  Future<String?> getUserEmail() async => 'test@example.com';
  @override
  Future<void> clearAll() async => _storage.clear();
  @override
  Future<bool> hasToken() async => true;
  @override
  Future<void> saveProfilePhoto(String userId, String path) async {}
  @override
  Future<String?> getProfilePhoto(String userId) async => null;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockBookingService mockBookingService;
  late MockCatalogService mockCatalogService;
  late FakeTokenStorageService fakeTokenStorage;

  setUp(() {
    mockBookingService = MockBookingService();
    mockCatalogService = MockCatalogService();
    fakeTokenStorage = FakeTokenStorageService();
  });

  Widget createTestApp() {
    return ProviderScope(
      overrides: [
        bookingServiceProvider.overrideWithValue(mockBookingService),
        catalogServiceProvider.overrideWithValue(mockCatalogService),
        tokenStorageServiceProvider.overrideWithValue(fakeTokenStorage),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          return MaterialApp.router(
            title: 'Test App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ref.watch(themeProvider),
            routerConfig: ref.watch(appRouterProvider),
          );
        },
      ),
    );
  }

  testWidgets('E2E Booking Flow: Active Bookings -> Details -> QR Handover -> Scanner -> Map Search', (WidgetTester tester) async {
    final testBooking = BookingModel(
      id: '12345678-aaaa-bbbb-cccc-ddddeeeeffff',
      equipmentId: 'eq-123',
      renterId: 'test_user_id',
      ownerId: 'owner-456',
      status: 'Confirmed',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 3)),
      totalRentalFee: 45000,
    );

    final testToken = HandoverTokenModel(
      bookingId: '12345678-aaaa-bbbb-cccc-ddddeeeeffff',
      token: 'mock_qr_raw_hash_token_123',
      eventType: 'Pickup',
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
      qrPayload: 'mock_qr_payload_data',
    );

    when(() => mockBookingService.getActiveBookings())
        .thenAnswer((_) async => [testBooking]);

    when(() => mockCatalogService.getEquipment(
          search: any(named: 'search'),
          categoryId: any(named: 'categoryId'),
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        )).thenAnswer((_) async => []);

    when(() => mockBookingService.getBookingById(any()))
        .thenAnswer((_) async => testBooking);

    when(() => mockBookingService.generateHandoverToken(
          bookingId: any(named: 'bookingId'),
          eventType: any(named: 'eventType'),
        )).thenAnswer((_) async => testToken);

    // 1. Launch App & Navigate to Bookings
    await tester.pumpWidget(createTestApp());
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    
    expect(find.text(testBooking.displayCode), findsWidgets);
    await binding.takeScreenshot('Bkg_01_Active_Bookings_List');

    // 2. Open QR Scanner Screen from AppBar Action
    await tester.tap(find.descendant(
      of: find.byType(AppBar),
      matching: find.byTooltip('Scan Handover QR'),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(QrScannerScreen), findsOneWidget);
    await binding.takeScreenshot('Bkg_02_QR_Scanner_Screen');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 3. Open Booking Map Search Screen from AppBar Action
    await tester.tap(find.descendant(
      of: find.byType(AppBar),
      matching: find.byTooltip('Interactive Radius Map'),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(BookingMapScreen), findsOneWidget);
    await binding.takeScreenshot('Bkg_03_Interactive_Map_Search');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 4. Open Booking Detail Screen
    await tester.tap(find.text(testBooking.displayCode).first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(BookingDetailScreen), findsOneWidget);
    await binding.takeScreenshot('Bkg_04_Booking_Detail');

    // 5. Open QR Handover Screen from Action Button
    await tester.tap(find.descendant(
      of: find.byType(AppBar),
      matching: find.byTooltip('Show Handover QR'),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(QrHandoverScreen), findsOneWidget);
    await binding.takeScreenshot('Bkg_05_QR_Handover_Token');
  });
}
