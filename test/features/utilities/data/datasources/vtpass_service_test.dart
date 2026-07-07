import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mspay/core/di/injection_container.dart';
import 'package:mspay/features/utilities/data/datasources/vtpass_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockFunctionsClient mockFunctionsClient;

  setUpAll(() {
    mockSupabaseClient = MockSupabaseClient();
    mockFunctionsClient = MockFunctionsClient();
    when(() => mockSupabaseClient.functions).thenReturn(mockFunctionsClient);

    // Register in GetIt service locator for VtPassService to resolve
    sl.registerSingleton<SupabaseClient>(mockSupabaseClient);
  });

  group('VtPassService - Electricity Bills Testing', () {
    test(
      'validateMeter returns MeterValidationResult when API call is successful',
      () async {
        final mockResponse = {
          'code': '000',
          'response_description': 'TRANSACTION SUCCESSFUL',
          'content': {
            'Customer_Name': 'John Doe',
            'Customer_Address': '123 Fake Street, Ikeja',
          },
        };

        when(
          () => mockFunctionsClient.invoke('vtpass', body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 200, data: mockResponse),
        );

        final result = await VtPassService.validateMeter(
          meterNumber: '11002233445',
          discoCode: 'ikeja-electric',
        );

        expect(result.isValid, isTrue);
        expect(result.customerName, 'John Doe');
        expect(result.address, '123 Fake Street, Ikeja');
        expect(result.error, isNull);
      },
    );

    test('validateMeter returns error when API call fails', () async {
      final mockResponse = {
        'code': '011',
        'response_description': 'INVALID BILLERS CODE',
      };

      when(
        () => mockFunctionsClient.invoke('vtpass', body: any(named: 'body')),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200, data: mockResponse),
      );

      final result = await VtPassService.validateMeter(
        meterNumber: '99999999999',
        discoCode: 'eko-electric',
      );

      expect(result.isValid, isFalse);
      expect(result.customerName, isNull);
      expect(result.error, 'INVALID BILLERS CODE');
    });

    test(
      'purchaseProduct returns success result for prepaid electricity',
      () async {
        final mockResponse = {
          'code': '000',
          'response_description': 'TRANSACTION SUCCESSFUL',
          'content': {
            'transactions': {'transactionId': 'VTP-100200300'},
            'token': '1111-2222-3333-4444',
          },
        };

        when(
          () => mockFunctionsClient.invoke('vtpass', body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 200, data: mockResponse),
        );

        final result = await VtPassService.purchaseProduct(
          serviceType: 'Electricity',
          target: '11002233445',
          amount: 5000.0,
          providerName: 'ikeja-electric',
        );

        expect(result.success, isTrue);
        expect(result.transactionId, 'VTP-100200300');
        expect(result.token, '1111-2222-3333-4444');
        expect(result.error, isNull);
      },
    );
  });
}
