import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mspay/features/utilities/presentation/pages/airtime_to_cash_screen.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';

class MockWalletProvider extends Mock implements WalletProvider {}

void main() {
  late MockWalletProvider mockWalletProvider;

  setUp(() {
    mockWalletProvider = MockWalletProvider();
    when(() => mockWalletProvider.balance).thenReturn(50000.0);
    when(() => mockWalletProvider.receiveAirtimeToCash(
      faceValue: any(named: 'faceValue'),
      payoutAmount: any(named: 'payoutAmount'),
      network: any(named: 'network'),
      senderPhone: any(named: 'senderPhone'),
    )).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<WalletProvider>.value(
      value: mockWalletProvider,
      child: const MaterialApp(
        home: AirtimeToCashScreen(),
      ),
    );
  }

  group('AirtimeToCashScreen Widget Tests', () {
    testWidgets('renders all initial fields and labels correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Airtime to Cash'), findsOneWidget);
      expect(find.text('Select Network Provider'), findsOneWidget);
      expect(find.text('Your Phone Number (Sender)'), findsOneWidget);
      expect(find.text('Airtime Amount to Liquidate (₦)'), findsOneWidget);
      expect(find.text('Confirm Transfer & Credit Wallet'), findsOneWidget);
    });

    testWidgets('calculates payout amount correctly at 75% rate', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter 1000 in amount text field
      final amountField = find.widgetWithText(TextFormField, 'Airtime Amount to Liquidate (₦)');
      await tester.enterText(amountField, '1000');
      await tester.pumpAndSettle();

      // Payout should be calculated: 1000 * 0.75 = 750
      expect(find.textContaining('Payout (75% conversion rate)'), findsOneWidget);
      expect(find.text('₦750.00'), findsOneWidget);
    });

    testWidgets('shows transfer instructions and generated code when amount is typed', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final amountField = find.widgetWithText(TextFormField, 'Airtime Amount to Liquidate (₦)');
      await tester.enterText(amountField, '2000');
      await tester.pumpAndSettle();

      expect(find.text('TRANSFER INSTRUCTIONS'), findsOneWidget);
      // Default provider is MTN, dial code should be generated: *600*08139455385*2000*PIN#
      expect(find.textContaining('*600*08139455385*2000*PIN#'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty on submit', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final submitButton = find.text('Confirm Transfer & Credit Wallet');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter sender phone number'), findsOneWidget);
      expect(find.text('Please enter airtime amount'), findsOneWidget);
    });
  });
}
