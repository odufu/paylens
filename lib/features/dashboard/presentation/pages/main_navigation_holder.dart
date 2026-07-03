import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:mspay/features/wallet/presentation/pages/fund_wallet_screen.dart';
import 'package:mspay/features/wallet/presentation/pages/transfer_screen.dart';
import 'package:mspay/features/wallet/presentation/pages/transaction_history_screen.dart';
import 'package:mspay/features/chatbot/presentation/pages/chatbot_screen.dart';
import 'package:mspay/features/profile/presentation/pages/profile_screen.dart';
import 'package:mspay/core/presentation/pages/coming_soon_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/airtime_to_cash_screen.dart';

class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => MainNavigationHolderState();
}

class MainNavigationHolderState extends State<MainNavigationHolder> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardScreen(),
      const FundWalletScreen(), // Wallet tab displays Monify Virtual Accounts details
      const AirtimeToCashScreen(), // Center tab displays the app USP
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
              child: const Icon(
                LucideIcons.messageSquare,
                color: AppColors.accentLime,
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
                color: Colors.black.withOpacity(0.2),
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
                _buildNavItem(1, LucideIcons.wallet, 'Wallet'),
                _buildCenterSendButton(),
                _buildNavItem(3, LucideIcons.history, 'History'),
                _buildNavItem(4, LucideIcons.user, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
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
            color: isActive ? AppColors.accentLime : AppColors.textLightGrey.withOpacity(0.6),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? AppColors.accentLime : AppColors.textLightGrey.withOpacity(0.6),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterSendButton() {
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
                color: AppColors.accentLime.withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: const Center(
            child: Icon(
              LucideIcons.repeat,
              color: Color(0xFF022E1F),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}


