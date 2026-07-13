import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/utils/currency_formatter.dart';
import 'package:mspay/features/auth/presentation/state/auth_provider.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/wallet/presentation/pages/paystack_webview_page.dart';
import 'package:mspay/core/presentation/widgets/branded_spinner.dart';

class FundWalletScreen extends StatefulWidget {
  const FundWalletScreen({super.key});

  @override
  State<FundWalletScreen> createState() => _FundWalletScreenState();
}

class _FundWalletScreenState extends State<FundWalletScreen> {
  final TextEditingController _depositController = TextEditingController();
  bool _isInitializingPayment = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _depositController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account number copied to clipboard!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _fundWithPaystack(WalletProvider walletProvider) async {
    final amtText = _depositController.text.trim();
    final double? amount = double.tryParse(amtText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0.')),
      );
      return;
    }

    setState(() {
      _isInitializingPayment = true;
    });

    try {
      BrandedLoadingOverlay.show(context, message: 'Initializing payment...');
      final authUrl = await walletProvider.initializePayment(amount);
      if (authUrl == null || authUrl.isEmpty) {
        throw Exception('Authorization URL is empty.');
      }

      if (mounted) {
        BrandedLoadingOverlay.hide(context);
        // Open the payment inside our custom, controlled WebView frame
        final bool? success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PaystackWebViewPage(initialUrl: authUrl),
          ),
        );
        debugPrint("Payment WebView closed. Status: $success");
      }

      // Automatically refresh the wallet balance from the database after the webview closes
      await walletProvider.loadState();

      _depositController.clear();
    } catch (e) {
      if (mounted) {
        BrandedLoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize payment: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializingPayment = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fund Wallet'),
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADING INFO CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryForest.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryForest.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: AppColors.primaryForest, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fund your digital wallet instantly using cards, bank transfer, or USSD codes.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryForest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // DIGITAL WALLET DETAILS CARD
            Text(
              'Your Digital Wallet Details',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildDigitalWalletCard(
              walletId: authProvider.userId.isNotEmpty
                  ? 'PL-${authProvider.userId.substring(0, 8).toUpperCase()}'
                  : 'PL-UNASSIGNED',
              accountName: authProvider.userFullName,
              balanceText: CurrencyFormatter.format(walletProvider.balance),
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // PAYSTACK GATEWAY DEPOSIT CARD
            Text(
              'Fund Wallet Instantly (Cards, Bank Transfer, USSD)',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _depositController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount to Fund (₦)',
                      hintText: 'Enter amount (e.g., 2000)',
                      prefixIcon: Icon(LucideIcons.banknote),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isInitializingPayment ? null : () => _fundWithPaystack(walletProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isInitializingPayment
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: BrandedSpinner(radius: 12),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.creditCard, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Fund Wallet',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }



  Widget _buildDigitalWalletCard({
    required String walletId,
    required String accountName,
    required String balanceText,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryForest, Color(0xFF034F32), Color(0xFF023220)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryForest.withOpacity(0.35),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Row 1: Logo and Wallet Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.wallet, color: AppColors.accentLime, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'PAY LENSES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentLime,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.checkCircle2, color: AppColors.textDark, size: 10),
                    SizedBox(width: 4),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Row 2: Balance display
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AVAILABLE BALANCE',
                style: TextStyle(
                  color: AppColors.textLightGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                balanceText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // Row 3: Account Name & Wallet ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WALLET HOLDER',
                      style: TextStyle(
                        color: AppColors.textLightGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accountName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'WALLET ID',
                    style: TextStyle(
                      color: AppColors.textLightGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        walletId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _copyToClipboard(walletId),
                        child: Icon(
                          LucideIcons.copy,
                          color: Colors.white.withOpacity(0.7),
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
