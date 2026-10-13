import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rentatool_mobile/core/theme/theme_provider.dart';
import 'package:rentatool_mobile/core/routes/app_router.dart';
import 'package:rentatool_mobile/core/theme/app_theme.dart';
import 'package:rentatool_mobile/modules/catalog/services/catalog_service.dart';
import 'package:rentatool_mobile/modules/catalog/models/equipment_model.dart';
import 'package:rentatool_mobile/modules/catalog/models/inspection_log_model.dart';
import 'package:rentatool_mobile/modules/catalog/models/equipment_history_model.dart';
import 'package:rentatool_mobile/modules/catalog/screens/equipment_detail_screen.dart';
import 'package:rentatool_mobile/modules/catalog/screens/add_equipment_screen.dart';
import 'package:rentatool_mobile/modules/catalog/screens/condition_inspection_screen.dart';
import 'package:rentatool_mobile/modules/catalog/screens/equipment_history_screen.dart';
import 'package:rentatool_mobile/core/services/token_storage_service.dart';

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

  late MockCatalogService mockCatalogService;
  late FakeTokenStorageService fakeTokenStorage;

  setUp(() {
    mockCatalogService = MockCatalogService();
    fakeTokenStorage = FakeTokenStorageService();
    registerFallbackValue(1);
    registerFallbackValue(20);
  });

  Widget createTestApp() {
    return ProviderScope(
      overrides: [
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

  testWidgets('E2E Catalog Flow: Catalog -> Search -> Add Equipment -> Detail -> Inspection -> History', (WidgetTester tester) async {
    const testEquipment = EquipmentModel(
      id: 'eq-123',
      ownerId: 'owner-456',
      title: 'Heavy Duty Excavator',
      description: 'Test Excavator',
      categoryId: 'earthmoving',
      dailyRate: 15000,
      replacementValue: 5000000,
      location: 'Colombo',
      status: 'Available',
      images: [],
    );

    const testInspection = InspectionLogModel(
      id: 'insp-01',
      equipmentId: 'eq-123',
      bookingId: 'bkg-101',
      inspectorId: 'user-007',
      inspectionType: 'PreRental',
      conditionNotes: 'Clean hydraulic seal.',
      photos: [],
    );

    const testHistory = EquipmentHistoryTimelineModel(
      equipmentId: 'eq-123',
      title: 'Heavy Duty Excavator',
      totalRentalDays: 45,
      requiresMaintenance: false,
      inspectionTimeline: [testInspection],
    );

    when(() => mockCatalogService.getEquipment(
          search: any(named: 'search'),
          categoryId: any(named: 'categoryId'),
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        )).thenAnswer((_) async => [testEquipment]);

    when(() => mockCatalogService.getEquipmentById(any()))
        .thenAnswer((_) async => testEquipment);

    when(() => mockCatalogService.getEquipmentHistory(any()))
        .thenAnswer((_) async => testHistory);

    // 1. Launch Catalog
    await tester.pumpWidget(createTestApp());
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('Cat_01_Catalog_Feed');

    expect(find.text('Heavy Duty Excavator'), findsWidgets);

    // 2. Search
    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'Excavator');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await binding.takeScreenshot('Cat_02_Search_Filtered');

    // 3. Open Add Equipment Screen
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    expect(find.byType(AddEquipmentScreen), findsOneWidget);
    await binding.takeScreenshot('Cat_03_Add_Equipment');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 4. Open Equipment Details
    await tester.tap(find.text('Heavy Duty Excavator').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(EquipmentDetailScreen), findsOneWidget);
    await binding.takeScreenshot('Cat_04_Equipment_Detail');

    // 5. Open Condition Inspection Screen
    await tester.tap(find.byTooltip('Condition Inspection'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(ConditionInspectionScreen), findsOneWidget);
    await binding.takeScreenshot('Cat_05_Condition_Inspection');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 6. Open Maintenance History Screen
    await tester.tap(find.byTooltip('Maintenance History'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(EquipmentHistoryScreen), findsOneWidget);
    await binding.takeScreenshot('Cat_06_Equipment_History');
  });
}
