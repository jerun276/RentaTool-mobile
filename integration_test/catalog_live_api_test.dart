import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rentatool_mobile/main.dart' as app;

/// Live cross-platform check. Run with the Development API available at the
/// target device's API_BASE_URL and the Development renter seed enabled.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('XPLAT-01 mobile reads the shared seeded catalog from the API', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 10));
    await binding.convertFlutterSurfaceToImage();

    if (find.text('Profile').evaluate().isNotEmpty) {
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      if (find.text('Sign In').evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();
      }
    }

    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).at(0), 'renter@rentatool.lk');
    await tester.enterText(find.byType(TextFormField).at(1), 'Renter@123');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle(const Duration(seconds: 10));

    expect(find.text('Fleet Machinery Catalog'), findsOneWidget);
    await tester.tap(find.text('Catalog'));
    await tester.pumpAndSettle(const Duration(seconds: 10));
    expect(find.text('Mikasa Plate Compactor 90kg'), findsOneWidget);
    await binding.takeScreenshot('XPLAT_01_Mobile_Live_Shared_Catalog');
  });
}
