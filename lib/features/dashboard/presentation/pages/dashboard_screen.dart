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
import 'package:mspay/features/dashboard/presentation/pages/main_navigation_holder.dart';
import 'package:mspay/core/presentation/pages/coming_soon_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/airtime_to_cash_screen.dart';

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

    Widget buildHeaderBlock() {
      return Container(
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
                        GestureDetector(
                          onTap: () {
                            context
                                .findAncestorStateOfType<
                                  MainNavigationHolderState
                                >()
                                ?.onTabSelected(4);
                          },
                          child: Container(
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
                const SizedBox(height: 18),

                // Wallet Balance Display (Centered, Minimal)
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
                      const SizedBox(height: 4),
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
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: walletProvider.toggleBalanceVisibility,
                            child: Icon(
                              walletProvider.isBalanceVisible
                                  ? LucideIcons.eye
                                  : LucideIcons.eyeOff,
                              color: AppColors.accentLime,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Fund/Send CTA Buttons (Centered, Compact Row)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCompactCTAButton(
                      label: 'Fund',
                      icon: LucideIcons.plus,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FundWalletScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildCompactCTAButton(
                      label: 'Send',
                      icon: LucideIcons.send,
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
                const SizedBox(height: 18),

                // Your Wallet (Monnify Services)
                // Most Popular Transactions
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
                        'Most Popular Transactions',
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
                            _buildPopularTransactionPill(
                              label: 'MTN SME 1GB',
                              icon: LucideIcons.smartphone,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AirtimeDataScreen(
                                    isData: true,
                                    initialProvider: 'MTN',
                                  ),
                                ),
                              ),
                            ),
                            _buildPopularTransactionPill(
                              label: 'Airtel CG 1.5GB',
                              icon: LucideIcons.smartphone,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AirtimeDataScreen(
                                    isData: true,
                                    initialProvider: 'Airtel',
                                  ),
                                ),
                              ),
                            ),
                            _buildPopularTransactionPill(
                              label: 'Glo SME 2GB',
                              icon: LucideIcons.smartphone,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AirtimeDataScreen(
                                    isData: true,
                                    initialProvider: 'Glo',
                                  ),
                                ),
                              ),
                            ),
                            _buildPopularTransactionPill(
                              label: 'IKEDC Prepaid',
                              icon: LucideIcons.zap,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ElectricityScreen(),
                                ),
                              ),
                            ),
                            _buildPopularTransactionPill(
                              label: 'GOTV Max',
                              icon: LucideIcons.tv,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CableTvScreen(),
                                ),
                              ),
                            ),
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
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: buildHeaderBlock(),
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
                        // Utility Services Section Header
                        // Text(
                        //   'Utility Services',
                        // Circular VTpass Services Shortcuts Card (Grid of 8 items in 2 rows)
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).scaffoldBackgroundColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.grey.shade100,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 8,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildCircularActionItem(
                                    context,
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
                                    context,
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
                                    context,
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
                                    context,
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF161E1A) // Darker card color matching brand
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.grey.shade100,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Transactions',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white60
                                          : Colors.grey.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const TransactionHistoryScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'View All',
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white60
                                            : Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
            buildHeaderBlock(),
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

  Widget _buildCompactCTAButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accentLime,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primaryForest),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryForest,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularTransactionPill({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.accentLime, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentLime,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentLime.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.primaryForest, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFF0F4F2)
                    : AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.02)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(itemIcon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tx.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFF0F4F2)
                        : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${tx.date.day}th April • ${tx.subtitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (isCredit ? '+' : '-') + CurrencyFormatter.format(tx.amount.abs()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Successful',
                  style: TextStyle(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
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
