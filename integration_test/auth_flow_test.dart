import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rentatool_mobile/core/routes/app_router.dart';
import 'package:rentatool_mobile/core/services/token_storage_service.dart';
import 'package:rentatool_mobile/core/theme/app_theme.dart';
import 'package:rentatool_mobile/core/theme/theme_provider.dart';
import 'package:rentatool_mobile/modules/identity/models/trust_score_model.dart';
import 'package:rentatool_mobile/modules/identity/models/user_model.dart';
import 'package:rentatool_mobile/modules/identity/providers/auth_provider.dart';
import 'package:rentatool_mobile/modules/identity/services/identity_service.dart';

class MockIdentityService extends Mock implements IdentityService {}

class FakeTokenStorageService implements TokenStorageService {
  final Map<String, String> _storage = {};

  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    _storage['token'] = accessToken;
  }

  @override
  Future<String?> getAccessToken() async => _storage['token'];
  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> saveUser({required String userId, required String role, String? name, String? email}) async {
    _storage['id'] = userId;
    _storage['role'] = role;
    if (name != null) _storage['name'] = name;
    if (email != null) _storage['email'] = email;
  }

  @override
  Future<String?> getUserId() async => _storage['id'];
  @override
  Future<String?> getUserRole() async => _storage['role'];
  @override
  Future<String?> getUserName() async => _storage['name'];
  @override
  Future<String?> getUserEmail() async => _storage['email'];
  @override
  Future<void> clearAll() async => _storage.clear();
  @override
  Future<bool> hasToken() async => _storage.containsKey('token');

  @override
  Future<void> saveProfilePhoto(String userId, String path) async {
    _storage['photo_$userId'] = path;
  }

  @override
  Future<String?> getProfilePhoto(String userId) async => _storage['photo_$userId'];
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late MockIdentityService identityService;
  late FakeTokenStorageService tokenStorage;

  const authResponse = AuthResponse(
    userId: 'identity-e2e-user',
    name: 'Identity Test User',
    role: 'Renter',
    accessToken: 'identity-e2e-token',
  );

  const profile = UserModel(
    id: 'identity-e2e-user',
    name: 'Identity Test User',
    email: 'identity@example.com',
    phoneNumber: '0771122334',
    role: UserRole.renter,
    trustScore: 88,
  );

  setUp(() {
    identityService = MockIdentityService();
    tokenStorage = FakeTokenStorageService();
  });

  Widget createTestApp() => ProviderScope(
        overrides: [
          identityServiceProvider.overrideWithValue(identityService),
          tokenStorageServiceProvider.overrideWithValue(tokenStorage),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            title: 'RentaTool Identity Test',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ref.watch(themeProvider),
            routerConfig: ref.watch(appRouterProvider),
          ),
        ),
      );

  Future<void> launchApp(WidgetTester tester) async {
    await tester.pumpWidget(createTestApp());
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  Future<void> openLogin(WidgetTester tester) async {
    await launchApp(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Please sign in to view your profile.'), findsOneWidget);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('RentaTool LK'), findsOneWidget);
  }

  Future<void> openRegister(WidgetTester tester) async {
    await openLogin(tester);
    await tester.tap(find.text('Register Here'));
    await tester.pumpAndSettle();
    expect(find.text('Create Account'), findsOneWidget);
  }

  Future<void> fillLogin(WidgetTester tester, {String email = 'identity@example.com', String password = 'Password@123'}) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
  }

  Future<void> tapCreateAccount(WidgetTester tester) async {
    final button = find.text('Create account');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.scrollUntilVisible(button, 250, scrollable: find.byType(Scrollable).first);
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  Future<void> setRegistrationField(WidgetTester tester, String key, String value) async {
    final field = find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(TextFormField),
    );
    await tester.scrollUntilVisible(field, 200, scrollable: find.byType(Scrollable).first);
    await tester.enterText(field, value);
  }

  Future<void> loginAsTestUser(WidgetTester tester) async {
    when(() => identityService.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => authResponse);
    when(() => identityService.getUserProfile('identity-e2e-user')).thenAnswer((_) async => profile);
    await openLogin(tester);
    await fillLogin(tester);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Fleet Machinery Catalog'), findsOneWidget);
  }

  testWidgets('TC-ID-01 login required-field and email validation', (tester) async {
    await openLogin(tester);
    await fillLogin(tester, email: '', password: '');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    await binding.takeScreenshot('ID_01_Login_Validation_Errors');
    verifyNever(() => identityService.login(email: any(named: 'email'), password: any(named: 'password')));
  });

  testWidgets('TC-ID-02 displays an authentication error for rejected credentials', (tester) async {
    final request = RequestOptions(path: '/auth/login');
    when(() => identityService.login(email: any(named: 'email'), password: any(named: 'password'))).thenThrow(
      DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 401,
          data: {'message': 'Invalid email or password.'},
        ),
      ),
    );

    await openLogin(tester);
    await fillLogin(tester, password: 'WrongPassword');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Invalid email or password.'), findsOneWidget);
    expect(await tokenStorage.hasToken(), isFalse);
    await binding.takeScreenshot('ID_02_Login_Invalid_Credentials');
  });

  testWidgets('TC-ID-03 successful login persists the session and loads profile trust score', (tester) async {
    when(() => identityService.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => authResponse);
    when(() => identityService.getUserProfile('identity-e2e-user')).thenAnswer((_) async => profile);
    when(() => identityService.getTrustScore('identity-e2e-user')).thenAnswer(
      (_) async => const TrustScoreModel(userId: 'identity-e2e-user', score: 88, tier: 'Tier A'),
    );

    await openLogin(tester);
    await fillLogin(tester);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Fleet Machinery Catalog'), findsOneWidget);
    expect(await tokenStorage.hasToken(), isTrue);
    expect(await tokenStorage.getUserRole(), 'Renter');
    await binding.takeScreenshot('ID_03_Login_Success_Catalog');

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('User Profile & Trust'), findsOneWidget);
    expect(find.text('Identity Test User'), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    await binding.takeScreenshot('ID_04_Authenticated_Profile_Trust');
  });

  testWidgets('TC-ID-04 registration validates all required fields', (tester) async {
    await openRegister(tester);
    for (final key in [
      'reg_name_field',
      'reg_email_field',
      'reg_phone_field',
      'reg_password_field',
      'reg_confirm_password_field',
    ]) {
      await setRegistrationField(tester, key, '');
    }
    await tapCreateAccount(tester);

    await binding.takeScreenshot('ID_05_Register_Required_Field_Errors');
    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Mobile number is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
    verifyNever(() => identityService.register(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          phoneNumber: any(named: 'phoneNumber'),
          role: any(named: 'role'),
        ));
  });

  testWidgets('TC-ID-05 registration rejects mismatched passwords and invalid phone numbers', (tester) async {
    await openRegister(tester);
    await setRegistrationField(tester, 'reg_phone_field', '12345');
    await setRegistrationField(tester, 'reg_confirm_password_field', 'Different@123');
    await tapCreateAccount(tester);

    expect(find.text('Enter a valid 10-digit Sri Lankan number (e.g. 0771234567)'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    await binding.takeScreenshot('ID_06_Register_Phone_And_Password_Errors');
  });

  testWidgets('TC-ID-06 registration shows a recoverable server error', (tester) async {
    when(() => identityService.register(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          phoneNumber: any(named: 'phoneNumber'),
          role: any(named: 'role'),
        )).thenThrow(Exception('server unavailable'));

    await openRegister(tester);
    await tapCreateAccount(tester);

    expect(find.text('Registration failed. Please check your details.'), findsOneWidget);
    expect(await tokenStorage.hasToken(), isFalse);
    await binding.takeScreenshot('ID_07_Register_Server_Error');
  });

  testWidgets('TC-ID-07 owner registration sends the selected role and opens the catalog', (tester) async {
    when(() => identityService.register(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          phoneNumber: any(named: 'phoneNumber'),
          role: any(named: 'role'),
        )).thenAnswer((_) async => const AuthResponse(
              userId: 'identity-owner-e2e',
              name: 'Test User',
              role: 'Owner',
              accessToken: 'identity-owner-token',
            ));

    await openRegister(tester);
    await tester.tap(find.text('Equipment owner'));
    await tapCreateAccount(tester);

    expect(find.text('Fleet Machinery Catalog'), findsOneWidget);
    expect(await tokenStorage.getUserRole(), 'Owner');
    verify(() => identityService.register(
          name: 'Test User',
          email: 'newuser@example.com',
          password: 'Test@1234',
          phoneNumber: '0771234567',
          role: 'Owner',
        )).called(1);
    await binding.takeScreenshot('ID_08_Register_Owner_Success');
  });

  testWidgets('TC-ID-08 KYC rejects an invalid Sri Lankan NIC number', (tester) async {
    await loginAsTestUser(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Submit NIC Documents'));
    await tester.tap(find.text('Submit NIC Documents'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'invalid-nic');
    await tester.ensureVisible(find.text('Submit & Validate Document'));
    await tester.tap(find.text('Submit & Validate Document'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid Sri Lankan NIC number (e.g. 884210992V or 198842109923).'), findsOneWidget);
    await binding.takeScreenshot('ID_09_KYC_Invalid_NIC');
    verifyNever(() => identityService.submitKyc(
          documentNumber: any(named: 'documentNumber'),
          documentType: any(named: 'documentType'),
          frontImagePath: any(named: 'frontImagePath'),
          backImagePath: any(named: 'backImagePath'),
        ));
  });

  testWidgets('TC-ID-09 KYC requires a front document image after NIC validation', (tester) async {
    await loginAsTestUser(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Submit NIC Documents'));
    await tester.tap(find.text('Submit NIC Documents'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '198842109923');
    await tester.ensureVisible(find.text('Submit & Validate Document'));
    await tester.tap(find.text('Submit & Validate Document'));
    await tester.pumpAndSettle();

    expect(find.text('Front image of the document is required.'), findsOneWidget);
    await binding.takeScreenshot('ID_10_KYC_Front_Image_Required');
    verifyNever(() => identityService.submitKyc(
          documentNumber: any(named: 'documentNumber'),
          documentType: any(named: 'documentType'),
          frontImagePath: any(named: 'frontImagePath'),
          backImagePath: any(named: 'backImagePath'),
        ));
  });

  testWidgets('TC-NF-M01 login fields expose labels and remain usable with keyboard open', (tester) async {
    await openLogin(tester);
    final semantics = tester.ensureSemantics();

    try {
      // The visible label text also matches bySemanticsLabel, so assert the
      // explicit field Semantics widgets rather than every matching node.
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Email Address',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Password',
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Show password'), findsOneWidget);
    } finally {
      semantics.dispose();
    }

    final emailField = find.byType(TextFormField).first;
    await tester.tap(emailField);
    await tester.enterText(emailField, 'mobile-nfr@example.com');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign In'));
    expect(tester.takeException(), isNull);
    await binding.takeScreenshot('NF_MOB_01_Accessible_Login_Keyboard');
  });

  testWidgets('TC-NF-M02 login controls fit inside the mobile viewport', (tester) async {
    await openLogin(tester);
    final screen = MediaQuery.sizeOf(tester.element(find.byType(TextFormField).first));
    final emailRect = tester.getRect(find.byType(TextFormField).first);
    final passwordRect = tester.getRect(find.byType(TextFormField).at(1));
    final signInRect = tester.getRect(find.text('Sign In'));

    expect(emailRect.left, greaterThanOrEqualTo(0));
    expect(passwordRect.right, lessThanOrEqualTo(screen.width));
    expect(signInRect.right, lessThanOrEqualTo(screen.width));
    expect(signInRect.bottom, lessThanOrEqualTo(screen.height));
    expect(tester.takeException(), isNull);
    await binding.takeScreenshot('NF_MOB_02_Login_Viewport_Fit');
  });
}
