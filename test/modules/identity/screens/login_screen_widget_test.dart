import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rentatool_mobile/modules/identity/providers/auth_provider.dart';
import 'package:rentatool_mobile/modules/identity/screens/login_screen.dart';
import 'package:go_router/go_router.dart';

// ──────────────────────────────────────────────
// MOCKS
// ──────────────────────────────────────────────
class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier() : super(const AuthState());

  @override
  Future<bool> login({required String email, required String password}) async {
    return true;
  }

  @override
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
  }) async => true;

  @override
  Future<void> checkCurrentSession() async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> saveLocalProfilePhoto(String path) async {}

  @override
  Future<void> fetchProfile() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFailAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockFailAuthNotifier()
      : super(const AuthState(errorMessage: 'Invalid credentials'));

  @override
  Future<bool> login({required String email, required String password}) async {
    state = const AuthState(errorMessage: 'Invalid credentials');
    return false;
  }

  @override
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
  }) async => false;

  @override
  Future<void> checkCurrentSession() async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> saveLocalProfilePhoto(String path) async {}

  @override
  Future<void> fetchProfile() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ──────────────────────────────────────────────
// HELPERS
// ──────────────────────────────────────────────
Widget _buildLoginScreen({AuthNotifier? notifier}) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/catalog', builder: (_, __) => const Scaffold(body: Text('Catalog'))),
    GoRoute(path: '/register', builder: (_, __) => const Scaffold(body: Text('Register'))),
  ]);

  return ProviderScope(
    overrides: [
      if (notifier != null)
        authProvider.overrideWith((_) => notifier),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ──────────────────────────────────────────────
// TEST CASES
// ──────────────────────────────────────────────
void main() {
  group('TC-LOGIN-001 — LoginScreen renders all fields and button', () {
    testWidgets('Shows email field, password field, and Sign In button', (tester) async {
      await tester.pumpWidget(_buildLoginScreen(notifier: MockAuthNotifier()));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });
  });

  group('TC-LOGIN-002 — Default values are pre-filled in debug mode', () {
    testWidgets('Email and password fields contain debug defaults', (tester) async {
      await tester.pumpWidget(_buildLoginScreen(notifier: MockAuthNotifier()));
      await tester.pumpAndSettle();

      // In debug mode, fields should have pre-filled values
      final emailField = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).at(0),
          matching: find.byType(EditableText),
        ).first,
      );
      expect(emailField.controller.text, isNotEmpty);
    });
  });

  group('TC-LOGIN-003 — Empty fields show validation errors', () {
    testWidgets('Tapping Sign In with empty fields shows required errors', (tester) async {
      await tester.pumpWidget(_buildLoginScreen(notifier: MockAuthNotifier()));
      await tester.pumpAndSettle();

      // Clear all fields first
      await tester.enterText(find.byType(TextFormField).at(0), '');
      await tester.enterText(find.byType(TextFormField).at(1), '');

      // Tap Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });
  });

  group('TC-LOGIN-004 — Invalid email shows validation error', () {
    testWidgets('Invalid email format shows error message', (tester) async {
      await tester.pumpWidget(_buildLoginScreen(notifier: MockAuthNotifier()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });
  });

  group('TC-LOGIN-005 — Valid input calls the login function', () {
    testWidgets('Valid credentials trigger login and navigate to catalog', (tester) async {
      await tester.pumpWidget(_buildLoginScreen(notifier: MockAuthNotifier()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'renter@rentatool.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Renter@123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Catalog'), findsOneWidget);
    });
  });

  group('TC-LOGIN-006 — Failed login shows error banner', () {
    testWidgets('Login failure shows error message from API', (tester) async {
      await tester.pumpWidget(_buildLoginScreen(notifier: MockFailAuthNotifier()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'wrong@email.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });

  group('TC-LOGIN-007 — Register navigation', () {
    testWidgets('Tapping Register Here navigates to register screen', (tester) async {
      await tester.pumpWidget(_buildLoginScreen(notifier: MockAuthNotifier()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Register Here'));
      await tester.pumpAndSettle();

      expect(find.text('Register'), findsOneWidget);
    });
  });
}
