import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rentatool_mobile/core/widgets/app_button.dart';
import 'package:rentatool_mobile/core/widgets/app_text_field.dart';
import 'package:rentatool_mobile/modules/identity/providers/auth_provider.dart';
import 'package:rentatool_mobile/modules/identity/screens/login_screen.dart';

// Mock the AuthNotifier to control the authentication state during testing
class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  Future<bool> login({required String email, required String password}) async {
    return true; // default mock behaviour
  }
  
  // Implement other methods as no-ops or default values to satisfy the interface
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockGoRouter mockRouter;

  setUp(() {
    mockRouter = MockGoRouter();
  });

  Widget createWidgetUnderTest(AuthNotifier authNotifier) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => authNotifier),
      ],
      child: InheritedGoRouter(
        goRouter: mockRouter,
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
  }

  group('LoginScreen Widget & Form Validation Tests', () {
    testWidgets('renders login screen correctly', (WidgetTester tester) async {
      final notifier = MockAuthNotifier(const AuthState());
      await tester.pumpWidget(createWidgetUnderTest(notifier));

      // Verify UI elements
      expect(find.text('RentaTool LK'), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(2)); // Email and Password
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows form validation errors when fields are empty', (WidgetTester tester) async {
      final notifier = MockAuthNotifier(const AuthState());
      await tester.pumpWidget(createWidgetUnderTest(notifier));

      // Clear any pre-filled debug values first
      await tester.enterText(find.byType(TextFormField).at(0), '');
      await tester.enterText(find.byType(TextFormField).at(1), '');

      // Tap the sign in button without entering data
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      // Verify validation errors
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows form validation error for invalid email', (WidgetTester tester) async {
      final notifier = MockAuthNotifier(const AuthState());
      await tester.pumpWidget(createWidgetUnderTest(notifier));

      // Enter invalid email and valid password
      await tester.enterText(find.byType(TextFormField).at(0), 'invalidemail');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });
  });

  group('LoginScreen Navigation & Integration Tests', () {
    testWidgets('navigates to register screen when Register Here is tapped', (WidgetTester tester) async {
      final notifier = MockAuthNotifier(const AuthState());
      await tester.pumpWidget(createWidgetUnderTest(notifier));

      when(() => mockRouter.push('/register')).thenAnswer((_) => Future.value());

      await tester.tap(find.text('Register Here'));
      await tester.pumpAndSettle();

      verify(() => mockRouter.push('/register')).called(1);
    });

    testWidgets('navigates to catalog upon successful login', (WidgetTester tester) async {
      // Custom mock notifier that returns success
      final notifier = MockAuthNotifier(const AuthState());
      await tester.pumpWidget(createWidgetUnderTest(notifier));

      when(() => mockRouter.go('/catalog')).thenAnswer((_) {});

      // Enter valid credentials
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // Tap Sign In
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      // Verify navigation to catalog
      verify(() => mockRouter.go('/catalog')).called(1);
    });
  });
}
