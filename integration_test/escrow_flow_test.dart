import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rentatool_mobile/core/theme/theme_provider.dart';
import 'package:rentatool_mobile/core/routes/app_router.dart';
import 'package:rentatool_mobile/core/theme/app_theme.dart';
import 'package:rentatool_mobile/modules/escrow/services/escrow_service.dart';
import 'package:rentatool_mobile/modules/escrow/models/damage_claim_model.dart';
import 'package:rentatool_mobile/modules/escrow/screens/claim_detail_screen.dart';
import 'package:rentatool_mobile/core/services/token_storage_service.dart';

class MockEscrowService extends Mock implements EscrowService {}

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

  late MockEscrowService mockEscrowService;
  late FakeTokenStorageService fakeTokenStorage;

  setUp(() {
    mockEscrowService = MockEscrowService();
    fakeTokenStorage = FakeTokenStorageService();
  });

  Widget createTestApp() {
    return ProviderScope(
      overrides: [
        escrowServiceProvider.overrideWithValue(mockEscrowService),
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

  testWidgets('E2E Escrow Flow: Escrow Overview -> Claim Details -> File Damage Claim', (WidgetTester tester) async {
    const testClaim = DamageClaimModel(
      claimId: 'c_999001',
      bookingId: 'BKG-12345',
      filedByUserId: 'test_user_id',
      damageDescription: 'Scratched housing and broken teeth during rental operation',
      proposedDeduction: 1500,
      status: ClaimStatus.filed,
      rawStatus: 'Filed',
    );

    when(() => mockEscrowService.getClaims())
        .thenAnswer((_) async => [testClaim]);

    when(() => mockEscrowService.getClaimById(any()))
        .thenAnswer((_) async => testClaim);

    // 1. Launch App & Navigate to Escrow Tab
    await tester.pumpWidget(createTestApp());
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.text('Escrow'));
    await tester.pumpAndSettle();

    expect(find.text('Escrow & Damage Disputes'), findsOneWidget);
    await binding.takeScreenshot('Esc_01_Escrow_Overview_List');

    // 2. Open Damage Claim Detail Screen
    await tester.tap(find.text('CLAIM-C_99'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(ClaimDetailScreen), findsOneWidget);
    await binding.takeScreenshot('Esc_02_Claim_Detail_Screen');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 3. Open File Claim Screen
    await tester.tap(find.text('File Claim'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('Esc_03_FileClaim_Form_Empty');

    // Fill form
    final bookingIdField = find.byType(TextFormField).at(0);
    await tester.scrollUntilVisible(bookingIdField, 200, scrollable: find.byType(Scrollable).first);
    await tester.enterText(bookingIdField, '33333333-3333-3333-3333-333333333301');

    final userIdField = find.byType(TextFormField).at(1);
    await tester.scrollUntilVisible(userIdField, 200, scrollable: find.byType(Scrollable).first);
    await tester.enterText(userIdField, '11111111-1111-1111-1111-111111111101');

    final descField = find.byType(TextFormField).at(2);
    await tester.scrollUntilVisible(descField, 200, scrollable: find.byType(Scrollable).first);
    await tester.enterText(descField, 'Scratched housing and broken teeth during rental operation');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    
    await binding.takeScreenshot('Esc_04_FileClaim_Form_Filled');
  });
}
