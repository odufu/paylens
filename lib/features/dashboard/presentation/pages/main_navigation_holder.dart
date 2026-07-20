import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/features/auth/presentation/state/auth_provider.dart';
import 'package:mspay/features/profile/presentation/pages/admin_console_screen.dart';
import 'package:mspay/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:mspay/features/wallet/presentation/pages/fund_wallet_screen.dart';
import 'package:mspay/features/wallet/presentation/pages/budget_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/airtime_data_screen.dart';
import 'package:mspay/features/wallet/presentation/pages/transaction_history_screen.dart';
import 'package:mspay/features/chatbot/presentation/pages/chatbot_screen.dart';
import 'package:mspay/features/profile/presentation/pages/profile_screen.dart';
import 'package:mspay/core/presentation/pages/coming_soon_screen.dart';
import 'package:mspay/features/chatbot/presentation/state/chat_provider.dart';

class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => MainNavigationHolderState();
}

class MainNavigationHolderState extends State<MainNavigationHolder> {
  int _currentIndex = 0;
  bool _isSideNavCollapsed = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardScreen(),
      const BudgetScreen(), // Budgeting tab
      const FundWalletScreen(), // Center tab displays Fund Wallet
      const TransactionHistoryScreen(), // Services/History tab (using History for detail here)
      const ProfileScreen(),            // Profile Screen
    ];
  }

  void onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    if (isDesktop) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C1013) : const Color(0xFFF8F9FA),
          ),
          child: Row(
            children: [
              // Collapsable Desktop Side Nav
              _buildDesktopSideNav(context, isDark, textTheme, authProvider),
              // Vertical Divider line
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
              ),
              // Active Sub-page Content
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile Viewport (Original layout)
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // Floating Action Button (FAB) or Support FAB for Chatbot
      floatingActionButton: _currentIndex != 2 && _currentIndex != 1 
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                );
              },
              backgroundColor: AppColors.primaryForest,
              child: Badge(
                isLabelVisible: chatProvider.hasUnreadMessages,
                backgroundColor: AppColors.errorRed,
                child: const Icon(
                  LucideIcons.messageSquare,
                  color: AppColors.accentLime,
                ),
              ),
            )
          : null,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 72,
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF022E1F), // Extra deep forest green
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.home, 'Home'),
                _buildNavItem(1, LucideIcons.lock, 'Budgeting'),
                _buildCenterFundButton(),
                _buildNavItem(3, LucideIcons.history, 'History'),
                _buildNavItem(4, LucideIcons.user, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSideNav(BuildContext context, bool isDark, TextTheme textTheme, AuthProvider authProvider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: _isSideNavCollapsed ? 76 : 240,
      color: isDark ? const Color(0xFF13191B) : AppColors.primaryForest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Logo
          Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0, bottom: 20.0),
            child: Row(
              mainAxisAlignment: _isSideNavCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                if (!_isSideNavCollapsed) ...[
                  const Icon(LucideIcons.wallet, color: AppColors.accentLime, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'PAYLENSES',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ] else
                  const Icon(LucideIcons.wallet, color: AppColors.accentLime, size: 24),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Colors.white12),
          const SizedBox(height: 16),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildDesktopSideNavItem(
                  index: 0,
                  icon: LucideIcons.home,
                  label: 'Home Dashboard',
                  isActive: _currentIndex == 0,
                  isDark: isDark,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 8),
                _buildDesktopSideNavItem(
                  index: 1,
                  icon: LucideIcons.lock,
                  label: 'Budget Pool',
                  isActive: _currentIndex == 1,
                  isDark: isDark,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 8),
                _buildDesktopSideNavItem(
                  index: 2,
                  icon: LucideIcons.plusCircle,
                  label: 'Fund Wallet',
                  isActive: _currentIndex == 2,
                  isDark: isDark,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 8),
                _buildDesktopSideNavItem(
                  index: 3,
                  icon: LucideIcons.history,
                  label: 'Vending History',
                  isActive: _currentIndex == 3,
                  isDark: isDark,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 8),
                _buildDesktopSideNavItem(
                  index: 4,
                  icon: LucideIcons.user,
                  label: 'User Profile',
                  isActive: _currentIndex == 4,
                  isDark: isDark,
                  textTheme: textTheme,
                ),

                // Admin Console link if user is an admin
                if (authProvider.isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1, thickness: 1, color: Colors.white12),
                  ),
                  _buildDesktopSideNavItem(
                    index: -2, // Unique index trigger
                    icon: LucideIcons.shieldCheck,
                    label: 'Admin Console',
                    isActive: false,
                    isDark: isDark,
                    textTheme: textTheme,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminConsoleScreen()),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          // Collapse/Expand toggle at bottom
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                _buildDesktopSideNavItem(
                  index: -3,
                  icon: LucideIcons.messageSquare,
                  label: 'Ask AI Chatbot',
                  isActive: false,
                  isDark: isDark,
                  textTheme: textTheme,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isSideNavCollapsed = !_isSideNavCollapsed;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        _isSideNavCollapsed ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSideNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDark,
    required TextTheme textTheme,
    VoidCallback? onTap,
  }) {
    final activeBgColor = isDark ? AppColors.primaryForest : Colors.white;
    final activeTextColor = isDark ? Colors.white : AppColors.primaryForest;
    final inactiveTextColor = Colors.white.withValues(alpha: 0.7);

    final Widget child = InkWell(
      onTap: onTap ?? () => onTabSelected(index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: _isSideNavCollapsed ? 0 : 16),
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: _isSideNavCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isActive ? activeTextColor : inactiveTextColor,
              size: 20,
            ),
            if (!_isSideNavCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isActive ? activeTextColor : inactiveTextColor,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (_isSideNavCollapsed) {
      return Tooltip(
        message: label,
        child: child,
      );
    }

    return child;
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.accentLime : AppColors.textLightGrey.withValues(alpha: 0.6),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? AppColors.accentLime : AppColors.textLightGrey.withValues(alpha: 0.6),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterFundButton() {
    return GestureDetector(
      onTap: () => onTabSelected(2),
      child: Transform.translate(
        offset: const Offset(0, -6),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.accentLime,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF022E1F),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentLime.withValues(alpha: 0.3),
                blurRadius: 6,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: const Center(
            child: Icon(
              LucideIcons.wallet,
              color: Color(0xFF022E1F),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}


