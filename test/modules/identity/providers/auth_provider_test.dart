import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rentatool_mobile/core/services/token_storage_service.dart';
import 'package:rentatool_mobile/modules/identity/models/user_model.dart';
import 'package:rentatool_mobile/modules/identity/providers/auth_provider.dart';
import 'package:rentatool_mobile/modules/identity/services/identity_service.dart';

class MockIdentityService extends Mock implements IdentityService {}
class MockTokenStorageService extends Mock implements TokenStorageService {}

void main() {
  late MockIdentityService mockIdentityService;
  late MockTokenStorageService mockTokenStorageService;

  setUp(() {
    mockIdentityService = MockIdentityService();
    mockTokenStorageService = MockTokenStorageService();
  });

  group('AuthNotifier Unit Tests', () {
    test('checkCurrentSession sets unauthenticated if no token', () async {
      when(() => mockTokenStorageService.hasToken()).thenAnswer((_) async => false);

      final notifier = AuthNotifier(mockIdentityService, mockTokenStorageService);
      
      // Wait for initial checkCurrentSession to finish
      await Future.delayed(Duration.zero);

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.isLoading, isFalse);
    });

    test('login success sets authenticated state and saves tokens', () async {
      // Setup initial state bypass
      when(() => mockTokenStorageService.hasToken()).thenAnswer((_) async => false);
      
      final notifier = AuthNotifier(mockIdentityService, mockTokenStorageService);
      await Future.delayed(Duration.zero);

      const email = 'test@example.com';
      const password = 'password123';
      const authResponse = AuthResponse(
        userId: '1',
        name: 'Test User',
        role: 'Renter',
        accessToken: 'access_token',
      );
      const userModel = UserModel(
        id: '1',
        name: 'Test User',
        email: email,
        phoneNumber: '1234567890',
        role: UserRole.renter,
      );

      when(() => mockIdentityService.login(email: email, password: password))
          .thenAnswer((_) async => authResponse);
      when(() => mockIdentityService.getUserProfile('1'))
          .thenAnswer((_) async => userModel);
          
      when(() => mockTokenStorageService.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});
      when(() => mockTokenStorageService.saveUser(
            userId: any(named: 'userId'),
            role: any(named: 'role'),
            name: any(named: 'name'),
            email: any(named: 'email'),
          )).thenAnswer((_) async {});
      when(() => mockTokenStorageService.getProfilePhoto('1'))
          .thenAnswer((_) async => null);

      final result = await notifier.login(email: email, password: password);

      expect(result, isTrue);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.user?.email, email);
      
      verify(() => mockTokenStorageService.saveTokens(
          accessToken: 'access_token', refreshToken: null)).called(1);
    });
  });
}
