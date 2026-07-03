import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mspay/features/profile/presentation/pages/in_app_documentation_screen.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: InAppDocumentationScreen(),
    );
  }

  group('InAppDocumentationScreen Widget Tests', () {
    testWidgets('renders all tabs in AppBar correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Developer API Docs'), findsOneWidget);
      expect(find.text('Monnify'), findsOneWidget);
      expect(find.text('VTPass'), findsOneWidget);
      expect(find.text('Aimtoget'), findsOneWidget);
      expect(find.text('Security Rules'), findsOneWidget);
    });

    testWidgets('displays Monnify content by default', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Monnify Wallet Services'), findsOneWidget);
      expect(find.textContaining('Handles instant virtual bank accounts'), findsOneWidget);
    });

    testWidgets('can tap and switch to other tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap VTPass Tab
      await tester.tap(find.text('VTPass').last);
      await tester.pumpAndSettle();

      expect(find.text('VTPass Services'), findsOneWidget);
      expect(find.textContaining('Utility bill payments'), findsOneWidget);

      // Tap Aimtoget Tab
      await tester.tap(find.text('Aimtoget').last);
      await tester.pumpAndSettle();

      expect(find.text('Aimtoget Airtime to Cash'), findsOneWidget);
      expect(find.textContaining('Automated conversion of carrier airtime'), findsOneWidget);

      // Tap Security Rules Tab
      await tester.tap(find.text('Security Rules').last);
      await tester.pumpAndSettle();

      expect(find.text('General API Security Rules'), findsOneWidget);
      expect(find.textContaining('Never Hardcode Keys in Codebase'), findsOneWidget);
    });
  });
}
