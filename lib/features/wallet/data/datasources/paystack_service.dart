class PaystackService {
  /// Deterministically generates a 10-digit virtual bank account number
  /// based on the user's UUID and bank code.
  static String generateVirtualAccount(String userId, String bankCode) {
    if (userId.isEmpty) return '3091827364';

    // Simple deterministic 32-bit hash calculation
    int hash = 0;
    final combined = '${userId}_$bankCode';
    for (int i = 0; i < combined.length; i++) {
      hash = 31 * hash + combined.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF; // Keep it 32-bit
    }

    // Format as 8 digits string, padding with '6' if it's too short
    final suffix = hash.abs().toString().padRight(8, '6').substring(0, 8);

    // Paystack partners virtual account prefixes:
    // Wema Bank: prefix 99 (e.g. 99xxxxxxxx)
    // Titan Trust Bank: prefix 88 (e.g. 88xxxxxxxx)
    final prefix = bankCode == 'WEMA' ? '99' : '88';

    return '$prefix$suffix';
  }

  /// Generates a deterministic Paystack customer code.
  static String generateCustomerCode(String userId) {
    if (userId.isEmpty) return 'CUST_3091827364';
    final suffix = userId.replaceAll('-', '').substring(0, 10).toUpperCase();
    return 'CUST_$suffix';
  }

  /// Gets bank name from code.
  static String getBankName(String bankCode) {
    return bankCode == 'WEMA' ? 'Wema Bank' : 'Titan Trust Bank';
  }
}
