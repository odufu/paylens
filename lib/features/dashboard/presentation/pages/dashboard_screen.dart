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
    final shortInitials = initials.substring(
      0,
      initials.length > 2 ? 2 : initials.length,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // FOREST GREEN CURVED HEADER BLOCK
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: const Color(0xFF003D26),
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
                      // Hello Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.accentLime,
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: authProvider.avatarUrl != null
                                      ? Image.network(
                                          authProvider.avatarUrl!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _buildInitialsAvatar(
                                                    shortInitials,
                                                  ),
                                        )
                                      : _buildInitialsAvatar(shortInitials),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello,',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textLightGrey
                                          .withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    authProvider.userFullName.split(' ').first,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Notification Bell
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                            child: const Icon(
                              LucideIcons.bell,
                              color: AppColors.textLight,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Wallet Balance Display
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Your Wallet Balance',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.accentLime.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  walletProvider.isBalanceVisible
                                      ? CurrencyFormatter.format(
                                          walletProvider.balance,
                                        )
                                      : '₦ ••••••••',
                                  style: textTheme.headlineMedium?.copyWith(
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 32,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: walletProvider.toggleBalanceVisibility,
                                  child: Icon(
                                    walletProvider.isBalanceVisible
                                        ? LucideIcons.eye
                                        : LucideIcons.eyeOff,
                                    color: AppColors.accentLime,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Centered Fund & Send buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCenteredCTAButton(
                            label: 'Fund',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FundWalletScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          _buildCenteredCTAButton(
                            label: 'Send',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TransferScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Your Wallet (Monnify Services)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryForest, // Darker green card
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Wallet (Monnify)',
                              style: TextStyle(
                                color: AppColors.textLightGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildWalletCurrencyPill(
                                    label: 'Wema Bank',
                                    isActive: true,
                                  ),
                                  _buildWalletCurrencyPill(
                                    label: 'Card Payment',
                                    isActive: false,
                                  ),
                                  _buildWalletCurrencyPill(
                                    label: 'Bank Transfer',
                                    isActive: false,
                                  ),
                                  _buildAddWalletButton(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular VTpass Services Shortcuts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCircularActionItem(
                          icon: LucideIcons.smartphone,
                          label: 'Airtime',
                          color: Colors.green.shade400,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AirtimeDataScreen(isData: false),
                            ),
                          ),
                        ),
                        _buildCircularActionItem(
                          icon: LucideIcons.barChart2,
                          label: 'Data',
                          color: Colors.red.shade400,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AirtimeDataScreen(isData: true),
                            ),
                          ),
                        ),
                        _buildCircularActionItem(
                          icon: LucideIcons.zap,
                          label: 'Electricity',
                          color: Colors.blue.shade400,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ElectricityScreen(),
                            ),
                          ),
                        ),
                        _buildCircularActionItem(
                          icon: LucideIcons.tv,
                          label: 'Cable TV',
                          color: Colors.orange.shade400,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CableTvScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

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
                                builder: (_) =>
                                    const TransactionHistoryScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'See all',
                            style: TextStyle(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // List of Transactions (No scrolling)
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

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      color: Colors.white24,
      alignment: Alignment.center,
      child: Text(
        initials.isNotEmpty ? initials : 'DN',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.accentLime,
        ),
      ),
    );
  }

  Widget _buildCenteredCTAButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accentLime,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryForest,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCurrencyPill({
    required String label,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.accentLime : Colors.transparent,
        border: isActive ? null : Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? AppColors.primaryForest : Colors.white,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAddWalletButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.add, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'Add Wallet',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularActionItem({
    required IconData icon,
    required String label,
    required Color color,
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
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 24),
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

    // Dynamically choose visual style to feel premium (Spotify, GoDaddy, MTN style colors)
    IconData itemIcon = LucideIcons.dollarSign;
    Color iconBg = AppColors.primaryForest.withOpacity(0.08);
    Color iconColor = AppColors.primaryForest;

    if (tx.title.toLowerCase().contains('spotify')) {
      itemIcon = LucideIcons.music;
      iconBg = const Color(0xFFE8F5E9);
      iconColor = const Color(0xFF4CAF50);
    } else if (tx.title.toLowerCase().contains('purchase') ||
        tx.title.toLowerCase().contains('godaddy')) {
      itemIcon = LucideIcons.globe;
      iconBg = const Color(0xFFE1F5FE);
      iconColor = const Color(0xFF03A9F4);
    } else if (tx.title.toLowerCase().contains('top-up') ||
        tx.title.toLowerCase().contains('mtn')) {
      itemIcon = LucideIcons.phone;
      iconBg = const Color(0xFFFFFDE7);
      iconColor = const Color(0xFFFBC02D);
    } else if (tx.title.toLowerCase().contains('funding') ||
        tx.title.toLowerCase().contains('monnify') ||
        tx.title.toLowerCase().contains('wema')) {
      itemIcon = LucideIcons.wallet;
      iconBg = AppColors.successGreen.withOpacity(0.1);
      iconColor = AppColors.successGreen;
    } else if (tx.title.toLowerCase().contains('transfer')) {
      itemIcon = LucideIcons.send;
      iconBg = const Color(0xFFECEFF1);
      iconColor = const Color(0xFF607D8B);
    } else if (tx.title.toLowerCase().contains('tv') ||
        tx.title.toLowerCase().contains('dstv') ||
        tx.title.toLowerCase().contains('cable')) {
      itemIcon = LucideIcons.tv;
      iconBg = const Color(0xFFF3E5F5);
      iconColor = const Color(0xFF9C27B0);
    } else if (tx.title.toLowerCase().contains('electricity') ||
        tx.title.toLowerCase().contains('power')) {
      itemIcon = LucideIcons.zap;
      iconBg = const Color(0xFFFFF3E0);
      iconColor = const Color(0xFFFF9800);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(itemIcon, color: iconColor, size: 22),
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
