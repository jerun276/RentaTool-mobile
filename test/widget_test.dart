import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentatool_mobile/core/widgets/app_button.dart';
import 'package:rentatool_mobile/core/widgets/status_badge.dart';
import 'package:rentatool_mobile/core/theme/app_theme.dart';

void main() {
  group('Core UI Component Widget Tests', () {
    testWidgets('AppButton renders with text and responds to tap', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Submit Verification',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Submit Verification'), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      expect(tapped, isTrue);
    });

    testWidgets('StatusBadge renders correct label and style', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(label: 'Verified Tier A', style: BadgeStyle.success),
          ),
        ),
      );

      expect(find.text('VERIFIED TIER A'), findsOneWidget);
    });
  });
}
