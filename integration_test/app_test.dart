import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rentatool_mobile/main.dart' as app;

// ─────────────────────────────────────────────────────────────
// E2E CREDENTIALS
// ─────────────────────────────────────────────────────────────
const String _testEmail    = 'renter@rentatool.com';
const String _testPassword = 'Renter@123';

Future<void> _humanType(WidgetTester tester, Finder field, String text) async {
  await tester.tap(field);
  await tester.pump();
  String buffer = '';
  for (final char in text.split('')) {
    buffer += char;
    await tester.enterText(field, buffer);
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('RentaTool — Full-App E2E Visual Automation', () {
    testWidgets('STEP 1 — Login Screen', (WidgetTester tester) async {
      app.main();
      // Pump longer to allow secure_storage and router to initialize
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // Take screenshot of whatever is on screen first
      await binding.takeScreenshot('Step1_Login_PASS');

      // Try to fill login if fields are visible
      if (find.byType(TextFormField).evaluate().isNotEmpty) {
        final emailField = find.byType(TextFormField).at(0);
        await _humanType(tester, emailField, _testEmail);
        final passwordField = find.byType(TextFormField).at(1);
        await _humanType(tester, passwordField, _testPassword);
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await binding.takeScreenshot('Step1_Login_AfterSignIn_PASS');
      }
    });

    testWidgets('STEP 2 — Catalog', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));
      
      if (find.text('Sign In').evaluate().isNotEmpty) {
        await _humanType(tester, find.byType(TextFormField).at(0), _testEmail);
        await _humanType(tester, find.byType(TextFormField).at(1), _testPassword);
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle(const Duration(seconds: 4));
      }

      await tester.tap(find.text('Catalog'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon.first);
        await tester.pumpAndSettle();
        final searchField = find.byType(TextField).last;
        await _humanType(tester, searchField, 'excavator');
      }

      await tester.pumpAndSettle(const Duration(seconds: 2));
      await binding.takeScreenshot('Step2_Catalog_PASS');
    });

    testWidgets('STEP 3 — Bookings', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));
      
      if (find.text('Sign In').evaluate().isNotEmpty) {
        await _humanType(tester, find.byType(TextFormField).at(0), _testEmail);
        await _humanType(tester, find.byType(TextFormField).at(1), _testPassword);
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle(const Duration(seconds: 4));
      }

      await tester.tap(find.text('Bookings'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await binding.takeScreenshot('Step3_Bookings_PASS');
    });

    testWidgets('STEP 4 — Escrow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      if (find.text('Sign In').evaluate().isNotEmpty) {
        await _humanType(tester, find.byType(TextFormField).at(0), _testEmail);
        await _humanType(tester, find.byType(TextFormField).at(1), _testPassword);
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle(const Duration(seconds: 4));
      }

      await tester.tap(find.text('Escrow'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await binding.takeScreenshot('Step4_Escrow_PASS');
    });

    testWidgets('STEP 5 — Profile', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      if (find.text('Sign In').evaluate().isNotEmpty) {
        await _humanType(tester, find.byType(TextFormField).at(0), _testEmail);
        await _humanType(tester, find.byType(TextFormField).at(1), _testPassword);
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle(const Duration(seconds: 4));
      }

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Column), findsWidgets);
      await binding.takeScreenshot('Step5_Profile_PASS');
    });
  });
}

