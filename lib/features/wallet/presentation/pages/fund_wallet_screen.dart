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
  final TextEditingController _amountController = TextEditingController(text: '20000');
  final TextEditingController _depositController = TextEditingController();
  String _selectedBank = 'Access Bank';
  bool _isSimulating = false;
  bool _isInitializingPayment = false;

  final List<String> _mockBanks = [
    'Access Bank',
    'GTBank',
    'Zenith Bank',
    'United Bank for Africa (UBA)',
    'Sterling Bank',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _amountController.dispose();
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
      final authUrl = await walletProvider.initializePayment(amount);
      if (authUrl == null || authUrl.isEmpty) {
        throw Exception('Authorization URL is empty.');
      }

      if (mounted) {
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

  Future<void> _runFundingSimulation(WalletProvider walletProvider) async {
    final amtText = _amountController.text.trim();
    final double? amount = double.tryParse(amtText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid funding amount.')),
      );
      return;
    }

    setState(() {
      _isSimulating = true;
    });

    // Simulate network delays for Monify instant settlement
    await Future.delayed(const Duration(milliseconds: 1200));

    await walletProvider.fundWallet(amount, sourceBank: _selectedBank);

    if (mounted) {
      setState(() {
        _isSimulating = false;
      });

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
            'Funding Successful!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Your transfer of ${CurrencyFormatter.format(amount)} from $_selectedBank has settled. Your Pay Lenses wallet balance was updated instantly.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss Dialog
                Navigator.of(context).pop(); // Pop Fund Screen to view balance on Dashboard
              },
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      );
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
                                  'Regular Pay',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // INTERACTIVE SIMULATION UTILITY
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(LucideIcons.terminal, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(
                  'Instant Funding Simulator',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Simulate an external bank transfer to test instant wallet funding:',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Amount Input Field
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Simulated Amount (₦)',
                hintText: 'Enter amount to deposit',
                prefixIcon: Icon(LucideIcons.wallet),
              ),
            ),
            const SizedBox(height: 16),
            
            // Bank Selector Dropdown
            DropdownButtonFormField<String>(
              value: _selectedBank,
              decoration: const InputDecoration(
                labelText: 'Source Bank',
                prefixIcon: Icon(LucideIcons.building),
              ),
              items: _mockBanks.map((bank) {
                return DropdownMenuItem<String>(
                  value: bank,
                  child: Text(bank),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedBank = val;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            
            // Trigger Simulation Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSimulating ? null : () => _runFundingSimulation(walletProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryForest,
                  foregroundColor: Colors.white,
                ),
                child: _isSimulating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.send),
                          SizedBox(width: 8),
                          Text('Simulate Inward Bank Transfer'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildVirtualAccountCard({
    required String bankName,
    required String accountNumber,
    required String accountName,
    required List<Color> gradientColors,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BANK PROVIDER',
                    style: TextStyle(
                      color: AppColors.textLightGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bankName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                child: const Text(
                  'Monify Settled',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ACCOUNT NAME',
                style: TextStyle(
                  color: AppColors.textLightGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                accountName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACCOUNT NUMBER',
                    style: TextStyle(
                      color: AppColors.textLightGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    accountNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _copyToClipboard(accountNumber),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.copy,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
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
