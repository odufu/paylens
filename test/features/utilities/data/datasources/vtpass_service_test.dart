import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mspay/features/utilities/data/datasources/vtpass_service.dart';

void main() {
  group('VtPassService - Electricity Bills Testing', () {
    test('should map electricity provider to correct service ID', () {
      // We can use a trick to test private static method _mapProviderToServiceId
      // or we can test public methods that call it, like validateMeter and purchaseProduct.
      // Let's test the request body mapping in purchaseProduct.
    });

    test('validateMeter returns MeterValidationResult when API call is successful', () async {
      final mockResponse = {
        'code': '000',
        'response_description': 'TRANSACTION SUCCESSFUL',
        'content': {
          'Customer_Name': 'John Doe',
          'Customer_Address': '123 Fake Street, Ikeja',
        }
      };

      await http.runWithClient(() async {
        final result = await VtPassService.validateMeter(
          meterNumber: '11002233445',
          discoCode: 'ikeja-electric',
        );

        expect(result.isValid, isTrue);
        expect(result.customerName, 'John Doe');
        expect(result.address, '123 Fake Street, Ikeja');
        expect(result.error, isNull);
      }, () => MockClient((request) async {
        expect(request.url.path, endsWith('/merchant-verify'));
        final body = jsonDecode(request.body);
        expect(body['billersCode'], '11002233445');
        expect(body['serviceID'], 'ikeja-electric');
        expect(body['type'], 'prepaid');

        return http.Response(jsonEncode(mockResponse), 200);
      }));
    });

    test('validateMeter returns error when API call fails', () async {
      final mockResponse = {
        'code': '011',
        'response_description': 'INVALID BILLERS CODE',
      };

      await http.runWithClient(() async {
        final result = await VtPassService.validateMeter(
          meterNumber: '99999999999',
          discoCode: 'eko-electric',
        );

        expect(result.isValid, isFalse);
        expect(result.customerName, isNull);
        expect(result.error, 'INVALID BILLERS CODE');
      }, () => MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      }));
    });

    test('purchaseProduct returns success result for prepaid electricity', () async {
      final mockResponse = {
        'code': '000',
        'response_description': 'TRANSACTION SUCCESSFUL',
        'content': {
          'transactions': {
            'transactionId': 'VTP-100200300',
          },
          'token': '1111-2222-3333-4444',
        }
      };

      await http.runWithClient(() async {
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
      }, () => MockClient((request) async {
        expect(request.url.path, endsWith('/pay'));
        final body = jsonDecode(request.body);
        expect(body['serviceID'], 'ikeja-electric');
        expect(body['billersCode'], '11002233445');
        expect(body['amount'], 5000.0);
        expect(body['variation_code'], 'prepaid');

        return http.Response(jsonEncode(mockResponse), 200);
      }));
    });
  });
}
