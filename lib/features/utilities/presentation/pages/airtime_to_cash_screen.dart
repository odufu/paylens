import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/utils/currency_formatter.dart';
import 'package:mspay/core/presentation/widgets/branded_spinner.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/wallet/data/models/transaction_model.dart';

class AirtimeToCashScreen extends StatefulWidget {
  const AirtimeToCashScreen({super.key});

  @override
  State<AirtimeToCashScreen> createState() => _AirtimeToCashScreenState();
}

class _AirtimeToCashScreenState extends State<AirtimeToCashScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String _selectedProvider = 'MTN';
  bool _isProcessing = false;
  double _payoutAmount = 0.0;
  
  // Payout rate (75% conversion)
  static const double _conversionRate = 0.75;
  
  // Mock merchant receiving numbers for simulation
  static const Map<String, String> _merchantNumbers = {
    'MTN': '08139455385',
    'Airtel': '09012233445',
    'Glo': '08051122334',
    '9mobile': '08099887766',
  };

  final List<Map<String, dynamic>> _providers = [
    {
      'name': 'MTN',
      'color': const Color(0xFFFFCC00),
      'textColor': Colors.black,
    },
    {
      'name': 'Airtel',
      'color': const Color(0xFFFF0000),
      'textColor': Colors.white,
    },
    {
      'name': 'Glo',
      'color': const Color(0xFF00FF00),
      'textColor': Colors.black,
    },
    {
      'name': '9mobile',
      'color': const Color(0xFF006644),
      'textColor': Colors.white,
    },
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updatePayout);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updatePayout);
    _phoneController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _updatePayout() {
    final amtText = _amountController.text.trim();
    final double? amount = double.tryParse(amtText);
    setState(() {
      if (amount != null && amount >= 50) {
        _payoutAmount = amount * _conversionRate;
      } else {
        _payoutAmount = 0.0;
      }
    });
  }

  String _generateDialCode(String amount) {
    final merchant = _merchantNumbers[_selectedProvider] ?? '08000000000';
    final pin = _pinController.text.isEmpty ? 'PIN' : _pinController.text;
    
    switch (_selectedProvider) {
      case 'MTN':
        return '*600*$merchant*$amount*$pin#';
      case 'Airtel':
        return '*432*1*$merchant*$amount*$pin#';
      case 'Glo':
        return '*131*1*$merchant*$amount*$pin#';
      case '9mobile':
        return '*223*$pin*$amount*$merchant#';
      default:
        return '*600*$merchant*$amount*$pin#';
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('USSD Dial code copied to clipboard!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _processConversion(WalletProvider walletProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final String amountText = _amountController.text.trim();
    final double amount = double.parse(amountText);
    final String senderPhone = _phoneController.text.trim();

    setState(() {
      _isProcessing = true;
    });

    // Show Custom Branded Loading Overlay
    BrandedLoadingOverlay.show(
      context,
      message: 'Verifying airtime transfer with $_selectedProvider...',
    );

    // Simulate verification delay (2.5 seconds)
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      BrandedLoadingOverlay.hide(context);
      
      // Credit wallet using receiveAirtimeToCash
      await walletProvider.receiveAirtimeToCash(
        faceValue: amount,
        payoutAmount: _payoutAmount,
        network: _selectedProvider,
        senderPhone: senderPhone,
      );

      setState(() {
        _isProcessing = false;
      });

      // Show beautiful success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(
            LucideIcons.checkCircle2,
            color: AppColors.successGreen,
            size: 48,
          ),
          title: const Text(
            'Liquidation Successful!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We have confirmed your transfer of ₦${amount.toStringAsFixed(0)} $_selectedProvider airtime.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${CurrencyFormatter.format(_payoutAmount)} has been credited to your Pay Lenses wallet instantly (75% conversion rate).',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss Dialog
                Navigator.of(context).pop(); // Back to Dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryForest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletProvider = Provider.of<WalletProvider>(context);
    final merchantNum = _merchantNumbers[_selectedProvider] ?? '08000000000';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Airtime to Cash', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top branding block showing exchange banner
            Container(
              color: AppColors.primaryForest,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                children: [
                  const Icon(LucideIcons.repeat, color: AppColors.accentLime, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    'Instant Airtime Liquidation',
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Convert your airtime back into actual cash balance in your wallet. Fast & Secured.',
                    style: TextStyle(color: AppColors.textLightGrey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Form container
            Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Select network
                      Text(
                        'Select Network Provider',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _providers.map((p) {
                          final bool isSelected = _selectedProvider == p['name'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedProvider = p['name'];
                              });
                            },
                            child: Container(
                              width: 72,
                              height: 56,
                              decoration: BoxDecoration(
                                color: p['color'],
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: AppColors.primaryForest, width: 3)
                                    : Border.all(color: Colors.transparent),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  p['name'],
                                  style: TextStyle(
                                    color: p['textColor'],
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Sender phone number
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Your Phone Number (Sender)',
                          hintText: 'Enter the 11-digit phone sending airtime',
                          prefixIcon: const Icon(LucideIcons.smartphone),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Please enter sender phone number';
                          final cleaned = val.trim();
                          if (cleaned.length != 11 || !RegExp(r'^\d+$').hasMatch(cleaned)) {
                            return 'Please enter a valid 11-digit phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Airtime amount
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Airtime Amount to Liquidate (₦)',
                          hintText: 'Minimum is ₦50',
                          prefixIcon: const Icon(LucideIcons.dollarSign),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter airtime amount';
                          }
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null || parsed < 50) {
                            return 'Minimum liquidation amount is ₦50';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Optional transfer pin
                      TextFormField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Your SIM Transfer PIN (Optional)',
                          hintText: 'Used to generate transfer dial code',
                          prefixIcon: const Icon(LucideIcons.lock),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Payout estimator card
                      if (_payoutAmount > 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.accentLime.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accentLime.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Payout (75% conversion rate)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.primaryForest,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(_payoutAmount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: AppColors.primaryForest,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You will receive ${CurrencyFormatter.format(_payoutAmount)} cash credited to your Pay Lenses wallet balance.',
                                style: const TextStyle(fontSize: 11, color: AppColors.primaryForest),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Instructions / Dial Code section
                      if (_amountController.text.isNotEmpty && double.tryParse(_amountController.text) != null && double.parse(_amountController.text) >= 50)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TRANSFER INSTRUCTIONS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '1. You must transfer the airtime to our merchant receiver number: $merchantNum',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white70 : AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '2. Or copy and dial this network code on your SIM:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white70 : AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black26 : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Text(
                                          _generateDialCode(_amountController.text),
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppColors.successGreen,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(LucideIcons.copy, size: 16),
                                      onPressed: () => _copyToClipboard(_generateDialCode(_amountController.text)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : () => _processConversion(walletProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryForest,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Confirm Transfer & Credit Wallet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Available Balance: ${CurrencyFormatter.format(walletProvider.balance)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
