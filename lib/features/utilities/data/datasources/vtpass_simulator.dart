import 'dart:async';

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

class VtPassSimulator {
  /// Simulates network latency
  static Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  /// Validates electricity meter numbers
  static Future<MeterValidationResult> validateMeter({
    required String meterNumber,
    required String discoCode,
  }) async {
    await _simulateDelay();
    
    final sanitized = meterNumber.trim();
    if (sanitized.length != 11 || !RegExp(r'^\d+$').hasMatch(sanitized)) {
      return MeterValidationResult(
        isValid: false,
        error: 'Invalid Meter Number. Must be exactly 11 digits.',
      );
    }

    // Specific mock accounts
    if (sanitized == '12345678901') {
      return MeterValidationResult(
        isValid: true,
        customerName: 'Darlington Nnamdi',
        address: '104 Alaba Way, Ikeja, Lagos',
      );
    } else if (sanitized == '98765432109') {
      return MeterValidationResult(
        isValid: true,
        customerName: 'Elizabeth Okoro',
        address: '45 Trans-Amadi Road, Port Harcourt',
      );
    } else if (sanitized == '55566677788') {
      return MeterValidationResult(
        isValid: true,
        customerName: 'Musa Yar\'Adua',
        address: '12 Garki Crescent, Abuja',
      );
    }

    // Dynamic success for any other 11 digit number
    return MeterValidationResult(
      isValid: true,
      customerName: 'Guest Customer (Meter: $sanitized)',
      address: 'Simulated Address (Disco: $discoCode)',
    );
  }

  /// Validates Cable TV Smartcard/IUC Numbers
  static Future<SmartcardValidationResult> validateSmartcard({
    required String smartcardNumber,
    required String provider, // "DSTV", "GOTV", "StarTimes"
  }) async {
    await _simulateDelay();

    final sanitized = smartcardNumber.trim();
    if (sanitized.length != 11 || !RegExp(r'^\d+$').hasMatch(sanitized)) {
      return SmartcardValidationResult(
        isValid: false,
        error: 'Invalid Smartcard/IUC Number. Must be exactly 11 digits.',
      );
    }

    if (sanitized == '11122233344') {
      return SmartcardValidationResult(
        isValid: true,
        customerName: 'Darlington Nnamdi',
        activePackage: 'Premium Package',
      );
    } else if (sanitized == '22233344455') {
      return SmartcardValidationResult(
        isValid: true,
        customerName: 'Elizabeth Okoro',
        activePackage: 'GOtv Max',
      );
    }

    return SmartcardValidationResult(
      isValid: true,
      customerName: 'Guest Subscriber ($sanitized)',
      activePackage: 'Basic / Compact Package',
    );
  }

  /// Simulates product purchasing via VTPass
  static Future<VtPassPurchaseResult> purchaseProduct({
    required String serviceType, // "Airtime", "Data", "Electricity", "Cable TV"
    required String target,      // phone, meter, or smartcard number
    required double amount,
  }) async {
    await _simulateDelay();
    
    final int hash = target.hashCode;
    if (hash % 50 == 0) {
      return VtPassPurchaseResult(
        success: false,
        error: 'VTPass Provider Service is temporarily unavailable. Please try again.',
      );
    }
    
    final txId = 'VTP-${(hash.abs() ^ DateTime.now().millisecond).toString().padRight(8, '9').substring(0, 8).toUpperCase()}';
    
    String? token;
    if (serviceType == 'Electricity') {
      final randomPart = hash.abs().toString().padRight(20, '4');
      token = '${randomPart.substring(0, 4)}-${randomPart.substring(4, 8)}-${randomPart.substring(8, 12)}-${randomPart.substring(12, 16)}-${randomPart.substring(16, 20)}';
    }
    
    return VtPassPurchaseResult(
      success: true,
      transactionId: txId,
      token: token,
    );
  }
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
