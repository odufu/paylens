import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:mspay/features/wallet/presentation/pages/budget_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/airtime_data_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/electricity_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/cable_tv_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/betting_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/waec_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/jamb_screen.dart';
import 'package:mspay/features/dashboard/presentation/pages/main_navigation_holder.dart';
import 'package:mspay/core/presentation/pages/coming_soon_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/airtime_to_cash_screen.dart';
import 'package:mspay/features/auth/presentation/pages/kyc_verification_screen.dart';
import 'package:mspay/features/notifications/presentation/pages/notification_screen.dart';
import 'package:mspay/features/notifications/presentation/state/notification_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _sliderTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startSliderTimer();
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startSliderTimer() {
    _sliderTimer?.cancel();
    _sliderTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final provider = Provider.of<WalletProvider>(context, listen: false);
      final banners = provider.marketingBanners;
      if (banners.isNotEmpty) {
        if (_currentPage < banners.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    if (isDesktop) {
      return _buildDesktopDashboard(context, walletProvider, authProvider, textTheme, isDark);
    }

    final initials = authProvider.userFullName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join()
        .toUpperCase();
    final shortInitials = initials.substring(
      0,
      initials.length > 2 ? 2 : initials.length,
    );

    Widget buildHeaderBlock({bool isPlaceholder = false}) {
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
                                  ? CachedNetworkImage(
                                      imageUrl: authProvider.avatarUrl!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: AppColors.primaryForest,
                                        child: const Center(
                                          child: SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: AppColors.accentLime,
                                            ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
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
                                color: AppColors.textLightGrey.withValues(
                                  alpha: 0.8,
                                ),
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
                    Consumer<NotificationProvider>(
                      builder: (context, notifProvider, child) {
                        final count = notifProvider.unreadCount;
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationScreen(),
                              ),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                child: const Icon(
                                  LucideIcons.bell,
                                  color: AppColors.textLight,
                                  size: 20,
                                ),
                              ),
                              if (count > 0)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.errorRed,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
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
                          color: AppColors.accentLime.withValues(alpha: 0.9),
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
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () =>
                            _showRedeemPointsDialog(context, walletProvider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentLime.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accentLime.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.sparkles,
                                color: AppColors.accentLime,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${walletProvider.loyaltyPoints} LensPoints',
                                style: const TextStyle(
                                  color: AppColors.accentLime,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentLime,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'REDEEM',
                                  style: TextStyle(
                                    color: AppColors.primaryForest,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Fund CTA Button (Centered, Compact Row)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCompactCTAButton(
                      label: 'Fund Wallet',
                      icon: LucideIcons.plus,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FundWalletScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (!walletProvider.kycVerified) ...[
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const KycVerificationScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentLime.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.alertTriangle,
                            color: AppColors.accentLime,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Account Unverified',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Verify your identity (BVN) to activate your virtual bank accounts.',
                                  style: TextStyle(
                                    color: AppColors.textLightGrey.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            color: AppColors.accentLime,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // Your Wallet (Paystack Services)
                // Most Popular Transactions
                isPlaceholder
                    ? const SizedBox(height: 100)
                    : _buildMarketingSlider(context, walletProvider),
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
                  child: buildHeaderBlock(isPlaceholder: true),
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
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).scaffoldBackgroundColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.grey.shade100,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Services',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textGrey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      _buildCircularActionItem(
                                        context,
                                        icon: LucideIcons.lock,
                                        label: 'Budgeting',
                                        color: AppColors.primaryForest,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const BudgetScreen(),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: -4,
                                        right: 2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentLime,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.accentLime
                                                    .withValues(alpha: 0.6),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'NEW',
                                            style: TextStyle(
                                              fontSize: 7,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primaryForest,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  _buildCircularActionItem(
                                    context,
                                    icon: LucideIcons.smartphone,
                                    label: 'Airtime',
                                    color: const Color(0xFF0F9D58),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const AirtimeDataScreen(
                                          isData: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildCircularActionItem(
                                    context,
                                    icon: LucideIcons.barChart2,
                                    label: 'Data',
                                    color: const Color(0xFF4285F4),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const AirtimeDataScreen(
                                          isData: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildCircularActionItem(
                                    context,
                                    icon: LucideIcons.zap,
                                    label: 'Electricity',
                                    color: const Color(0xFFF4B400),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ElectricityScreen(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildCircularActionItem(
                                    context,
                                    icon: LucideIcons.tv,
                                    label: 'Cable TV',
                                    color: const Color(0xFFDB4437),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const CableTvScreen(),
                                      ),
                                    ),
                                  ),
                                  _buildCircularActionItem(
                                    context,
                                    icon: LucideIcons.gamepad2,
                                    label: 'Betting',
                                    color: const Color(0xFF9C27B0),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const BettingScreen(),
                                      ),
                                    ),
                                  ),
                                  _buildCircularActionItem(
                                    context,
                                    icon: LucideIcons.graduationCap,
                                    label: 'WAEC',
                                    color: const Color(0xFF009688),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const WaecScreen(),
                                      ),
                                    ),
                                  ),
                                  _buildCircularActionItem(
                                    context,
                                    icon: LucideIcons.award,
                                    label: 'JAMB',
                                    color: const Color(0xFFFF5722),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const JambScreen(),
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
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(
                                    0xFF161E1A,
                                  ) // Darker card color matching brand
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.grey.shade100,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Transactions',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
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
                                          builder: (_) =>
                                              const TransactionHistoryScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'View All',
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
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
                                itemCount:
                                    walletProvider.transactions.length > 3
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
            buildHeaderBlock(isPlaceholder: false),
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

  void _showRedeemPointsDialog(
    BuildContext context,
    WalletProvider walletProvider,
  ) {
    final pointsController = TextEditingController(
      text: walletProvider.loyaltyPoints.toString(),
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isRedeeming = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Row(
                children: [
                  Icon(LucideIcons.sparkles, color: AppColors.accentLime),
                  SizedBox(width: 10),
                  Text(
                    'Redeem LensPoints',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Convert your loyalty LensPoints directly to wallet cash. 1 LensPoint = ₦1.00 Naira.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryForest.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryForest.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'YOUR BALANCE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textGrey,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${walletProvider.loyaltyPoints} LensPoints',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryForest,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '= ₦${walletProvider.loyaltyPoints}.00 Naira Value',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Points to Redeem',
                        hintText: 'Enter amount of points',
                        prefixIcon: Icon(LucideIcons.sparkles),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter points to redeem';
                        }
                        final int? p = int.tryParse(val.trim());
                        if (p == null || p <= 0) {
                          return 'Enter a valid positive number';
                        }
                        if (p > walletProvider.loyaltyPoints) {
                          return 'Insufficient points balance';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isRedeeming
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isRedeeming || walletProvider.loyaltyPoints <= 0
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            setDialogState(() {
                              isRedeeming = true;
                            });

                            final int points = int.parse(
                              pointsController.text.trim(),
                            );
                            final bool success = await walletProvider
                                .redeemPointsToCash(points);

                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Successfully redeemed $points LensPoints for ₦$points.00!'
                                        : 'Failed to redeem points. Please try again.',
                                  ),
                                  backgroundColor: success
                                      ? AppColors.successGreen
                                      : AppColors.errorRed,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryForest,
                    foregroundColor: Colors.white,
                  ),
                  child: isRedeeming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Convert to Cash'),
                ),
              ],
            );
          },
        );
      },
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
          color: Colors.white.withValues(alpha: 0.08),
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
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(child: Icon(icon, color: color, size: 20)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFF0F4F2)
                    : AppColors.textDark,
                fontWeight: FontWeight.w500,
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
    Color iconBg = AppColors.primaryForest.withValues(alpha: 0.08);
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
        tx.title.toLowerCase().contains('paystack') ||
        tx.title.toLowerCase().contains('monnify') ||
        tx.title.toLowerCase().contains('wema')) {
      itemIcon = LucideIcons.wallet;
      iconBg = AppColors.successGreen.withValues(alpha: 0.1);
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
            ? Colors.white.withValues(alpha: 0.02)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
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
                (isCredit ? '+' : '-') +
                    CurrencyFormatter.format(tx.amount.abs()),
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
                  color: AppColors.successGreen.withValues(alpha: 0.12),
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

  Widget _buildMarketingSlider(
    BuildContext context,
    WalletProvider walletProvider,
  ) {
    final banners = walletProvider.marketingBanners;
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: banners.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final banner = banners[index];
                return GestureDetector(
                  onTap: () => _handleBannerTap(
                    context,
                    banner['action_url'],
                    walletProvider,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: banner['image_url'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.primaryForest,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentLime,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.primaryForest,
                      child: const Center(
                        child: Icon(
                          LucideIcons.wifiOff,
                          color: Colors.white24,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Dot Indicator Overlays
            Positioned(
              bottom: 12,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  banners.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: _currentPage == index
                          ? AppColors.accentLime
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopDashboard(
    BuildContext context,
    WalletProvider walletProvider,
    AuthProvider authProvider,
    TextTheme textTheme,
    bool isDark,
  ) {
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
      backgroundColor: isDark ? const Color(0xFF0C1013) : const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
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
                        ? CachedNetworkImage(
                            imageUrl: authProvider.avatarUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.primaryForest,
                              child: const Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accentLime),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildInitialsAvatar(shortInitials),
                          )
                        : _buildInitialsAvatar(shortInitials),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      authProvider.userFullName,
                      style: textTheme.titleLarge?.copyWith(
                        color: isDark ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Notification Bell
                Consumer<NotificationProvider>(
                  builder: (context, notifProvider, child) {
                    final count = notifProvider.unreadCount;
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationScreen()),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                            ),
                            child: Icon(
                              LucideIcons.bell,
                              color: isDark ? Colors.white : AppColors.textDark,
                              size: 20,
                            ),
                          ),
                          if (count > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppColors.errorRed, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column (flex: 3)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wallet Card
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF003D26), Color(0xFF002214)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TOTAL WALLET BALANCE',
                                      style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          walletProvider.isBalanceVisible
                                              ? '₦${CurrencyFormatter.format(walletProvider.balance)}'
                                              : '₦ ••••••••',
                                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: walletProvider.toggleBalanceVisibility,
                                          child: Icon(
                                            walletProvider.isBalanceVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                                            color: AppColors.accentLime,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // LensPoints Badge
                                GestureDetector(
                                  onTap: () => _showRedeemPointsDialog(context, walletProvider),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentLime.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.sparkles, color: AppColors.accentLime, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${walletProvider.loyaltyPoints} LensPoints',
                                          style: const TextStyle(color: AppColors.accentLime, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Virtual Accounts Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildDesktopVirtualAccountCard(
                                    bankName: 'WEMA BANK (DEDICATED)',
                                    accountNumber: walletProvider.wemaAccountNumber,
                                    isVerified: walletProvider.kycVerified,
                                    textTheme: textTheme,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDesktopVirtualAccountCard(
                                    bankName: 'STERLING BANK',
                                    accountNumber: walletProvider.sterlingAccountNumber,
                                    isVerified: walletProvider.kycVerified,
                                    textTheme: textTheme,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Actions Row
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.findAncestorStateOfType<MainNavigationHolderState>()?.onTabSelected(2);
                                  },
                                  icon: const Icon(LucideIcons.plus, size: 16),
                                  label: const Text('Fund Wallet'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentLime,
                                    foregroundColor: AppColors.primaryForest,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const TransferScreen()),
                                    );
                                  },
                                  icon: const Icon(LucideIcons.send, size: 16),
                                  label: const Text('Send Money'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white10,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Services Grid
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161E1A) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Utility Services Vending',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                            ),
                            const SizedBox(height: 20),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 4,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.15,
                              children: [
                                _buildCircularActionItem(
                                  context,
                                  icon: LucideIcons.lock,
                                  label: 'Budgeting',
                                  color: AppColors.primaryForest,
                                  onTap: () => context.findAncestorStateOfType<MainNavigationHolderState>()?.onTabSelected(1),
                                ),
                                _buildCircularActionItem(
                                  context,
                                  icon: LucideIcons.smartphone,
                                  label: 'Airtime',
                                  color: const Color(0xFF0F9D58),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const AirtimeDataScreen(isData: false)),
                                  ),
                                ),
                                _buildCircularActionItem(
                                  context,
                                  icon: LucideIcons.barChart2,
                                  label: 'Data',
                                  color: const Color(0xFF4285F4),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const AirtimeDataScreen(isData: true)),
                                  ),
                                ),
                                _buildCircularActionItem(
                                  context,
                                  icon: LucideIcons.zap,
                                  label: 'Electricity',
                                  color: const Color(0xFFF4B400),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ElectricityScreen()),
                                  ),
                                ),
                                _buildCircularActionItem(
                                  context,
                                  icon: LucideIcons.tv,
                                  label: 'Cable TV',
                                  color: const Color(0xFFDB4437),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const CableTvScreen()),
                                  ),
                                ),
                                _buildCircularActionItem(
                                  context,
                                  icon: LucideIcons.gamepad2,
                                  label: 'Betting',
                                  color: const Color(0xFF9C27B0),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const BettingScreen()),
                                  ),
                                ),
                                _buildCircularActionItem(
                                  context,
                                  icon: LucideIcons.graduationCap,
                                  label: 'WAEC',
                                  color: const Color(0xFF009688),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const WaecScreen()),
                                  ),
                                ),
                                _buildCircularActionItem(
                                  context,
                                  icon: LucideIcons.award,
                                  label: 'JAMB',
                                  color: const Color(0xFFFF5722),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const JambScreen()),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column (flex: 2)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KYC Notice
                      if (!walletProvider.kycVerified) ...[
                        _buildDesktopKycAlert(context),
                        const SizedBox(height: 24),
                      ],
                      // Banners Slider
                      const Text(
                        'Campaigns & Updates',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 12),
                      _buildMarketingSlider(context, walletProvider),
                      const SizedBox(height: 24),
                      // Transactions Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161E1A) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Transactions',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    context.findAncestorStateOfType<MainNavigationHolderState>()?.onTabSelected(3);
                                  },
                                  child: const Text(
                                    'View All',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryForest),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (walletProvider.transactions.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32.0),
                                  child: Text('No transactions yet.', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: walletProvider.transactions.length > 5 ? 5 : walletProvider.transactions.length,
                                separatorBuilder: (_, __) => const Divider(height: 20, thickness: 1, color: Colors.white10),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopVirtualAccountCard({
    required String bankName,
    required String accountNumber,
    required bool isVerified,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bankName,
            style: const TextStyle(color: AppColors.accentLime, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            accountNumber,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            isVerified ? 'Active & Funded' : 'Action Required',
            style: TextStyle(color: isVerified ? Colors.white54 : Colors.orangeAccent, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopKycAlert(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const KycVerificationScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AppColors.errorRed, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identity Verification Pending (KYC)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.errorRed),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Click here to complete BVN verification to activate transfer virtual bank accounts.',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: AppColors.errorRed, size: 18),
          ],
        ),
      ),
    );
  }

  void _handleBannerTap(
    BuildContext context,
    String? actionUrl,
    WalletProvider walletProvider,
  ) {
    if (actionUrl == null || actionUrl.isEmpty) return;

    if (actionUrl.startsWith('/budgeting') || actionUrl.startsWith('/budget')) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BudgetScreen()));
    } else if (actionUrl.startsWith('/transfers') ||
        actionUrl.startsWith('/transfer')) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const TransferScreen()));
    } else if (actionUrl.startsWith('/loyalty') ||
        actionUrl.startsWith('/redeem')) {
      _showRedeemPointsDialog(context, walletProvider);
    }
  }
}
