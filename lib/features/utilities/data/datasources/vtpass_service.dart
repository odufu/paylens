import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mspay/core/constants/api_constants.dart';

class MeterValidationResult {
  final bool isValid;
  final String? customerName;
  final String? address;
  final String? error;

  MeterValidationResult({
    required this.isValid,
    this.customerName,
    this.address,
    this.error,
  });
}

class SmartcardValidationResult {
  final bool isValid;
  final String? customerName;
  final String? activePackage;
  final String? error;

  SmartcardValidationResult({
    required this.isValid,
    this.customerName,
    this.activePackage,
    this.error,
  });
}

class VtPassPurchaseResult {
  final bool success;
  final String? transactionId;
  final String? token;
  final String? error;

  VtPassPurchaseResult({
    required this.success,
    this.transactionId,
    this.token,
    this.error,
  });
}

class VtPassService {
  /// Helper to map app network provider / disco names to VTPass serviceIDs
  static String _mapProviderToServiceId(String provider, String serviceType) {
    final cleanProvider = provider.trim().toLowerCase();
    
    if (serviceType == 'Airtime') {
      if (cleanProvider == '9mobile') return 'etisalat';
      return cleanProvider; // mtn, airtel, glo
    } else if (serviceType == 'Data') {
      if (cleanProvider == '9mobile') return 'etisalat-data';
      return '$cleanProvider-data'; // mtn-data, airtel-data, glo-data
    } else if (serviceType == 'Electricity') {
      return provider; // e.g. "ikeja-electric", "eko-electric", "abuja-electric", etc.
    } else if (serviceType == 'Cable TV') {
      return provider.toLowerCase(); // dstv, gotv, startimes
    }
    return provider;
  }

  /// Map UI package descriptions to typical VTPass variation_codes
  static String _mapPackageToVariationCode(String serviceID, String packageName) {
    final cleanName = packageName.toLowerCase();
    
    // Cable TV mapping
    if (serviceID == 'dstv') {
      if (cleanName.contains('premium')) return 'dstv3';
      if (cleanName.contains('compact plus')) return 'dstv7';
      if (cleanName.contains('compact')) return 'dstv79';
      if (cleanName.contains('confam')) return 'dstv-confam';
      if (cleanName.contains('yanga')) return 'dstv-yanga';
      return 'dstv-padi';
    }
    if (serviceID == 'gotv') {
      if (cleanName.contains('lite')) return 'gotv-lite';
      if (cleanName.contains('max')) return 'gotv-max';
      if (cleanName.contains('jolli')) return 'gotv-jolli';
      if (cleanName.contains('jinja')) return 'gotv-jinja';
      if (cleanName.contains('supa')) return 'gotv-supa-plus';
      return 'gotv-lite';
    }
    if (serviceID == 'startimes') {
      if (cleanName.contains('super')) return 'super';
      if (cleanName.contains('smart')) return 'smart';
      if (cleanName.contains('nova')) return 'nova';
      if (cleanName.contains('classic')) return 'classic';
      return 'basic';
    }
    
    // Data mapping (e.g. mtn-data, airtel-data, etc.)
    if (serviceID.contains('-data')) {
      final prefix = serviceID.split('-').first;
      if (prefix == 'mtn') {
        if (cleanName.contains('1.5 gb') || cleanName.contains('1.5gb')) return 'mtn-100mb-1000';
        if (cleanName.contains('3 gb') || cleanName.contains('3gb')) return 'mtn-3gb-1500';
        if (cleanName.contains('10 gb') || cleanName.contains('10gb')) return 'mtn-1gb-3500';
        if (cleanName.contains('20 gb') || cleanName.contains('20gb')) return 'mtn-3gb-6000';
        if (cleanName.contains('40 gb') || cleanName.contains('40gb')) return 'mtn-40gb-10000';
      } else {
        if (cleanName.contains('1.5 gb') || cleanName.contains('1.5gb')) return '${prefix}-1-5gb';
        if (cleanName.contains('3 gb') || cleanName.contains('3gb')) return '${prefix}-3gb';
        if (cleanName.contains('10 gb') || cleanName.contains('10gb')) return '${prefix}-10gb';
        if (cleanName.contains('20 gb') || cleanName.contains('20gb')) return '${prefix}-20gb';
        if (cleanName.contains('40 gb') || cleanName.contains('40gb')) return '${prefix}-40gb';
      }
      return '${prefix}-1gb';
    }
    
    return packageName;
  }

  /// Generates a VTPass compliant transaction request_id
  /// Must be at least 12 characters, and start with the date formatted as YYYYMMDDHHII (Lagos time UTC+1)
  static String _generateRequestId() {
    final lagosTime = DateTime.now().toUtc().add(const Duration(hours: 1));
    final yyyy = lagosTime.year.toString();
    final mm = lagosTime.month.toString().padLeft(2, '0');
    final dd = lagosTime.day.toString().padLeft(2, '0');
    final hh = lagosTime.hour.toString().padLeft(2, '0');
    final ii = lagosTime.minute.toString().padLeft(2, '0');
    
    // Alphanumeric suffix using millisecond and microseconds to ensure uniqueness
    final uniqueSuffix = (lagosTime.millisecond * 1000 + lagosTime.microsecond).toString().padLeft(6, '0');
    return '$yyyy$mm$dd$hh$ii$uniqueSuffix';
  }

  /// Validates electricity meter numbers using VTPass /merchant-verify
  static Future<MeterValidationResult> validateMeter({
    required String meterNumber,
    required String discoCode,
  }) async {
    try {
      final serviceID = _mapProviderToServiceId(discoCode, 'Electricity');
      
      final response = await http.post(
        Uri.parse('${ApiConstants.vtPassBaseUrl}/merchant-verify'),
        headers: {
          'api-key': ApiConstants.vtPassApiKey,
          'secret-key': ApiConstants.vtPassSecretKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'billersCode': meterNumber.trim(),
          'serviceID': serviceID,
          'type': 'prepaid', // Default to prepaid validation
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final code = data['code'];
        
        if (code == '000') {
          final content = data['content'] ?? {};
          return MeterValidationResult(
            isValid: true,
            customerName: content['Customer_Name'] ?? 'Verified Customer',
            address: content['Customer_Address'] ?? 'Verified Address',
          );
        } else {
          return MeterValidationResult(
            isValid: false,
            error: data['response_description'] ?? 'Meter validation failed. Please check the details.',
          );
        }
      } else {
        return MeterValidationResult(
          isValid: false,
          error: 'HTTP error ${response.statusCode} calling verification service.',
        );
      }
    } catch (e) {
      debugPrint('VTPass Meter Validation Exception: $e');
      return MeterValidationResult(
        isValid: false,
        error: 'Failed to connect to verification provider. Check internet connectivity.',
      );
    }
  }

  /// Attempts to automatically detect the Disco provider from a meter number by validating across all available Discos in parallel
  static Future<Map<String, dynamic>?> autoDetectDisco({
    required String meterNumber,
  }) async {
    final List<String> discoCodes = [
      'ikeja-electric',
      'eko-electric',
      'abuja-electric',
      'ibadan-electric',
      'kano-electric',
      'port-harcourt',
    ];

    try {
      final List<Future<MeterValidationResult>> futures = discoCodes.map((code) {
        return validateMeter(meterNumber: meterNumber, discoCode: code);
      }).toList();

      final results = await Future.wait(futures);

      for (int i = 0; i < results.length; i++) {
        if (results[i].isValid) {
          return {
            'discoCode': discoCodes[i],
            'validationResult': results[i],
          };
        }
      }
    } catch (e) {
      debugPrint('Auto-detect Disco Exception: $e');
    }
    return null;
  }

  /// Validates Cable TV Smartcard/IUC Numbers using VTPass /merchant-verify
  static Future<SmartcardValidationResult> validateSmartcard({
    required String smartcardNumber,
    required String provider,
  }) async {
    try {
      final serviceID = _mapProviderToServiceId(provider, 'Cable TV');
      
      final response = await http.post(
        Uri.parse('${ApiConstants.vtPassBaseUrl}/merchant-verify'),
        headers: {
          'api-key': ApiConstants.vtPassApiKey,
          'secret-key': ApiConstants.vtPassSecretKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'billersCode': smartcardNumber.trim(),
          'serviceID': serviceID,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final code = data['code'];
        
        if (code == '000') {
          final content = data['content'] ?? {};
          return SmartcardValidationResult(
            isValid: true,
            customerName: content['Customer_Name'] ?? 'Verified Subscriber',
            activePackage: content['Current_Plan'] ?? 'Active Package',
          );
        } else {
          return SmartcardValidationResult(
            isValid: false,
            error: data['response_description'] ?? 'Smartcard validation failed. Verify ID number.',
          );
        }
      } else {
        return SmartcardValidationResult(
          isValid: false,
          error: 'HTTP error ${response.statusCode} calling verification service.',
        );
      }
    } catch (e) {
      debugPrint('VTPass Smartcard Validation Exception: $e');
      return SmartcardValidationResult(
        isValid: false,
        error: 'Failed to connect to verification provider. Check internet connectivity.',
      );
    }
  }

  /// Purchase utility product (Airtime, Data, Electricity, Cable TV) via VTPass /pay
  static Future<VtPassPurchaseResult> purchaseProduct({
    required String serviceType, // "Airtime", "Data", "Electricity", "Cable TV"
    required String target,      // phone, meter, or smartcard number
    required double amount,
    String? providerName,        // MTN, Airtel, dstv, gotv, or disco codes
    String? packageName,         // Selected package name/desc for Data & TV
    String? variationCode,       // Direct variation code bypass
  }) async {
    try {
      final serviceID = _mapProviderToServiceId(providerName ?? '', serviceType);
      final finalVariation = variationCode ?? 
          ((serviceType == 'Data' || serviceType == 'Cable TV') && packageName != null
              ? _mapPackageToVariationCode(serviceID, packageName)
              : (serviceType == 'Electricity' ? 'prepaid' : null));

      final Map<String, dynamic> body = {
        'request_id': _generateRequestId(),
        'serviceID': serviceID,
        'billersCode': target.trim(),
        'amount': amount,
        'phone': serviceType == 'Airtime' || serviceType == 'Data' ? target.trim() : '08012345678',
      };

      if (finalVariation != null) {
        body['variation_code'] = finalVariation;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.vtPassBaseUrl}/pay'),
        headers: {
          'api-key': ApiConstants.vtPassApiKey,
          'secret-key': ApiConstants.vtPassSecretKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final code = data['code'];
        
        if (code == '000') {
          final content = data['content'] ?? {};
          final transaction = content['transactions'] ?? {};
          final token = content['token'] ?? transaction['token'];
          
          return VtPassPurchaseResult(
            success: true,
            transactionId: transaction['transactionId']?.toString() ?? 'VTP-${DateTime.now().millisecondsSinceEpoch}',
            token: token,
          );
        } else {
          return VtPassPurchaseResult(
            success: false,
            error: data['response_description'] ?? 'Transaction failed. Check wallet balance and try again.',
          );
        }
      } else {
        return VtPassPurchaseResult(
          success: false,
          error: 'HTTP error ${response.statusCode} returned from payment server.',
        );
      }
    } catch (e) {
      debugPrint('VTPass Purchase Exception: $e');
      return VtPassPurchaseResult(
        success: false,
        error: 'Network connection error during utility purchase checkout.',
      );
    }
  }
}
