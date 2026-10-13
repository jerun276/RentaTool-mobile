import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentatool_mobile/modules/identity/providers/auth_provider.dart';
import 'package:rentatool_mobile/modules/identity/screens/register_screen.dart';
import 'package:go_router/go_router.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier() : super(const AuthState());
  @override
  Future<bool> login({required String email, required String password}) async => true;
  @override
  Future<bool> register({required String name, required String email,
      required String password, required String phoneNumber, required String role}) async => true;
  @override Future<void> checkCurrentSession() async {}
  @override Future<void> logout() async {}
  @override Future<void> saveLocalProfilePhoto(String path) async {}
  @override Future<void> fetchProfile() async {}
  @override noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget _buildRegisterScreen() {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/catalog', builder: (_, __) => const Scaffold(body: Text('Catalog'))),
  ]);
  return ProviderScope(
    overrides: [authProvider.overrideWith((_) => MockAuthNotifier())],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Fills a field identified by its Key
Future<void> _fillByKey(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(Key(key));
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.enterText(finder, value);
  await tester.pump();
}

void main() {
  group('TC-REG-001 — RegisterScreen renders all required fields', () {
    testWidgets('Shows submit button and form fields', (tester) async {
      await tester.pumpWidget(_buildRegisterScreen());
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(find.text('Create account'), find.byType(Scrollable).first, const Offset(0, -300));
      expect(find.text('Create account'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });
  });

  group('TC-REG-002 — Default values are pre-filled in debug mode', () {
    testWidgets('Name and email fields have debug defaults', (tester) async {
      await tester.pumpWidget(_buildRegisterScreen());
      await tester.pumpAndSettle();
      final fields = tester.widgetList<EditableText>(find.byType(EditableText)).toList();
      expect(fields.isNotEmpty, true);
      expect(fields.first.controller.text, isNotEmpty);
    });
  });

  group('TC-REG-003 — Empty fields show validation errors', () {
    testWidgets('Empty name shows required error', (tester) async {
      await tester.pumpWidget(_buildRegisterScreen());
      await tester.pumpAndSettle();
      await _fillByKey(tester, 'reg_name_field', '');
      await tester.dragUntilVisible(find.text('Create account'), find.byType(Scrollable).first, const Offset(0, -300));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Full name is required'), findsOneWidget);
    });
  });

  group('TC-REG-004 — Invalid email shows validation error', () {
    testWidgets('Invalid email shows error', (tester) async {
      await tester.pumpWidget(_buildRegisterScreen());
      await tester.pumpAndSettle();
      await _fillByKey(tester, 'reg_email_field', 'not-valid');
      await tester.dragUntilVisible(find.text('Create account'), find.byType(Scrollable).first, const Offset(0, -300));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });
  });

  group('TC-REG-005 — Password mismatch shows error', () {
    testWidgets('Different confirm password shows mismatch error', (tester) async {
      await tester.pumpWidget(_buildRegisterScreen());
      await tester.pumpAndSettle();
      await _fillByKey(tester, 'reg_password_field', 'Password1');
      await _fillByKey(tester, 'reg_confirm_password_field', 'DifferentPass1');
      await tester.dragUntilVisible(find.text('Create account'), find.byType(Scrollable).first, const Offset(0, -300));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });

  group('TC-REG-006 — Short password shows length error', () {
    testWidgets('Password under 8 chars shows error', (tester) async {
      await tester.pumpWidget(_buildRegisterScreen());
      await tester.pumpAndSettle();
      await _fillByKey(tester, 'reg_password_field', 'abc');
      await tester.dragUntilVisible(find.text('Create account'), find.byType(Scrollable).first, const Offset(0, -300));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });
  });

  group('TC-REG-007 — Valid input calls register and navigates', () {
    testWidgets('Valid form navigates to Catalog', (tester) async {
      await tester.pumpWidget(_buildRegisterScreen());
      await tester.pumpAndSettle();
      await _fillByKey(tester, 'reg_name_field', 'Test User');
      await _fillByKey(tester, 'reg_email_field', 'test@example.com');
      await _fillByKey(tester, 'reg_phone_field', '0771234567');
      await _fillByKey(tester, 'reg_password_field', 'Test@1234');
      await _fillByKey(tester, 'reg_confirm_password_field', 'Test@1234');
      await tester.dragUntilVisible(find.text('Create account'), find.byType(Scrollable).first, const Offset(0, -300));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Catalog'), findsOneWidget);
    });
  });
}
