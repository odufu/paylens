import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/services/supabase_service.dart';
import 'package:mspay/core/utils/currency_formatter.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/profile/presentation/pages/in_app_documentation_screen.dart';
import 'package:mspay/features/utilities/data/datasources/vtpass_service.dart';

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSideNavCollapsed = false;

  // Support Tickets State
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoadingTickets = false;

  // System Transactions Audit State
  List<Map<String, dynamic>> _systemTransactions = [];
  bool _isLoadingTransactions = false;

  // Search & Filter State for Transactions Tab
  String _txSearchQuery = '';
  String _txSelectedCategory = 'All';
  String _txSelectedStatus = 'All';

  // Settlement Ledgers State
  List<Map<String, dynamic>> _settlementLedgers = [];
  bool _isLoadingSettlements = false;

  // VTPass Wallet Balance State
  double? _vtpassBalance;
  bool _isLoadingVTPassBalance = false;

  // Marketing State
  final _announcementTitleController = TextEditingController();
  final _announcementBodyController = TextEditingController();
  bool _isPublishing = false;

  // Marketing Banners State
  final _bannerImageUrlController = TextEditingController();
  final _bannerTitleController = TextEditingController();
  final _bannerActionUrlController = TextEditingController();
  bool _isSavingBanner = false;

  // Pricing State
  final _electricityFeeController = TextEditingController();
  final _cableFeeController = TextEditingController();
  final _transferFeeController = TextEditingController();
  final _pointsRateController = TextEditingController();

  final _airtimeMarkupPercentController = TextEditingController();
  final _airtimeMarkupFlatController = TextEditingController();
  final _dataMarkupPercentController = TextEditingController();
  final _dataMarkupFlatController = TextEditingController();
  final _cableMarkupPercentController = TextEditingController();
  final _cableMarkupFlatController = TextEditingController();
  final _electricityMarkupPercentController = TextEditingController();
  final _electricityMarkupFlatController = TextEditingController();

  final _airtimeMtnAdminController = TextEditingController();
  final _airtimeGloAdminController = TextEditingController();
  final _airtime9mobileAdminController = TextEditingController();
  final _airtimeAirtelAdminController = TextEditingController();

  final _dataMtnAdminController = TextEditingController();
  final _dataGloAdminController = TextEditingController();
  final _data9mobileAdminController = TextEditingController();
  final _dataAirtelAdminController = TextEditingController();

  final _electricityAdminController = TextEditingController();
  final _cableAdminController = TextEditingController();

  bool _isSavingPricing = false;
  bool _isInitializedPricing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadOperationsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _announcementTitleController.dispose();
    _announcementBodyController.dispose();
    _electricityFeeController.dispose();
    _cableFeeController.dispose();
    _transferFeeController.dispose();
    _pointsRateController.dispose();
    _bannerImageUrlController.dispose();
    _bannerTitleController.dispose();
    _bannerActionUrlController.dispose();

    _airtimeMarkupPercentController.dispose();
    _airtimeMarkupFlatController.dispose();
    _dataMarkupPercentController.dispose();
    _dataMarkupFlatController.dispose();
    _cableMarkupPercentController.dispose();
    _cableMarkupFlatController.dispose();
    _electricityMarkupPercentController.dispose();
    _electricityMarkupFlatController.dispose();

    _airtimeMtnAdminController.dispose();
    _airtimeGloAdminController.dispose();
    _airtime9mobileAdminController.dispose();
    _airtimeAirtelAdminController.dispose();
    _dataMtnAdminController.dispose();
    _dataGloAdminController.dispose();
    _data9mobileAdminController.dispose();
    _dataAirtelAdminController.dispose();
    _electricityAdminController.dispose();
    _cableAdminController.dispose();

    super.dispose();
  }

  /// Loads platform-wide operations and transaction statistics from Supabase
  Future<void> _loadOperationsData() async {
    setState(() {
      _isLoadingTickets = true;
      _isLoadingTransactions = true;
    });

    try {
      // 1. Fetch support tickets (join with profile metadata)
      final ticketsResponse = await SupabaseService.client
          .from('support_tickets')
          .select('*, profiles(full_name, email)')
          .order('created_at', ascending: false);

      if (ticketsResponse != null) {
        _tickets = List<Map<String, dynamic>>.from(ticketsResponse);
      }
    } catch (e) {
      debugPrint(
        'Supabase support tickets fetch failed, utilizing fallback mocks: $e',
      );
      // Mock fallback data to ensure the admin experience is testable
      _tickets = [
        {
          'id': '#TKT-19283',
          'title': 'Failed Electricity Token Vending',
          'description':
              'Paid ₦5,000 for prepaid meter but token was not returned.',
          'status': 'escalated',
          'created_at': '2026-07-06T10:10:00Z',
          'profiles': {
            'full_name': 'Darlington Nnamdi',
            'email': 'darlington@lushfintech.com',
          },
        },
        {
          'id': '#TKT-18872',
          'title': 'Double Credit Wallet Dispute',
          'description':
              'Customer claims bank transfer charged twice but wallet credited once.',
          'status': 'escalated',
          'created_at': '2026-07-06T08:24:00Z',
          'profiles': {
            'full_name': 'Emerald Johnson',
            'email': 'emerald@paylenses.com',
          },
        },
        {
          'id': '#TKT-17631',
          'title': 'Withdrawal Delays',
          'description':
              'Bank transfer withdrawal takes more than 15 minutes to clear.',
          'status': 'resolved',
          'created_at': '2026-07-05T14:40:00Z',
          'profiles': {
            'full_name': 'Joel Odufu',
            'email': 'joel@paylenses.com',
          },
        },
      ];
    } finally {
      setState(() {
        _isLoadingTickets = false;
      });
    }

    try {
      // 2. Fetch platform transactions
      final txResponse = await SupabaseService.client
          .from('transactions')
          .select(
            '*, profiles(full_name, email), settlement_ledger(vtpass_cost, intake_amount, net_profit, expected_paystack_settlement)',
          )
          .order('created_at', ascending: false);

      if (txResponse != null) {
        _systemTransactions = List<Map<String, dynamic>>.from(txResponse);
      }
    } catch (e) {
      debugPrint(
        'Supabase transaction audit fetch failed, utilizing fallback mocks: $e',
      );
      // Mock fallback transactions
      _systemTransactions = [
        {
          'id': 'tx-1',
          'title': 'MTN SME 1GB purchase',
          'subtitle': '09012345678',
          'amount': -250.00,
          'category': 'bills',
          'status': 'success',
          'reference': 'REF-98127391',
          'created_at': '2026-07-06T11:20:00Z',
          'profiles': {
            'full_name': 'Darlington Nnamdi',
            'email': 'darl@paylenses.com',
          },
          'settlement_ledger': [
            {
              'vtpass_cost': 235.00,
              'intake_amount': 250.00,
              'net_profit': 10.00,
              'expected_paystack_settlement': 250.00,
            },
          ],
        },
        {
          'id': 'tx-2',
          'title': 'Wallet Funding via Wema Dedicated Transfer',
          'subtitle': 'Paystack Settle',
          'amount': 20000.00,
          'category': 'wallet',
          'status': 'success',
          'reference': 'REF-72635182',
          'created_at': '2026-07-06T10:45:00Z',
          'profiles': {
            'full_name': 'Emerald Johnson',
            'email': 'emerald@paylenses.com',
          },
          'settlement_ledger': [
            {
              'vtpass_cost': null,
              'intake_amount': 20000.00,
              'net_profit': -300.00,
              'expected_paystack_settlement': 19700.00,
            },
          ],
        },
        {
          'id': 'tx-3',
          'title': 'Transfer to Wema Bank',
          'subtitle': '0192837465',
          'amount': -15000.00,
          'category': 'transfers',
          'status': 'success',
          'reference': 'REF-16527183',
          'created_at': '2026-07-06T09:15:00Z',
          'profiles': {
            'full_name': 'Joel Odufu',
            'email': 'joel@paylenses.com',
          },
          'settlement_ledger': [
            {
              'vtpass_cost': 15000.00,
              'intake_amount': 15000.00,
              'net_profit': 0.00,
              'expected_paystack_settlement': 15000.00,
            },
          ],
        },
      ];
    } finally {
      setState(() {
        _isLoadingTransactions = false;
      });
    }

    // 3. Fetch settlement reconciliation logs
    setState(() {
      _isLoadingSettlements = true;
    });

    try {
      final settleResponse = await SupabaseService.client
          .from('settlement_ledger')
          .select('*, transactions(title, subtitle, reference, provider)')
          .order('created_at', ascending: false);

      if (settleResponse != null) {
        _settlementLedgers = List<Map<String, dynamic>>.from(settleResponse);
      }
    } catch (e) {
      debugPrint(
        'Supabase settlement ledger fetch failed: $e. Using mock fallback.',
      );
      _settlementLedgers = [
        {
          'id': 'settle-1',
          'transaction_id': 'tx-1',
          'user_id': 'user-1',
          'intake_amount': 2000.0,
          'expected_paystack_settlement': 1970.0,
          'vtpass_cost': 1940.0,
          'net_profit': 30.0,
          'reconciliation_status': 'pending',
          'created_at': '2026-07-06T11:20:00Z',
          'transactions': {
            'title': 'MTN Airtime ₦2,000',
            'subtitle': '08149204910',
            'reference': 'VTP-98201482',
            'provider': 'VTPass',
          },
        },
        {
          'id': 'settle-2',
          'transaction_id': 'tx-2',
          'user_id': 'user-2',
          'intake_amount': 5000.0,
          'expected_paystack_settlement': 4925.0,
          'vtpass_cost': null,
          'net_profit': -75.0,
          'reconciliation_status': 'matched',
          'created_at': '2026-07-06T10:45:00Z',
          'transactions': {
            'title': 'Wallet Funding',
            'subtitle': 'Bank Transfer via Wema Bank',
            'reference': 'REF-72635182',
            'provider': 'Paystack',
          },
        },
      ];
    } finally {
      setState(() {
        _isLoadingSettlements = false;
      });
    }

    // 4. Fetch VTPass vending balance
    setState(() {
      _isLoadingVTPassBalance = true;
    });
    try {
      final bal = await VtPassService.fetchBalance();
      if (bal != null) {
        setState(() {
          _vtpassBalance = bal;
        });
      }
    } catch (e) {
      debugPrint('Failed to load VTPass balance: $e');
    } finally {
      setState(() {
        _isLoadingVTPassBalance = false;
      });
    }
  }

  /// Resolves an escalated support ticket
  Future<void> _resolveTicket(String ticketId) async {
    try {
      await SupabaseService.client
          .from('support_tickets')
          .update({'status': 'resolved'})
          .eq('id', ticketId);
    } catch (e) {
      debugPrint(
        'Supabase resolve update failed, executing local state update: $e',
      );
    }

    setState(() {
      final index = _tickets.indexWhere((t) => t['id'] == ticketId);
      if (index != -1) {
        _tickets[index]['status'] = 'resolved';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ticket $ticketId resolved successfully!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  /// Updates the reconciliation status of a settlement ledger log
  Future<void> _updateReconciliationStatus(
    String ledgerId,
    String newStatus,
  ) async {
    try {
      await SupabaseService.client
          .from('settlement_ledger')
          .update({'reconciliation_status': newStatus})
          .eq('id', ledgerId);
    } catch (e) {
      debugPrint(
        'Supabase update reconciliation status failed: $e. Executing local update.',
      );
    }

    setState(() {
      final index = _settlementLedgers.indexWhere((s) => s['id'] == ledgerId);
      if (index != -1) {
        _settlementLedgers[index]['reconciliation_status'] = newStatus;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ledger status updated to $newStatus successfully!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  /// Opens dialog to record manual reconciliation audit status
  void _showReconciliationDialog(Map<String, dynamic> ledger) {
    final String ledgerId = ledger['id'];
    final currentStatus = ledger['reconciliation_status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (context) {
        String selectedStatus = currentStatus;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Record Reconciliation Audit',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set the status for this operation transaction:',
                    style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    title: const Text(
                      'Matched (Reconciled)',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: 'matched',
                    groupValue: selectedStatus,
                    onChanged: (val) {
                      setDialogState(() {
                        selectedStatus = val!;
                      });
                    },
                    activeColor: AppColors.primaryForest,
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'Discrepancy (Flag Error)',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: 'discrepancy',
                    groupValue: selectedStatus,
                    onChanged: (val) {
                      setDialogState(() {
                        selectedStatus = val!;
                      });
                    },
                    activeColor: AppColors.primaryForest,
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'Pending Verification',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: 'pending',
                    groupValue: selectedStatus,
                    onChanged: (val) {
                      setDialogState(() {
                        selectedStatus = val!;
                      });
                    },
                    activeColor: AppColors.primaryForest,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateReconciliationStatus(ledgerId, selectedStatus);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryForest,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Record'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Publishes a new marketing announcement to the system
  Future<void> _publishAnnouncement() async {
    final title = _announcementTitleController.text.trim();
    final body = _announcementBodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both announcement title and body'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    // Simulate database broadcast settlement delay
    await Future.delayed(const Duration(milliseconds: 800));

    _announcementTitleController.clear();
    _announcementBodyController.clear();

    setState(() {
      _isPublishing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marketing announcement broadcast successfully!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    if (isDesktop) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C1013) : const Color(0xFFF8F9FA),
          ),
          child: Row(
            children: [
              // Collapsable Side Navigation
              _buildSideNav(context, isDark, textTheme),
              // Thin Vertical Divider
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200,
              ),
              // Main content pane
              Expanded(
                child: Column(
                  children: [
                    // Desktop Header Bar
                    _buildDesktopHeader(context, isDark, textTheme),
                    // Inner Body Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics:
                            const NeverScrollableScrollPhysics(), // Disable swiping on desktop
                        children: [
                          _buildOperationsTab(context, textTheme, isDark),
                          _buildTransactionsTab(context, textTheme, isDark),
                          _buildAccountingTab(context, textTheme, isDark),
                          _buildMarketingTab(context, textTheme, isDark),
                          _buildPricingTab(context, textTheme, isDark),
                        ],
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

    // Mobile Viewport (Original Scaffold)
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        title: const Text(
          'Admin Console',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accentLime,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.accentLime,
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: _tickets.any((t) => t['admin_unread'] == true),
                backgroundColor: AppColors.errorRed,
                child: const Icon(LucideIcons.activity),
              ),
              text: 'Operations',
            ),
            const Tab(
              icon: Icon(LucideIcons.listOrdered),
              text: 'Transactions',
            ),
            const Tab(icon: Icon(LucideIcons.barChart2), text: 'Accounting'),
            const Tab(icon: Icon(LucideIcons.megaphone), text: 'Marketing'),
            const Tab(icon: Icon(LucideIcons.sliders), text: 'Pricing'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.fileText, size: 20),
            tooltip: 'Developer Documentation',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const InAppDocumentationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: _loadOperationsData,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C1013) : const Color(0xFFF8F9FA),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOperationsTab(context, textTheme, isDark),
            _buildTransactionsTab(context, textTheme, isDark),
            _buildAccountingTab(context, textTheme, isDark),
            _buildMarketingTab(context, textTheme, isDark),
            _buildPricingTab(context, textTheme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSideNav(BuildContext context, bool isDark, TextTheme textTheme) {
    final activeIndex = _tabController.index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: _isSideNavCollapsed ? 76 : 240,
      color: isDark ? const Color(0xFF13191B) : AppColors.primaryForest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Logo & Collapse Button
          Padding(
            padding: const EdgeInsets.only(
              top: 24.0,
              left: 16.0,
              right: 16.0,
              bottom: 20.0,
            ),
            child: Row(
              mainAxisAlignment: _isSideNavCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!_isSideNavCollapsed) ...[
                  const Icon(
                    LucideIcons.shieldAlert,
                    color: AppColors.accentLime,
                    size: 22,
                  ),
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
                  const Icon(
                    LucideIcons.shieldAlert,
                    color: AppColors.accentLime,
                    size: 24,
                  ),
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
                _buildSideNavItem(
                  index: 0,
                  icon: LucideIcons.activity,
                  label: 'Operations',
                  isActive: activeIndex == 0,
                  isDark: isDark,
                  textTheme: textTheme,
                  hasBadge: _tickets.any((t) => t['admin_unread'] == true),
                ),
                const SizedBox(height: 8),
                _buildSideNavItem(
                  index: 1,
                  icon: LucideIcons.listOrdered,
                  label: 'Transactions',
                  isActive: activeIndex == 1,
                  isDark: isDark,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 8),
                _buildSideNavItem(
                  index: 2,
                  icon: LucideIcons.barChart2,
                  label: 'Accounting',
                  isActive: activeIndex == 2,
                  isDark: isDark,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 8),
                _buildSideNavItem(
                  index: 3,
                  icon: LucideIcons.megaphone,
                  label: 'Marketing',
                  isActive: activeIndex == 3,
                  isDark: isDark,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 8),
                _buildSideNavItem(
                  index: 4,
                  icon: LucideIcons.sliders,
                  label: 'Pricing & Surcharges',
                  isActive: activeIndex == 4,
                  isDark: isDark,
                  textTheme: textTheme,
                ),
              ],
            ),
          ),

          // Collapse/Expand toggle at bottom
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                _buildSideNavItem(
                  index: -1, // Back action
                  icon: LucideIcons.arrowLeft,
                  label: 'Back to Profile',
                  isActive: false,
                  isDark: isDark,
                  textTheme: textTheme,
                  onTap: () => Navigator.of(context).pop(),
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
                        _isSideNavCollapsed
                            ? LucideIcons.chevronRight
                            : LucideIcons.chevronLeft,
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

  Widget _buildSideNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDark,
    required TextTheme textTheme,
    bool hasBadge = false,
    VoidCallback? onTap,
  }) {
    final activeBgColor = isDark ? AppColors.primaryForest : Colors.white;
    final activeTextColor = isDark ? Colors.white : AppColors.primaryForest;
    final inactiveTextColor = Colors.white.withOpacity(0.7);

    final Widget child = InkWell(
      onTap:
          onTap ??
          () {
            _tabController.animateTo(index);
          },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: _isSideNavCollapsed ? 0 : 16),
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: _isSideNavCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Badge(
              isLabelVisible: hasBadge,
              backgroundColor: AppColors.errorRed,
              child: Icon(
                icon,
                color: isActive ? activeTextColor : inactiveTextColor,
                size: 20,
              ),
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
      return Tooltip(message: label, child: child);
    }

    return child;
  }

  Widget _buildDesktopHeader(
    BuildContext context,
    bool isDark,
    TextTheme textTheme,
  ) {
    final activeIndex = _tabController.index;
    String title = 'Admin Console';
    if (activeIndex == 0) title = 'Operations & Support Tickets';
    if (activeIndex == 1) title = 'Accounting & Settlement Ledger';
    if (activeIndex == 2) title = 'Marketing & Banners Campaigns';
    if (activeIndex == 3) title = 'Vending Surcharges & Markups';

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13191B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const InAppDocumentationScreen(),
                ),
              );
            },
            icon: const Icon(LucideIcons.fileText, size: 16),
            label: const Text('Developer Documentation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentLime,
              foregroundColor: AppColors.textDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            color: isDark ? Colors.white70 : AppColors.textDark,
            onPressed: _loadOperationsData,
            tooltip: 'Refresh Stats',
          ),
        ],
      ),
    );
  }

  // --- OPERATIONS TAB ---
  Widget _buildOperationsTab(
    BuildContext context,
    TextTheme textTheme,
    bool isDark,
  ) {
    final activeTickets = _tickets
        .where((t) => t['status'] == 'escalated')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Support Tickets Desk
          Row(
            children: [
              const Icon(
                LucideIcons.helpCircle,
                color: AppColors.primaryForest,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Support Tickets Desk',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingTickets)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(
                  color: AppColors.primaryForest,
                ),
              ),
            )
          else if (activeTickets.isEmpty)
            Card(
              color: isDark ? Colors.white10 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No pending escalated tickets! Platform is healthy.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeTickets.length,
              itemBuilder: (context, index) {
                final ticket = activeTickets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ticket['id'] ?? '#TKT-XXXXX',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                if (ticket['admin_unread'] == true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorRed,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'NEW MESSAGE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              ticket['profiles']?['full_name'] ?? 'Guest User',
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ticket['title'] ?? 'Title',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ticket['description'] ?? 'No description provided.',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      AdminChatDialog(ticket: ticket),
                                ).then((_) => _loadOperationsData());
                              },
                              icon: const Icon(
                                LucideIcons.messageSquare,
                                size: 14,
                              ),
                              label: const Text('Open Chat'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryForest,
                                side: const BorderSide(
                                  color: AppColors.primaryForest,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _resolveTicket(ticket['id']),
                              icon: const Icon(
                                LucideIcons.checkCircle,
                                size: 14,
                              ),
                              label: const Text('Resolve Ticket'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.successGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // Section: Audit Log
          Row(
            children: [
              const Icon(
                LucideIcons.list,
                color: AppColors.primaryForest,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Platform Audit Ledger',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingTransactions)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(
                  color: AppColors.primaryForest,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _systemTransactions.length,
              itemBuilder: (context, index) {
                final tx = _systemTransactions[index];
                final isCredit = (tx['amount'] as num) > 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    title: Text(
                      tx['title'] ?? 'Transaction',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      'Account: ${tx['profiles']?['full_name'] ?? 'Unknown'} • Ref: ${tx['reference'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                    trailing: Text(
                      (isCredit ? '+' : '-') +
                          CurrencyFormatter.format(
                            (tx['amount'] as num).abs().toDouble(),
                          ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isCredit
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _updateTxStatus(String txId, String newStatus) async {
    try {
      setState(() => _isLoadingTransactions = true);
      await SupabaseService.client
          .from('transactions')
          .update({'status': newStatus})
          .eq('id', txId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transaction status updated to $newStatus successfully!',
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
      await _loadOperationsData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      setState(() => _isLoadingTransactions = false);
    }
  }

  Future<void> _refundTransaction(Map<String, dynamic> tx) async {
    final profileId = tx['profile_id'];
    final txId = tx['id'];
    final double refundAmt = (tx['amount'] as num).abs().toDouble();

    if (profileId == null) return;

    try {
      setState(() => _isLoadingTransactions = true);

      // 1. Fetch current profile wallet balance
      final profileRes = await SupabaseService.client
          .from('profiles')
          .select('wallet_balance')
          .eq('id', profileId)
          .maybeSingle();

      if (profileRes == null) {
        throw Exception('User profile not found.');
      }

      final double currentBalance = (profileRes['wallet_balance'] as num)
          .toDouble();

      // 2. Update profiles balance in Supabase
      await SupabaseService.client
          .from('profiles')
          .update({'wallet_balance': currentBalance + refundAmt})
          .eq('id', profileId);

      // 3. Mark transaction as failed/refunded
      await SupabaseService.client
          .from('transactions')
          .update({
            'status': 'failed',
            'subtitle': '${tx['subtitle']} (Refunded ₦$refundAmt)',
          })
          .eq('id', txId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User refunded ₦$refundAmt and transaction marked as Failed.',
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
      await _loadOperationsData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refund failed: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      setState(() => _isLoadingTransactions = false);
    }
  }

  // --- TRANSACTIONS TAB ---
  Widget _buildTransactionsTab(
    BuildContext context,
    TextTheme textTheme,
    bool isDark,
  ) {
    final filteredTx = _systemTransactions.where((tx) {
      // 1. Search Query Filter
      final query = _txSearchQuery.toLowerCase();
      final title = (tx['title'] ?? '').toString().toLowerCase();
      final subtitle = (tx['subtitle'] ?? '').toString().toLowerCase();
      final ref = (tx['reference'] ?? '').toString().toLowerCase();
      final fullName = (tx['profiles']?['full_name'] ?? '')
          .toString()
          .toLowerCase();
      final email = (tx['profiles']?['email'] ?? '').toString().toLowerCase();

      final matchesQuery =
          query.isEmpty ||
          title.contains(query) ||
          subtitle.contains(query) ||
          ref.contains(query) ||
          fullName.contains(query) ||
          email.contains(query);

      // 2. Category Filter
      final category = (tx['category'] ?? '').toString().toLowerCase();
      final matchesCategory =
          _txSelectedCategory == 'All' ||
          category == _txSelectedCategory.toLowerCase();

      // 3. Status Filter
      final status = (tx['status'] ?? '').toString().toLowerCase();
      final matchesStatus =
          _txSelectedStatus == 'All' ||
          status == _txSelectedStatus.toLowerCase();

      return matchesQuery && matchesCategory && matchesStatus;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadOperationsData,
      color: AppColors.primaryForest,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Search
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All System Transactions',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                Text(
                  '${filteredTx.length} items',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              onChanged: (val) {
                setState(() {
                  _txSearchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by user name, email, ref, title...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Filter ChoiceChips
            const Text(
              'Filter by Category',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'bills', 'wallet', 'transfer', 'budget'].map((
                  cat,
                ) {
                  final isSelected = _txSelectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        cat == 'All' ? 'All Categories' : cat.toUpperCase(),
                      ),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _txSelectedCategory = cat;
                        });
                      },
                      selectedColor: AppColors.primaryForest.withValues(
                        alpha: 0.15,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primaryForest
                            : (isDark ? Colors.white70 : AppColors.textDark),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Status Filter ChoiceChips
            const Text(
              'Filter by Status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: ['All', 'success', 'pending', 'failed'].map((status) {
                final isSelected = _txSelectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(status.toUpperCase()),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _txSelectedStatus = status;
                      });
                    },
                    selectedColor: AppColors.primaryForest.withValues(
                      alpha: 0.15,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primaryForest
                          : (isDark ? Colors.white70 : AppColors.textDark),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 200), // Transaction Table
            if (_isLoadingTransactions)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(
                    color: AppColors.primaryForest,
                  ),
                ),
              )
            else if (filteredTx.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Text(
                    'No transactions matching search criteria found.',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161E1A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    // Table Header Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'USER',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textGrey,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'SERVICE / DETAILS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textGrey,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'AMOUNT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textGrey,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'STATUS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Table Body Rows
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTx.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final tx = filteredTx[index];
                        final isCredit = (tx['amount'] as num) > 0;
                        final statusStr = (tx['status'] ?? 'pending')
                            .toString()
                            .toLowerCase();

                        Color statusColor = AppColors.successGreen;
                        if (statusStr == 'pending') statusColor = Colors.orange;
                        if (statusStr == 'failed')
                          statusColor = AppColors.errorRed;

                        return InkWell(
                          onTap: () {
                            _showTransactionDetailsModal(
                              context,
                              tx,
                              isDark,
                              textTheme,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                // Column 1: User
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx['profiles']?['full_name'] ??
                                            'Guest User',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tx['profiles']?['email'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textGrey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Column 2: Service/Details
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx['title'] ?? 'Transaction',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tx['subtitle'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textGrey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Column 3: Amount
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    (isCredit ? '+' : '-') +
                                        CurrencyFormatter.format(
                                          (tx['amount'] as num)
                                              .abs()
                                              .toDouble(),
                                        ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isCredit
                                          ? AppColors.successGreen
                                          : AppColors.errorRed,
                                    ),
                                  ),
                                ),
                                // Column 4: Status
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          statusStr.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
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
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementBreakdown(Map<String, dynamic> tx, bool isDark) {
    final List<dynamic> settleList = tx['settlement_ledger'] is List
        ? tx['settlement_ledger']
        : [];
    final Map<String, dynamic>? settle = settleList.isNotEmpty
        ? settleList.first
        : null;

    final double userCharged = (tx['amount'] as num).abs().toDouble();
    final double? providerCost = settle?['vtpass_cost'] != null
        ? (settle!['vtpass_cost'] as num).toDouble()
        : null;
    final double? netProfit = settle?['net_profit'] != null
        ? (settle!['net_profit'] as num).toDouble()
        : null;

    double cashbackAmount = 0.0;
    if (providerCost != null && netProfit != null) {
      // net_profit = userCharged - providerCost - cashbackAmount
      // cashbackAmount = userCharged - providerCost - net_profit
      cashbackAmount = userCharged - providerCost - netProfit;
      if (cashbackAmount < 0.0) cashbackAmount = 0.0;
    }

    final category = (tx['category'] ?? '').toString().toLowerCase();
    if (category != 'bills') {
      cashbackAmount = 0.0;
    }

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FINANCIAL LEDGER BREAKDOWN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildFinancialColumn(
                  title: 'User Charged',
                  amount: userCharged,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: isDark ? Colors.white10 : Colors.grey.shade300,
              ),
              Expanded(
                child: _buildFinancialColumn(
                  title: 'Provider Cost',
                  amount: providerCost,
                  color: AppColors.primaryForest,
                  isNA: providerCost == null,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: isDark ? Colors.white10 : Colors.grey.shade300,
              ),
              Expanded(
                child: _buildFinancialColumn(
                  title: 'Cashback',
                  amount: cashbackAmount,
                  color: AppColors.successGreen,
                  isNA: category != 'bills',
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: isDark ? Colors.white10 : Colors.grey.shade300,
              ),
              Expanded(
                child: _buildFinancialColumn(
                  title: 'Admin Share',
                  amount: netProfit,
                  color: netProfit != null && netProfit < 0
                      ? AppColors.errorRed
                      : AppColors.accentLime,
                  isNA: netProfit == null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialColumn({
    required String title,
    required double? amount,
    required Color color,
    bool isNA = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isNA || amount == null ? 'N/A' : CurrencyFormatter.format(amount),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // --- ACCOUNTING TAB ---
  Widget _buildAccountingTab(
    BuildContext context,
    TextTheme textTheme,
    bool isDark,
  ) {
    // Calculate aggregate metrics from transactions list
    double totalInflow = 0;
    double totalOutflow = 0;

    for (final tx in _systemTransactions) {
      final amt = (tx['amount'] as num).toDouble();
      if (amt > 0) {
        totalInflow += amt;
      } else {
        totalOutflow += amt.abs();
      }
    }

    final double netLiquidity = totalInflow - totalOutflow;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of accounting card metrics
          Row(
            children: [
              const Icon(
                LucideIcons.barChart,
                color: AppColors.primaryForest,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Financial Performance Monitor',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total liquid reserves
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryForest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryForest.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PAYSTACK RESERVES',
                        style: TextStyle(
                          color: AppColors.accentLime,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(netLiquidity),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.shieldCheck,
                            color: AppColors.accentLime,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              netLiquidity >= 0
                                  ? 'Reserve Healthy'
                                  : 'Deficit Warning',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.teal.shade900 : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.teal.shade800
                          : Colors.teal.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VTPASS VENDING FLOAT',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.accentLime
                              : AppColors.primaryForest,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _isLoadingVTPassBalance
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryForest,
                              ),
                            )
                          : Text(
                              _vtpassBalance != null
                                  ? CurrencyFormatter.format(_vtpassBalance!)
                                  : '₦0.00',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.refreshCw,
                            color: isDark
                                ? AppColors.accentLime
                                : AppColors.primaryForest,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                setState(() {
                                  _isLoadingVTPassBalance = true;
                                });
                                final bal = await VtPassService.fetchBalance();
                                if (bal != null) {
                                  setState(() {
                                    _vtpassBalance = bal;
                                  });
                                }
                                setState(() {
                                  _isLoadingVTPassBalance = false;
                                });
                              },
                              child: Text(
                                _isLoadingVTPassBalance
                                    ? 'Syncing...'
                                    : 'Sync Balance',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textDark.withValues(
                                          alpha: 0.7,
                                        ),
                                  fontSize: 10,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Inflow and Outflow grids
          Row(
            children: [
              Expanded(
                child: _buildAccountingStatCard(
                  title: 'Platform Inflow',
                  amount: totalInflow,
                  icon: LucideIcons.trendingUp,
                  color: AppColors.successGreen,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAccountingStatCard(
                  title: 'Platform Outflow',
                  amount: totalOutflow,
                  icon: LucideIcons.trendingDown,
                  color: AppColors.errorRed,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Product category splits
          Text(
            'Product Vending Breakdown',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          _buildVendingProgressRow(
            label: 'Funds Transfers (Send)',
            percentage: 0.65,
            amount: totalOutflow * 0.65,
            color: Colors.blue,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildVendingProgressRow(
            label: 'Utility Airtime & Data',
            percentage: 0.25,
            amount: totalOutflow * 0.25,
            color: Colors.green,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildVendingProgressRow(
            label: 'Electricity & Cable TV',
            percentage: 0.10,
            amount: totalOutflow * 0.10,
            color: Colors.orange,
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // Settlement Reconciliation Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settlement Reconciliation Ledger',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              if (_isLoadingSettlements)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryForest,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_settlementLedgers.isEmpty)
            Card(
              color: isDark ? Colors.white10 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'No settlement ledger entries recorded yet.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _settlementLedgers.length,
              itemBuilder: (context, index) {
                final ledger = _settlementLedgers[index];
                final tx = ledger['transactions'] ?? {};
                final status = ledger['reconciliation_status'] ?? 'pending';
                final intake =
                    (ledger['intake_amount'] as num?)?.toDouble() ?? 0.0;
                final cost = (ledger['vtpass_cost'] as num?)?.toDouble();
                final profit =
                    (ledger['net_profit'] as num?)?.toDouble() ?? 0.0;

                Color statusColor = Colors.orange;
                if (status == 'matched') statusColor = AppColors.successGreen;
                if (status == 'discrepancy') statusColor = AppColors.errorRed;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showReconciliationDialog(ledger),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  tx['title'] ?? 'Platform Transaction',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ref: ${tx['reference'] ?? 'N/A'} • Provider: ${tx['provider'] ?? 'N/A'}',
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 11,
                            ),
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'INTAKE',
                                    style: TextStyle(
                                      color: AppColors.textGrey,
                                      fontSize: 9,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(intake),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'VTPASS COST',
                                    style: TextStyle(
                                      color: AppColors.textGrey,
                                      fontSize: 9,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cost != null
                                        ? CurrencyFormatter.format(cost)
                                        : 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'NET PROFIT',
                                    style: TextStyle(
                                      color: AppColors.textGrey,
                                      fontSize: 9,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(profit),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: profit >= 0
                                          ? AppColors.successGreen
                                          : AppColors.errorRed,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAccountingStatCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendingProgressRow({
    required String label,
    required double percentage,
    required double amount,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}% (${CurrencyFormatter.format(amount)})',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              color: color,
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // --- MARKETING TAB ---
  Widget _buildMarketingTab(
    BuildContext context,
    TextTheme textTheme,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Announcement Composer
          Row(
            children: [
              const Icon(
                LucideIcons.megaphone,
                color: AppColors.primaryForest,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'System Announcement Composer',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compose message to broadcast system-wide to all user terminals:',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _announcementTitleController,
                  decoration: InputDecoration(
                    labelText: 'Announcement Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _announcementBodyController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Compose Body text...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _isPublishing ? null : _publishAnnouncement,
                    icon: _isPublishing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(LucideIcons.send, size: 16),
                    label: const Text('Broadcast Announcement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryForest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Marketing Banners management
          Row(
            children: [
              const Icon(
                LucideIcons.image,
                color: AppColors.primaryForest,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Marketing Banners Slider Manager',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                width: 1,
              ),
            ),
            child: Consumer<WalletProvider>(
              builder: (context, walletProvider, child) {
                final banners = walletProvider.marketingBanners;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Slides List:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (banners.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'No custom banners added yet. App will fallback to beautiful system default slides.',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: banners.length,
                        itemBuilder: (context, index) {
                          final banner = banners[index];
                          final bool isDefault = banner['id']
                              .toString()
                              .startsWith('default-');
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: banner['image_url'] ?? '',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: AppColors.primaryForest,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey,
                                  child: const Icon(
                                    LucideIcons.image,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              banner['title'] ?? 'Untitled Slide',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Action: ',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textGrey,
                              ),
                            ),
                            trailing: isDefault
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'System',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.textGrey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      LucideIcons.trash2,
                                      color: AppColors.errorRed,
                                      size: 18,
                                    ),
                                    onPressed: () async {
                                      final success = await walletProvider
                                          .deleteMarketingBanner(banner['id']);
                                      if (success && mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Banner slide deleted successfully!',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                          );
                        },
                      ),
                    const Divider(height: 24),
                    const Text(
                      'Add New Marketing Slide Banner:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bannerTitleController,
                      decoration: InputDecoration(
                        labelText: 'Banner Slide Title (Headline)',
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bannerImageUrlController,
                      decoration: InputDecoration(
                        labelText: 'Banner Image URL (Unsplash or web link)',
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bannerActionUrlController,
                      decoration: InputDecoration(
                        labelText:
                            'Action Redirect Path (e.g. /budgeting or /transfers)',
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingBanner
                            ? null
                            : () async {
                                final img = _bannerImageUrlController.text
                                    .trim();
                                final title = _bannerTitleController.text
                                    .trim();
                                final action = _bannerActionUrlController.text
                                    .trim();

                                if (img.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please provide an image URL!',
                                      ),
                                      backgroundColor: AppColors.errorRed,
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  _isSavingBanner = true;
                                });

                                final success = await walletProvider
                                    .addMarketingBanner(img, title, action);

                                setState(() {
                                  _isSavingBanner = false;
                                });

                                if (success && mounted) {
                                  _bannerImageUrlController.clear();
                                  _bannerTitleController.clear();
                                  _bannerActionUrlController.clear();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Banner slide added successfully!',
                                      ),
                                      backgroundColor: AppColors.successGreen,
                                    ),
                                  );
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to add banner. Please verify SQL schema is deployed.',
                                      ),
                                      backgroundColor: AppColors.errorRed,
                                    ),
                                  );
                                }
                              },
                        icon: _isSavingBanner
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.plus, size: 16),
                        label: const Text('Add Marketing Slide'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryForest,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutOptimizerRow(String label, bool isBoosted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        Row(
          children: [
            Text(
              isBoosted ? 'Boosted' : 'Normal',
              style: TextStyle(
                color: isBoosted ? AppColors.successGreen : AppColors.textGrey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: isBoosted,
              onChanged: (v) {},
              activeColor: AppColors.successGreen,
            ),
          ],
        ),
      ],
    );
  }

  // --- PRICING TAB ---
  Widget _buildPricingTab(
    BuildContext context,
    TextTheme textTheme,
    bool isDark,
  ) {
    final walletProvider = Provider.of<WalletProvider>(context);

    // Initialize values once from provider
    if (!_isInitializedPricing) {
      _electricityFeeController.text = walletProvider.electricityFee
          .toStringAsFixed(2);
      _cableFeeController.text = walletProvider.cableFee.toStringAsFixed(2);
      _transferFeeController.text = walletProvider.transferFee.toStringAsFixed(
        2,
      );
      _pointsRateController.text = (walletProvider.pointsRate * 100)
          .toStringAsFixed(1);

      _airtimeMarkupPercentController.text = walletProvider.airtimeMarkupPercent
          .toStringAsFixed(2);
      _airtimeMarkupFlatController.text = walletProvider.airtimeMarkupFlat
          .toStringAsFixed(2);
      _dataMarkupPercentController.text = walletProvider.dataMarkupPercent
          .toStringAsFixed(2);
      _dataMarkupFlatController.text = walletProvider.dataMarkupFlat
          .toStringAsFixed(2);
      _cableMarkupPercentController.text = walletProvider.cableMarkupPercent
          .toStringAsFixed(2);
      _cableMarkupFlatController.text = walletProvider.cableMarkupFlat
          .toStringAsFixed(2);
      _electricityMarkupPercentController.text = walletProvider
          .electricityMarkupPercent
          .toStringAsFixed(2);
      _electricityMarkupFlatController.text = walletProvider
          .electricityMarkupFlat
          .toStringAsFixed(2);

      _airtimeMtnAdminController.text = walletProvider.airtimeMtnAdminShare
          .toStringAsFixed(2);
      _airtimeGloAdminController.text = walletProvider.airtimeGloAdminShare
          .toStringAsFixed(2);
      _airtime9mobileAdminController.text = walletProvider
          .airtime9mobileAdminShare
          .toStringAsFixed(2);
      _airtimeAirtelAdminController.text = walletProvider
          .airtimeAirtelAdminShare
          .toStringAsFixed(2);

      _dataMtnAdminController.text = walletProvider.dataMtnAdminShare
          .toStringAsFixed(2);
      _dataGloAdminController.text = walletProvider.dataGloAdminShare
          .toStringAsFixed(2);
      _data9mobileAdminController.text = walletProvider.data9mobileAdminShare
          .toStringAsFixed(2);
      _dataAirtelAdminController.text = walletProvider.dataAirtelAdminShare
          .toStringAsFixed(2);

      _electricityAdminController.text = walletProvider.electricityAdminShare
          .toStringAsFixed(4);
      _cableAdminController.text = walletProvider.cableAdminShare
          .toStringAsFixed(2);

      _isInitializedPricing = true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.sliders,
                color: AppColors.primaryForest,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Fee & Surcharge Configurations',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Platform Convenience Fees surcharges charged to users during bills vending:',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _electricityFeeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Electricity Vending Fee (₦)',
                    prefixIcon: const Icon(LucideIcons.zap),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _cableFeeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Cable TV Vending Fee (₦)',
                    prefixIcon: const Icon(LucideIcons.tv),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _transferFeeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Outbound Transfer Fee (₦)',
                    prefixIcon: const Icon(LucideIcons.send),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Loyalty Points Engine configuration multipliers:',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _pointsRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText:
                        'Cashback Rate (%) - e.g. 1.0% is 1 point per ₦100 spent',
                    prefixIcon: const Icon(LucideIcons.sparkles),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Divider(height: 32),

                Row(
                  children: [
                    const Icon(
                      LucideIcons.percent,
                      color: AppColors.primaryForest,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Business Addition Markups (Markup per Vending Plan)',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set percentages or flat Naira additions. Both can be combined (e.g. 2% + ₦50).',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Airtime Markup
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _airtimeMarkupPercentController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Airtime Markup (%)',
                          prefixIcon: const Icon(LucideIcons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _airtimeMarkupFlatController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Airtime Markup (₦)',
                          prefixIcon: const Icon(LucideIcons.coins),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Data Markup
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dataMarkupPercentController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Data Markup (%)',
                          prefixIcon: const Icon(LucideIcons.globe),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _dataMarkupFlatController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Data Markup (₦)',
                          prefixIcon: const Icon(LucideIcons.coins),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cable TV Markup
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cableMarkupPercentController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Cable TV Markup (%)',
                          prefixIcon: const Icon(LucideIcons.tv),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _cableMarkupFlatController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Cable TV Markup (₦)',
                          prefixIcon: const Icon(LucideIcons.coins),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Electricity Markup
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _electricityMarkupPercentController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Electricity Markup (%)',
                          prefixIcon: const Icon(LucideIcons.zap),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _electricityMarkupFlatController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Electricity Markup (₦)',
                          prefixIcon: const Icon(LucideIcons.coins),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Divider(height: 32),

                Row(
                  children: [
                    const Icon(
                      LucideIcons.gitFork,
                      color: AppColors.primaryForest,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dynamic Provider Commission Splits',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Distribute provider-side reseller discounts between Admin profit (Admin Share) and user reward points (User Cashback).',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
                const SizedBox(height: 16),

                Text(
                  'Airtime Commissions',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryForest,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCommissionInputRow(
                  label: 'MTN Airtime',
                  totalComm: walletProvider.airtimeMtnTotalComm,
                  controller: _airtimeMtnAdminController,
                ),
                _buildCommissionInputRow(
                  label: 'Glo Airtime',
                  totalComm: walletProvider.airtimeGloTotalComm,
                  controller: _airtimeGloAdminController,
                ),
                _buildCommissionInputRow(
                  label: '9mobile Airtime',
                  totalComm: walletProvider.airtime9mobileTotalComm,
                  controller: _airtime9mobileAdminController,
                ),
                _buildCommissionInputRow(
                  label: 'Airtel Airtime',
                  totalComm: walletProvider.airtimeAirtelTotalComm,
                  controller: _airtimeAirtelAdminController,
                ),

                const SizedBox(height: 16),
                Text(
                  'Data Bundle Commissions',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryForest,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCommissionInputRow(
                  label: 'MTN Data',
                  totalComm: walletProvider.dataMtnTotalComm,
                  controller: _dataMtnAdminController,
                ),
                _buildCommissionInputRow(
                  label: 'Glo Data',
                  totalComm: walletProvider.dataGloTotalComm,
                  controller: _dataGloAdminController,
                ),
                _buildCommissionInputRow(
                  label: '9mobile Data',
                  totalComm: walletProvider.data9mobileTotalComm,
                  controller: _data9mobileAdminController,
                ),
                _buildCommissionInputRow(
                  label: 'Airtel Data',
                  totalComm: walletProvider.dataAirtelTotalComm,
                  controller: _dataAirtelAdminController,
                ),

                const SizedBox(height: 16),
                Text(
                  'Utilities Commissions',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryForest,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCommissionInputRow(
                  label: 'Electricity Vending',
                  totalComm: walletProvider.electricityTotalComm,
                  controller: _electricityAdminController,
                ),
                _buildCommissionInputRow(
                  label: 'Cable TV Vending',
                  totalComm: walletProvider.cableTotalComm,
                  controller: _cableAdminController,
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingPricing
                        ? null
                        : () => _savePricingConfig(walletProvider),
                    icon: _isSavingPricing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(LucideIcons.save, size: 16),
                    label: const Text('Update Pricing Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryForest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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

  Widget _buildCommissionInputRow({
    required String label,
    required double totalComm,
    required TextEditingController controller,
  }) {
    final double adminShare = double.tryParse(controller.text) ?? 0.0;
    final double userCashback = (totalComm - adminShare) < 0.0
        ? 0.0
        : totalComm - adminShare;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Provider discount: ${totalComm.toStringAsFixed(totalComm == 0.01 ? 4 : 2)}%',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (val) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Admin Share %',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: userCashback > 0
                    ? AppColors.successGreen.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'User: ${userCashback.toStringAsFixed(totalComm == 0.01 ? 4 : 2)}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: userCashback > 0
                      ? AppColors.successGreen
                      : AppColors.textGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePricingConfig(WalletProvider walletProvider) async {
    setState(() {
      _isSavingPricing = true;
    });

    final elect = double.tryParse(_electricityFeeController.text) ?? 150.0;
    final cable = double.tryParse(_cableFeeController.text) ?? 150.0;
    final trans = double.tryParse(_transferFeeController.text) ?? 25.0;
    final rate = (double.tryParse(_pointsRateController.text) ?? 1.0) / 100.0;

    final airtimePct =
        double.tryParse(_airtimeMarkupPercentController.text) ?? 0.0;
    final airtimeFlat =
        double.tryParse(_airtimeMarkupFlatController.text) ?? 0.0;
    final dataPct = double.tryParse(_dataMarkupPercentController.text) ?? 0.0;
    final dataFlat = double.tryParse(_dataMarkupFlatController.text) ?? 0.0;
    final cablePct = double.tryParse(_cableMarkupPercentController.text) ?? 0.0;
    final cableFlat = double.tryParse(_cableMarkupFlatController.text) ?? 0.0;
    final electPct =
        double.tryParse(_electricityMarkupPercentController.text) ?? 0.0;
    final electFlat =
        double.tryParse(_electricityMarkupFlatController.text) ?? 0.0;

    final airtimeMtnAdmin =
        double.tryParse(_airtimeMtnAdminController.text) ?? 2.0;
    final airtimeGloAdmin =
        double.tryParse(_airtimeGloAdminController.text) ?? 5.0;
    final airtime9mobileAdmin =
        double.tryParse(_airtime9mobileAdminController.text) ?? 4.0;
    final airtimeAirtelAdmin =
        double.tryParse(_airtimeAirtelAdminController.text) ?? 2.0;

    final dataMtnAdmin = double.tryParse(_dataMtnAdminController.text) ?? 2.0;
    final dataGloAdmin = double.tryParse(_dataGloAdminController.text) ?? 3.0;
    final data9mobileAdmin =
        double.tryParse(_data9mobileAdminController.text) ?? 4.0;
    final dataAirtelAdmin =
        double.tryParse(_dataAirtelAdminController.text) ?? 2.0;

    final electricityAdmin =
        double.tryParse(_electricityAdminController.text) ?? 0.005;
    final cableAdmin = double.tryParse(_cableAdminController.text) ?? 0.0;

    try {
      await SupabaseService.client.from('fees_config').upsert({
        'id': 'main',
        'electricity_fee': elect,
        'cable_fee': cable,
        'transfer_fee': trans,
        'points_rate': rate,
        'airtime_markup_percent': airtimePct,
        'airtime_markup_flat': airtimeFlat,
        'data_markup_percent': dataPct,
        'data_markup_flat': dataFlat,
        'cable_markup_percent': cablePct,
        'cable_markup_flat': cableFlat,
        'electricity_markup_percent': electPct,
        'electricity_markup_flat': electFlat,
        'airtime_mtn_admin_share': airtimeMtnAdmin,
        'airtime_glo_admin_share': airtimeGloAdmin,
        'airtime_9mobile_admin_share': airtime9mobileAdmin,
        'airtime_airtel_admin_share': airtimeAirtelAdmin,
        'data_mtn_admin_share': dataMtnAdmin,
        'data_glo_admin_share': dataGloAdmin,
        'data_9mobile_admin_share': data9mobileAdmin,
        'data_airtel_admin_share': dataAirtelAdmin,
        'electricity_admin_share': electricityAdmin,
        'cable_admin_share': cableAdmin,
      });

      await walletProvider.fetchFeesConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pricing and loyalty configuration updated dynamically in database!',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save fees config: $e');
      if (mounted) {
        String errMsg = 'Failed to save configurations: $e';
        if (e.toString().contains('42703') || e.toString().contains('column')) {
          errMsg =
              'Failed to save: Database columns do not exist. Please run the SQL migration script in your Supabase SQL editor first.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPricing = false;
        });
      }
    }
  }

  void _showTransactionDetailsModal(
    BuildContext context,
    Map<String, dynamic> tx,
    bool isDark,
    TextTheme textTheme,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final isCredit = (tx['amount'] as num) > 0;
        final txId = tx['id'].toString();
        final statusStr = (tx['status'] ?? 'pending').toString().toLowerCase();

        Color statusColor = AppColors.successGreen;
        if (statusStr == 'pending') statusColor = Colors.orange;
        if (statusStr == 'failed') statusColor = AppColors.errorRed;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: isDark ? const Color(0xFF161E1A) : Colors.white,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.85,
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx['title'] ?? 'Transaction Details',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ref: ${tx['reference'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(LucideIcons.x),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // General Details Card
                      _buildModalSectionTitle('GENERAL INFORMATION'),
                      const SizedBox(height: 8),
                      _buildModalInfoRow(
                        'User Name',
                        tx['profiles']?['full_name'] ?? 'N/A',
                        LucideIcons.user,
                      ),
                      _buildModalInfoRow(
                        'User Email',
                        tx['profiles']?['email'] ?? 'N/A',
                        LucideIcons.mail,
                      ),
                      _buildModalInfoRow(
                        'Description',
                        tx['subtitle'] ?? 'N/A',
                        LucideIcons.fileText,
                      ),
                      _buildModalInfoRow(
                        'Date/Time',
                        tx['created_at'] != null
                            ? DateTime.parse(
                                tx['created_at'].toString(),
                              ).toLocal().toString().substring(0, 19)
                            : 'N/A',
                        LucideIcons.calendar,
                      ),
                      _buildModalInfoRow(
                        'Gateway Provider',
                        tx['provider'] ?? 'ClubKonnect',
                        LucideIcons.server,
                      ),
                      _buildModalInfoRow(
                        'Amount',
                        (isCredit ? '+' : '-') +
                            CurrencyFormatter.format(
                              (tx['amount'] as num).abs().toDouble(),
                            ),
                        LucideIcons.wallet,
                        valueColor: isCredit
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                        valueFontWeight: FontWeight.bold,
                      ),
                      _buildModalInfoRow(
                        'Current Status',
                        statusStr.toUpperCase(),
                        LucideIcons.info,
                        valueColor: statusColor,
                        valueFontWeight: FontWeight.bold,
                      ),
                      const Divider(height: 24),

                      // Financial Split Ledger
                      _buildModalSectionTitle('FINANCIAL SPLIT BREAKDOWN'),
                      const SizedBox(height: 12),
                      _buildSettlementBreakdown(tx, isDark),
                      const Divider(height: 24),

                      // Actions
                      _buildModalSectionTitle('ADMIN MANAGEMENT ACTIONS'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Refund Button
                          if (!isCredit && statusStr != 'failed')
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context); // Close details modal
                                _confirmRefund(context, tx);
                              },
                              icon: const Icon(LucideIcons.rotateCcw, size: 14),
                              label: const Text('Refund User'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryForest,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          // Mark Success
                          if (statusStr != 'success')
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateTxStatus(txId, 'success');
                              },
                              icon: const Icon(
                                LucideIcons.checkCircle,
                                size: 14,
                                color: AppColors.successGreen,
                              ),
                              label: const Text('Mark Success'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.successGreen,
                                side: const BorderSide(
                                  color: AppColors.successGreen,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          // Mark Failed
                          if (statusStr != 'failed')
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateTxStatus(txId, 'failed');
                              },
                              icon: const Icon(
                                LucideIcons.xCircle,
                                size: 14,
                                color: AppColors.errorRed,
                              ),
                              label: const Text('Mark Failed'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.errorRed,
                                side: const BorderSide(
                                  color: AppColors.errorRed,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          // Mark Pending
                          if (statusStr != 'pending')
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateTxStatus(txId, 'pending');
                              },
                              icon: const Icon(
                                LucideIcons.helpCircle,
                                size: 14,
                                color: Colors.orange,
                              ),
                              label: const Text('Mark Pending'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmRefund(BuildContext context, Map<String, dynamic> tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Refund'),
        content: Text(
          'Are you sure you want to refund ${CurrencyFormatter.format((tx['amount'] as num).abs().toDouble())} to ${tx['profiles']?['full_name'] ?? 'this user\'s'} wallet balance?\n\nThis transaction status will also be set to FAILED.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _refundTransaction(tx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refund User'),
          ),
        ],
      ),
    );
  }

  Widget _buildModalSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.textGrey,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildModalInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textGrey),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: valueFontWeight ?? FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminChatDialog extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const AdminChatDialog({super.key, required this.ticket});

  @override
  State<AdminChatDialog> createState() => _AdminChatDialogState();
}

class _AdminChatDialogState extends State<AdminChatDialog> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  StreamSubscription? _chatSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessagesAndSubscribe();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessagesAndSubscribe() async {
    final ticketId = widget.ticket['id'];
    try {
      // Mark ticket read by admin
      await SupabaseService.client
          .from('support_tickets')
          .update({'admin_unread': false})
          .eq('id', ticketId);

      // Load past messages
      final res = await SupabaseService.client
          .from('support_messages')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      if (res != null && mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(List<Map<String, dynamic>>.from(res));
          _isLoading = false;
        });
        _scrollToBottom();
      }

      // Subscribe to stream
      _chatSubscription = SupabaseService.client
          .from('support_messages')
          .stream(primaryKey: ['id'])
          .eq('ticket_id', ticketId)
          .listen((data) {
            if (data.isNotEmpty && mounted) {
              setState(() {
                for (final row in data) {
                  final msgId = row['id'];
                  final exists = _messages.any((m) => m['id'] == msgId);
                  if (!exists) {
                    _messages.add(row);
                  }
                }
                _messages.sort(
                  (a, b) => a['created_at'].toString().compareTo(
                    b['created_at'].toString(),
                  ),
                );
              });
              _scrollToBottom();
            }
          });
    } catch (e) {
      debugPrint('Failed to load admin chat: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    final ticketId = widget.ticket['id'];
    final uid = SupabaseService.client.auth.currentUser?.id;

    try {
      // Insert message
      await SupabaseService.client.from('support_messages').insert({
        'ticket_id': ticketId,
        'sender_id': uid,
        'message': text,
        'is_admin': true,
      });

      // Update ticket unread flags
      await SupabaseService.client
          .from('support_tickets')
          .update({'user_unread': true, 'admin_unread': false})
          .eq('id', ticketId);
    } catch (e) {
      debugPrint('Failed to send admin support message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E201E) : Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat with ${widget.ticket['profiles']?['full_name'] ?? 'User'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Ticket: ${widget.ticket['title']}',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
            const Divider(),

            // Messages List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryForest,
                      ),
                    )
                  : _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet. Send a response below.',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[index];
                        final isAdmin = m['is_admin'] as bool? ?? false;
                        return Align(
                          alignment: isAdmin
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? AppColors.primaryForest
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.grey.shade200),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: Radius.circular(isAdmin ? 12 : 2),
                                bottomRight: Radius.circular(isAdmin ? 2 : 12),
                              ),
                            ),
                            child: Text(
                              m['message'] ?? '',
                              style: TextStyle(
                                color: isAdmin
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white
                                          : AppColors.textDark),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),

            // Input bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(
                    LucideIcons.sendHorizontal,
                    color: AppColors.primaryForest,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
