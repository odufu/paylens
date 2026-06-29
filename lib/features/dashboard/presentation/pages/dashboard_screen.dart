import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/utils/currency_formatter.dart';
import 'package:mspay/features/auth/presentation/state/auth_provider.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/wallet/data/models/transaction_model.dart';
import 'package:mspay/features/wallet/presentation/pages/fund_wallet_screen.dart';
import 'package:mspay/features/wallet/presentation/pages/transfer_screen.dart';
import 'package:mspay/features/wallet/presentation/pages/transaction_history_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/airtime_data_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/electricity_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/cable_tv_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    final initials = authProvider.userFullName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join()
        .toUpperCase();
    final shortInitials = initials.substring(0, initials.length > 2 ? 2 : initials.length);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // FOREST GREEN CURVED HEADER BLOCK
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primaryForest,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hello header and Notification Bell
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.accentLime, width: 1.5),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: authProvider.avatarUrl != null
                                      ? Image.network(
                                          authProvider.avatarUrl!,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.white24,
                                            alignment: Alignment.center,
                                            child: Text(
                                              shortInitials.isNotEmpty ? shortInitials : 'DN',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.accentLime,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.white24,
                                          alignment: Alignment.center,
                                          child: Text(
                                            shortInitials.isNotEmpty ? shortInitials : 'DN',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.accentLime,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HELLO,',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textLightGrey.withOpacity(0.8),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  Text(
                                    authProvider.userFullName.split(' ').first,
                                    style: textTheme.titleLarge?.copyWith(
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Notification Bell Ring
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.textLightGrey.withOpacity(0.2),
                              ),
                            ),
                            child: const Stack(
                              children: [
                                Icon(
                                  LucideIcons.bell,
                                  color: AppColors.textLight,
                                  size: 20,
                                ),
                                Positioned(
                                  right: 2,
                                  top: 2,
                                  child: CircleAvatar(
                                    radius: 4,
                                    backgroundColor: AppColors.accentLime,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Wallet Balance Display
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Your Wallet Balance',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textLightGrey.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  walletProvider.isBalanceVisible
                                      ? CurrencyFormatter.format(walletProvider.balance)
                                      : '₦ ••••••••',
                                  style: textTheme.headlineMedium?.copyWith(
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 34,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: walletProvider.toggleBalanceVisibility,
                                  child: Icon(
                                    walletProvider.isBalanceVisible
                                        ? LucideIcons.eye
                                        : LucideIcons.eyeOff,
                                    color: AppColors.accentLime,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // CTAs: Fund & Send
                      Row(
                        children: [
                          Expanded(
                            child: _buildCTAButton(
                              icon: LucideIcons.plusCircle,
                              label: 'Fund',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const FundWalletScreen()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCTAButton(
                              icon: LucideIcons.send,
                              label: 'Send',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const TransferScreen()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Horizontal Tab Pills: Fund, Transfer, Withdraw, History, Manage
                      _buildPillSlider(context),
                    ],
                  ),
                ),
              ),
            ),
            
            // WHITE OVERLAPPING CONTENT CARD
            Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grid Navigation Shortcuts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildServiceShortcut(
                          context,
                          icon: LucideIcons.smartphone,
                          label: 'Airtime',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AirtimeDataScreen(isData: false)),
                          ),
                        ),
                        _buildServiceShortcut(
                          context,
                          icon: LucideIcons.barChart2,
                          label: 'Data',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AirtimeDataScreen(isData: true)),
                          ),
                        ),
                        _buildServiceShortcut(
                          context,
                          icon: LucideIcons.zap,
                          label: 'Electricity',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ElectricityScreen()),
                          ),
                        ),
                        _buildServiceShortcut(
                          context,
                          icon: LucideIcons.tv,
                          label: 'Cable TV',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CableTvScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Recent Transactions Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TransactionHistoryScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'See all',
                            style: TextStyle(
                              color: Color(0xFF8C9B0F), // Muted gold/green color
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // List of Transactions (up to 3)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: walletProvider.transactions.length > 3
                          ? 3
                          : walletProvider.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = walletProvider.transactions[index];
                        return _buildTransactionItem(context, tx);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTAButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.accentLime,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textDark, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillSlider(BuildContext context) {
    final list = [
      {'label': 'Fund', 'active': true},
      {'label': 'Transfer', 'active': false},
      {'label': 'Withdraw', 'active': false},
      {'label': 'History', 'active': false},
      {'label': 'Manage', 'active': false},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: list.map((item) {
          final isFund = item['label'] == 'Fund';
          return GestureDetector(
            onTap: () {
              if (item['label'] == 'Fund') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FundWalletScreen()),
                );
              } else if (item['label'] == 'Transfer') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TransferScreen()),
                );
              } else if (item['label'] == 'History') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item['label']} simulation: coming soon!'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isFund ? AppColors.accentLime : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: isFund
                    ? null
                    : Border.all(
                        color: AppColors.textLightGrey.withOpacity(0.3),
                        width: 1,
                      ),
              ),
              child: Row(
                children: [
                  if (item['label'] == 'Manage') ...[
                    Icon(
                      LucideIcons.settings,
                      size: 14,
                      color: isFund ? AppColors.textDark : AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: isFund ? AppColors.textDark : AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServiceShortcut(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA), // Soft grey background
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, color: AppColors.primaryForest, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel tx) {
    final isCredit = tx.amount > 0;
    
    // Choose appropriate icon
    IconData itemIcon = LucideIcons.dollarSign;
    if (tx.title.contains('DSTV') || tx.title.contains('Cable')) {
      itemIcon = LucideIcons.tv;
    } else if (tx.title.contains('Airtime') || tx.title.contains('Data')) {
      itemIcon = LucideIcons.smartphone;
    } else if (tx.title.contains('Electricity')) {
      itemIcon = LucideIcons.zap;
    } else if (tx.title.contains('Funding')) {
      itemIcon = LucideIcons.wallet;
    } else if (tx.title.contains('Transfer')) {
      itemIcon = LucideIcons.send;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA), // Soft off-white container
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCredit 
                  ? AppColors.successGreen.withOpacity(0.1) 
                  : AppColors.accentLime.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              itemIcon,
              color: isCredit ? AppColors.successGreen : AppColors.primaryForest,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tx.date.day}th April, 2025 • ${tx.subtitle}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            (isCredit ? '+' : '-') + CurrencyFormatter.format(tx.amount.abs()),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isCredit ? AppColors.successGreen : AppColors.errorRed,
            ),
          ),
        ],
      ),
    );
  }
}
