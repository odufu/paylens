class MonifyService {
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
    
    // Format as 8 digits string, padding with '5' if it's too short
    final suffix = hash.abs().toString().padRight(8, '5').substring(0, 8);
    
    // Bank prefixes for virtual accounts:
    // Wema Bank: prefix 90 (e.g. 90xxxxxxxx)
    // Sterling Bank: prefix 72 (e.g. 72xxxxxxxx)
    final prefix = bankCode == 'WEMA' ? '90' : '72';
    
    return '$prefix$suffix';
  }
}
