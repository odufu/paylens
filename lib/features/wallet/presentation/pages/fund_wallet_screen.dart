import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/utils/currency_formatter.dart';
import 'package:mspay/features/auth/presentation/state/auth_provider.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';

class FundWalletScreen extends StatefulWidget {
  const FundWalletScreen({super.key});

  @override
  State<FundWalletScreen> createState() => _FundWalletScreenState();
}

class _FundWalletScreenState extends State<FundWalletScreen> {
  final TextEditingController _amountController = TextEditingController(text: '20000');
  String _selectedBank = 'Access Bank';
  bool _isSimulating = false;
  late final PageController _pageController;
  int _currentPage = 0;

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
    _pageController = PageController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _pageController.dispose();
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
                      'Fund your wallet instantly using your dedicated Wema Bank account number. Powered securely by Monify.',
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

            // VIRTUAL ACCOUNT CARDS CAROUSEL
            Text(
              'Virtual Account Details',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildVirtualAccountCard(
                    bankName: 'Wema Bank',
                    accountNumber: walletProvider.wemaAccountNumber,
                    accountName: 'Pay Lenses - ${authProvider.userFullName}',
                    gradientColors: [AppColors.primaryForest, const Color(0xFF033F28)],
                  ),
                  _buildVirtualAccountCard(
                    bankName: 'Sterling Bank',
                    accountNumber: walletProvider.sterlingAccountNumber,
                    accountName: 'Pay Lenses - ${authProvider.userFullName}',
                    gradientColors: [const Color(0xFF8B2635), const Color(0xFF5E1721)],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
                final isSelected = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: isSelected ? 24 : 8,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentLime : Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
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
}
