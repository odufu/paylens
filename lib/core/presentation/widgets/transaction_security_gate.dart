import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/features/auth/presentation/state/auth_provider.dart';

class TransactionSecurityGate {
  /// Prompts the user for authorization before performing a transaction.
  /// First attempts biometrics (Face ID/Fingerprint) if enabled.
  /// Falls back to a secure 4-digit PIN dialog sheet if biometrics fails or is disabled.
  static Future<bool> authorize(BuildContext context, {String reason = 'Authorize Transaction'}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. If no transaction PIN is set up yet, bypass gate
    if (!authProvider.hasTransactionPin) {
      return true;
    }

    // 2. Try Biometrics if enabled
    if (authProvider.biometricsEnabled) {
      final success = await authProvider.authenticateWithBiometrics(reason);
      if (success) {
        return true;
      }
    }

    // 3. Fallback to PIN Sheet
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransactionPinSheet(),
    );

    if (pin != null) {
      final isValid = authProvider.verifyTransactionPin(pin);
      if (!isValid && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect Transaction PIN! Authorization failed.'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return isValid;
    }

    return false;
  }
}

class TransactionPinSheet extends StatefulWidget {
  const TransactionPinSheet({super.key});

  @override
  State<TransactionPinSheet> createState() => _TransactionPinSheetState();
}

class _TransactionPinSheetState extends State<TransactionPinSheet> {
  String _pin = '';

  void _onKeyPress(String val) {
    if (_pin.length < 4) {
      setState(() {
        _pin += val;
      });
      
      // Auto-submit when 4 digits are completed
      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            Navigator.pop(context, _pin);
          }
        });
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A1E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(LucideIcons.lock, color: AppColors.primaryForest, size: 28),
          const SizedBox(height: 12),
          Text(
            'Enter Transaction PIN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Provide your 4-digit security PIN to authorize this vending transaction.',
            style: TextStyle(color: AppColors.textGrey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Display dots representing typed digits
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isTyped = index < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTyped
                      ? AppColors.primaryForest
                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                  border: Border.all(
                    color: isTyped
                        ? AppColors.accentLime
                        : (isDark ? Colors.white30 : Colors.grey.shade300),
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),

          // Custom Keypad Layout
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKeypadButton('1'),
                  _buildKeypadButton('2'),
                  _buildKeypadButton('3'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKeypadButton('4'),
                  _buildKeypadButton('5'),
                  _buildKeypadButton('6'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKeypadButton('7'),
                  _buildKeypadButton('8'),
                  _buildKeypadButton('9'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: IconButton(
                      icon: const Icon(LucideIcons.x, color: AppColors.errorRed),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  _buildKeypadButton('0'),
                  // Backspace button
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: IconButton(
                      icon: Icon(LucideIcons.delete, color: isDark ? Colors.white70 : AppColors.textDark),
                      onPressed: _onBackspace,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _onKeyPress(label),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
