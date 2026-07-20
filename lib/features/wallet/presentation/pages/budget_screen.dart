import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/utils/currency_formatter.dart';
import 'package:mspay/core/presentation/widgets/branded_spinner.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/wallet/data/models/budget_model.dart';
import 'package:mspay/features/wallet/data/models/transaction_model.dart';
import 'package:mspay/features/utilities/data/datasources/vtpass_service.dart';
import 'package:mspay/features/utilities/presentation/widgets/receipt_modal.dart';
import 'package:mspay/features/utilities/presentation/pages/airtime_data_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/electricity_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/cable_tv_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/waec_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/jamb_screen.dart';
import 'package:mspay/features/utilities/presentation/pages/betting_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  void _showCreateBudgetSheet(BuildContext context, WalletProvider walletProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateBudgetSheet(walletProvider: walletProvider),
    );
  }

  Future<void> _handleExecuteManual(BuildContext context, WalletProvider walletProvider, BudgetModel budget) async {
    if (!budget.isAutomatic) {
      Widget targetScreen;
      switch (budget.serviceType) {
        case 'Data':
          targetScreen = AirtimeDataScreen(isData: true, budget: budget);
          break;
        case 'Cable TV':
          targetScreen = CableTvScreen(budget: budget);
          break;
        case 'Electricity':
          targetScreen = ElectricityScreen(budget: budget);
          break;
        case 'Betting':
          targetScreen = BettingScreen(budget: budget);
          break;
        case 'WAEC':
          targetScreen = WaecScreen(budget: budget);
          break;
        case 'JAMB':
          targetScreen = JambScreen(budget: budget);
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unknown service type for budget.')),
          );
          return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      );
      return;
    }

    if (budget.target == null || budget.target!.isEmpty || budget.providerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target details are incomplete. Please edit or recreate budget.')),
      );
      return;
    }

    final double spendAmount = budget.subscriptionCost ?? budget.amount;

    if (spendAmount > budget.amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget balance is insufficient for this subscription. Please cancel and recreate.')),
      );
      return;
    }

    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Subscription'),
        content: Text('Do you want to execute subscription for ${budget.title} now? ${CurrencyFormatter.format(spendAmount)} will be paid and deducted from this budget.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pay Now')),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    BrandedLoadingOverlay.show(context, message: 'Executing subscription...');

    final purchaseResult = await VtPassService.purchaseProduct(
      serviceType: budget.serviceType,
      target: budget.target!,
      amount: spendAmount,
      providerName: budget.providerName,
      variationCode: budget.variationCode,
    );

    if (context.mounted) {
      BrandedLoadingOverlay.hide(context);
      if (purchaseResult.success) {
        final paySuccess = await walletProvider.payBill(
          amount: spendAmount,
          serviceName: budget.title,
          billDetails: 'Budget Vending: ${budget.serviceType} • Target: ${budget.target}',
          category: TransactionCategory.bills,
          vendorReference: purchaseResult.transactionId,
          baseAmount: spendAmount,
          serviceType: budget.serviceType,
          providerName: budget.providerName,
          isBudgetExecution: true,
        );

        if (paySuccess) {
          await walletProvider.deductFromBudget(budget.id, spendAmount);

          if (context.mounted) {
            ReceiptModal.show(
              context,
              serviceTitle: budget.title,
              recipient: budget.target!,
              amount: spendAmount,
              transactionId: purchaseResult.transactionId ?? 'CK-BUDGET',
              providerName: budget.providerName ?? 'Service',
              token: purchaseResult.carddetails ?? purchaseResult.token,
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(purchaseResult.error ?? 'Vending failed. Please try again.')),
        );
      }
    }
  }

  Future<void> _handleCancelBudget(BuildContext context, WalletProvider walletProvider, BudgetModel budget) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Budget'),
        content: Text('Are you sure you want to cancel ${budget.title}? The locked sum of ${CurrencyFormatter.format(budget.amount)} will be returned to your available balance.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Unlock')),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    final success = await walletProvider.cancelBudget(budget.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget cancelled and funds unlocked successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final activeBudgets = walletProvider.budgets.where((b) => b.status == 'active').toList();
    final completedBudgets = walletProvider.budgets.where((b) => b.status == 'completed' || b.status == 'cancelled').toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paylens Budgeting'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 960),
          child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryForest, Color(0xFF003320)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryForest.withValues(alpha: 0.3),
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
                        const Text(
                          'TOTAL LOCKED BUDGETS',
                          style: TextStyle(
                            color: AppColors.textLightGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Icon(LucideIcons.lock, color: AppColors.accentLime.withValues(alpha: 0.8), size: 18),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      CurrencyFormatter.format(walletProvider.lockedBudgetBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available Balance',
                              style: TextStyle(color: AppColors.textLightGrey, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(walletProvider.availableBalance),
                              style: const TextStyle(color: AppColors.accentLime, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Total Balance',
                              style: TextStyle(color: AppColors.textLightGrey, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(walletProvider.availableBalance + walletProvider.lockedBudgetBalance),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Locked Budgets',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _showCreateBudgetSheet(context, walletProvider),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add Budget'),
                  ),
                ],
              ),
            ),
          ),
          if (activeBudgets.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(LucideIcons.walletCards, size: 48, color: AppColors.textGrey),
                      SizedBox(height: 16),
                      Text(
                        'No active budgets found.\nLock funds to avoid accidental spending!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final budget = activeBudgets[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: isDark ? const Color(0xFF1E201E) : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        budget.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Category: ${budget.serviceType} • ${budget.isAutomatic ? "Automatic (${budget.frequency})" : "Manual Reservation"}',
                                        style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(budget.amount),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primaryForest),
                                ),
                              ],
                            ),
                            if (budget.target != null && budget.target!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF121212) : AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Destination: ${budget.providerName?.toUpperCase()} (${budget.target})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _handleCancelBudget(context, walletProvider, budget),
                                  icon: const Icon(LucideIcons.lockOpen, size: 14),
                                  label: const Text('Unlock'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.errorRed,
                                    side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.2)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _handleExecuteManual(context, walletProvider, budget),
                                  icon: const Icon(LucideIcons.checkSquare, size: 14),
                                  label: const Text('Pay Subscription'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryForest,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: activeBudgets.length,
                ),
              ),
            ),
          if (completedBudgets.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
                child: Text(
                  'Completed & Cancelled',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final budget = completedBudgets[index];
                    final isCompleted = budget.status == 'completed';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(budget.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${budget.serviceType} • ${isCompleted ? "Paid out" : "Unlocked"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(budget.amount),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? AppColors.successGreen : AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.successGreen.withValues(alpha: 0.1)
                                  : AppColors.errorRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              budget.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: isCompleted ? AppColors.successGreen : AppColors.errorRed,
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                  childCount: completedBudgets.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ]
        ],
      ),
        ),
      ),
    );
  }
}

class CreateBudgetSheet extends StatefulWidget {
  final WalletProvider walletProvider;
  const CreateBudgetSheet({super.key, required this.walletProvider});

  @override
  State<CreateBudgetSheet> createState() => _CreateBudgetSheetState();
}

class _CreateBudgetSheetState extends State<CreateBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _targetController = TextEditingController();

  String _serviceType = 'Data';
  bool _isAutomatic = false;
  String _frequency = 'monthly';
  
  String _selectedProvider = '';
  Map<String, dynamic>? _selectedPackage;
  String _providerName = '';
  String _variationCode = '';

  // Data providers & packages
  final List<String> _dataProviders = ['MTN', 'Airtel', 'Glo', '9mobile', 'Smile', 'Spectranet'];
  final Map<String, List<Map<String, dynamic>>> _dataPackages = {
    'MTN': [
      {'name': 'MTN SME 500MB', 'amount': 150.0, 'code': '150.01'},
      {'name': 'MTN SME 1GB', 'amount': 290.0, 'code': '290.01'},
      {'name': 'MTN SME 2GB', 'amount': 580.0, 'code': '580.01'},
      {'name': 'MTN SME 5GB', 'amount': 1450.0, 'code': '1450.01'},
      {'name': 'MTN SME 10GB', 'amount': 2900.0, 'code': '2900.01'},
    ],
    'Airtel': [
      {'name': 'Airtel 1.5GB (30 Days)', 'amount': 1000.0, 'code': 'airtel-1000'},
      {'name': 'Airtel 3GB (30 Days)', 'amount': 1500.0, 'code': 'airtel-1500'},
      {'name': 'Airtel 10GB (30 Days)', 'amount': 3000.0, 'code': 'airtel-3000'},
    ],
    'Glo': [
      {'name': 'Glo 1.35GB (30 Days)', 'amount': 500.0, 'code': 'glo-500'},
      {'name': 'Glo 2.9GB (30 Days)', 'amount': 1000.0, 'code': 'glo-1000'},
      {'name': 'Glo 5.8GB (30 Days)', 'amount': 2000.0, 'code': 'glo-2000'},
    ],
    '9mobile': [
      {'name': '9mobile 1.5GB (30 Days)', 'amount': 1000.0, 'code': '9mobile-1000'},
      {'name': '9mobile 3GB (30 Days)', 'amount': 1500.0, 'code': '9mobile-1500'},
    ],
    'Smile': [
      {'name': 'Smile 1GB (30 Days)', 'amount': 1000.0, 'code': 'smile-1000'},
    ],
    'Spectranet': [
      {'name': 'Spectranet 5GB (30 Days)', 'amount': 2000.0, 'code': 'spectranet-5000'},
    ],
  };

  // Cable TV providers & packages
  final List<String> _cableProviders = ['DSTV', 'GOtv', 'StarTimes'];
  final Map<String, List<Map<String, dynamic>>> _cablePackages = {
    'DSTV': [
      {'name': 'DSTV Padi', 'amount': 2500.0, 'code': 'dstv-padi'},
      {'name': 'DSTV Yanga', 'amount': 3500.0, 'code': 'dstv-yanga'},
      {'name': 'DSTV Confam', 'amount': 6200.0, 'code': 'dstv-confam'},
      {'name': 'DSTV Compact', 'amount': 10500.0, 'code': 'dstv79'},
      {'name': 'DSTV Compact Plus', 'amount': 16600.0, 'code': 'dstv7'},
      {'name': 'DSTV Premium', 'amount': 24500.0, 'code': 'dstv3'},
    ],
    'GOtv': [
      {'name': 'GOtv Lite', 'amount': 1100.0, 'code': 'gotv-lite'},
      {'name': 'GOtv Jinja', 'amount': 2250.0, 'code': 'gotv-jinja'},
      {'name': 'GOtv Jolli', 'amount': 3300.0, 'code': 'gotv-jolli'},
      {'name': 'GOtv Max', 'amount': 4850.0, 'code': 'gotv-max'},
      {'name': 'GOtv Supa', 'amount': 6400.0, 'code': 'gotv-supa-plus'},
    ],
    'StarTimes': [
      {'name': 'StarTimes Nova', 'amount': 1200.0, 'code': 'nova'},
      {'name': 'StarTimes Basic', 'amount': 2600.0, 'code': 'basic'},
      {'name': 'StarTimes Smart', 'amount': 3500.0, 'code': 'smart'},
      {'name': 'StarTimes Classic', 'amount': 4500.0, 'code': 'classic'},
      {'name': 'StarTimes Super', 'amount': 4900.0, 'code': 'super'},
    ],
  };

  // Electricity providers
  final List<String> _electricityProviders = [
    'ikeja-electric',
    'eko-electric',
    'abuja-electric',
    'ibadan-electric',
    'kano-electric',
    'port-harcourt',
    'jos-electric',
    'kaduna-electric',
    'enugu-electric',
    'benin-electric'
  ];

  // Betting providers
  final List<String> _bettingProviders = [
    'betway',
    'bang-bet',
    'bet-way',
    'bet-land',
    'bet-king',
    '1x-bet',
    'naija-bet',
    'sporty-bet',
    'merry-bet'
  ];

  // WAEC packages
  final List<Map<String, dynamic>> _waecPackages = [
    {'name': 'WAEC Result Checker PIN', 'amount': 3200.0, 'code': 'waecdirect'},
    {'name': 'WAEC Registration PIN', 'amount': 18000.0, 'code': 'waec-registration'},
  ];

  // JAMB packages
  final List<Map<String, dynamic>> _jambPackages = [
    {'name': 'JAMB UTME PIN (No Mock)', 'amount': 4700.0, 'code': 'utme-no-mock'},
    {'name': 'JAMB UTME PIN (With Mock)', 'amount': 5700.0, 'code': 'utme-mock'},
    {'name': 'JAMB Direct Entry PIN', 'amount': 4700.0, 'code': 'de'},
  ];

  bool _isLoadingLiveVariations = false;
  List<Map<String, dynamic>>? _liveVariations;

  @override
  void initState() {
    super.initState();
    _targetController.addListener(_onTargetChanged);
  }

  @override
  void dispose() {
    _targetController.removeListener(_onTargetChanged);
    _titleController.dispose();
    _amountController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  /// Returns the correct dropdown popup background color for light/dark mode.
  Color get _ddColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1B2420) : Colors.white;
  }

  /// Returns the correct text style for dropdown items in light/dark mode.
  TextStyle get _ddStyle {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      color: isDark ? const Color(0xFFF0F4F2) : const Color(0xFF1A1A1A),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
  }

  void _onTargetChanged() {
    if (_serviceType != 'Data') return;
    final phone = _targetController.text.trim();
    String processed = phone;
    if (processed.startsWith('+234')) {
      processed = '0' + processed.substring(4);
    }
    if (processed.length >= 4) {
      final prefix = processed.substring(0, 4);
      final detected = _detectNetwork(prefix);
      if (detected != null && detected != _selectedProvider) {
        setState(() {
          _selectedProvider = detected;
          _providerName = detected.toLowerCase();
          _selectedPackage = null;
          _amountController.clear();
        });
        _fetchLiveVariations();
      }
    }
  }

  String? _detectNetwork(String prefix) {
    const mtn = ['0703', '0706', '0803', '0806', '0810', '0813', '0814', '0816', '0903', '0906', '0913', '0916'];
    const airtel = ['0701', '0708', '0802', '0808', '0812', '0901', '0902', '0904', '0907', '0912'];
    const glo = ['0705', '0805', '0807', '0811', '0815', '0905', '0915'];
    const etisalat = ['0809', '0817', '0818', '0908', '0909'];

    if (mtn.contains(prefix)) return 'MTN';
    if (airtel.contains(prefix)) return 'Airtel';
    if (glo.contains(prefix)) return 'Glo';
    if (etisalat.contains(prefix)) return '9mobile';
    return null;
  }

  Future<void> _fetchLiveVariations() async {
    if (_selectedProvider.isEmpty) return;
    if (_serviceType != 'Data' && _serviceType != 'Cable TV') return;

    setState(() {
      _isLoadingLiveVariations = true;
      _liveVariations = null;
      _selectedPackage = null;
    });

    try {
      final variations = await VtPassService.fetchVariations(_selectedProvider, _serviceType);
      if (mounted) {
        setState(() {
          _isLoadingLiveVariations = false;
          if (variations != null && variations.isNotEmpty) {
            _liveVariations = variations.map<Map<String, dynamic>>((v) => {
              'name': v['name'],
              'amount': v['variation_amount'],
              'code': v['variation_code'],
            }).toList();
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch variations in sheet: $e');
      if (mounted) {
        setState(() {
          _isLoadingLiveVariations = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getCurrentPackages() {
    if (_liveVariations != null && _liveVariations!.isNotEmpty) {
      return _liveVariations!;
    }
    if (_serviceType == 'Data') {
      return _dataPackages[_selectedProvider] ?? [];
    } else if (_serviceType == 'Cable TV') {
      return _cablePackages[_selectedProvider] ?? [];
    }
    return [];
  }

  void _onServiceTypeChanged(String val) {
    setState(() {
      _serviceType = val;
      _selectedProvider = '';
      _selectedPackage = null;
      _amountController.clear();
      _providerName = '';
      _variationCode = '';
      _liveVariations = null;

      if (_serviceType == 'WAEC') {
        _providerName = 'waec';
      } else if (_serviceType == 'JAMB') {
        _providerName = 'jamb';
      }
    });
  }

  void _selectPackage(Map<String, dynamic> pkg) {
    setState(() {
      _selectedPackage = pkg;
      _variationCode = pkg['code'];
      // Prefill amount field to package cost, but let user increase it to lock more if they want!
      _amountController.text = pkg['amount'].toString();
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = '${pkg['name']} Budget';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    if (amount > widget.walletProvider.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient available balance to fund this budget.')),
      );
      return;
    }

    final double? subCost = _selectedPackage != null ? (_selectedPackage!['amount'] as double) : amount;

    final success = await widget.walletProvider.createBudget(
      title: _titleController.text.trim(),
      amount: amount,
      serviceType: _serviceType,
      providerName: _providerName.isNotEmpty ? _providerName : null,
      target: _targetController.text.isNotEmpty ? _targetController.text.trim() : null,
      variationCode: _variationCode.isNotEmpty ? _variationCode : null,
      isAutomatic: _isAutomatic,
      frequency: _frequency,
      subscriptionCost: subCost,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget created and funds locked successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = MediaQuery.of(context).viewInsets;
    final packagesList = _getCurrentPackages();

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E201E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Lock Budget & Funds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Service Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _serviceType,
                dropdownColor: _ddColor,
                style: _ddStyle,
                decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.listTodo)),
                items: ['Data', 'Cable TV', 'Electricity', 'Betting', 'WAEC', 'JAMB'].map((e) {
                  return DropdownMenuItem<String>(value: e, child: Text(e));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    _onServiceTypeChanged(val);
                  }
                },
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Automatic Renewal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Vends service automatically when time comes'),
                value: _isAutomatic,
                onChanged: (val) {
                  setState(() {
                    _isAutomatic = val;
                  });
                },
              ),
              if (_isAutomatic) ...[
                const SizedBox(height: 16),
                const Text('Vending Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _frequency,
                  dropdownColor: _ddColor,
                  style: _ddStyle,
                  decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.calendar)),
                  items: ['daily', 'weekly', 'monthly'].map((e) {
                    return DropdownMenuItem<String>(value: e, child: Text(e.toUpperCase()));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _frequency = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Destination Target ID (Phone / Meter / Wallet ID)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _targetController,
                  decoration: InputDecoration(
                    hintText: _serviceType == 'Data'
                        ? 'Enter phone number (auto-selects provider)'
                        : 'Enter recipient account ID',
                    prefixIcon: const Icon(LucideIcons.phone),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Destination Target is required' : null,
                ),
                const SizedBox(height: 16),
              ],

              // Dynamic fields based on service type selection
              if (_isAutomatic && _serviceType == 'Data') ...[
                const Text('Data Network Provider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedProvider.isEmpty ? null : _selectedProvider,
                  hint: const Text('Select Provider'),
                  dropdownColor: _ddColor,
                  style: _ddStyle,
                  decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.wifi)),
                  items: _dataProviders.map((e) {
                    return DropdownMenuItem<String>(value: e, child: Text(e));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedProvider = val;
                        _providerName = val.toLowerCase();
                        _selectedPackage = null;
                        _amountController.clear();
                      });
                      _fetchLiveVariations();
                    }
                  },
                  validator: (value) => value == null ? 'Network provider is required' : null,
                ),
                const SizedBox(height: 16),
                if (_selectedProvider.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Data Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (_isLoadingLiveVariations)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryForest),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedPackage,
                    hint: Text(_isLoadingLiveVariations ? 'Loading live plans...' : 'Select Package Plan'),
                    dropdownColor: _ddColor,
                    style: _ddStyle,
                    decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.barChart2)),
                    items: packagesList.map((pkg) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: pkg,
                        child: Text('${pkg['name']} (${CurrencyFormatter.format(pkg['amount'])})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _selectPackage(val);
                      }
                    },
                    validator: (value) => value == null ? 'Data plan is required' : null,
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              if (_isAutomatic && _serviceType == 'Cable TV') ...[
                const Text('Cable TV Biller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedProvider.isEmpty ? null : _selectedProvider,
                  hint: const Text('Select TV Provider'),
                  dropdownColor: _ddColor,
                  style: _ddStyle,
                  decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.tv)),
                  items: _cableProviders.map((e) {
                    return DropdownMenuItem<String>(value: e, child: Text(e));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedProvider = val;
                        _providerName = val.toLowerCase();
                        _selectedPackage = null;
                        _amountController.clear();
                      });
                      _fetchLiveVariations();
                    }
                  },
                  validator: (value) => value == null ? 'Biller provider is required' : null,
                ),
                const SizedBox(height: 16),
                if (_selectedProvider.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cable Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (_isLoadingLiveVariations)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryForest),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedPackage,
                    hint: Text(_isLoadingLiveVariations ? 'Loading live plans...' : 'Select Subscription Bouquet'),
                    dropdownColor: _ddColor,
                    style: _ddStyle,
                    decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.listTodo)),
                    items: packagesList.map((pkg) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: pkg,
                        child: Text('${pkg['name']} (${CurrencyFormatter.format(pkg['amount'])})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _selectPackage(val);
                      }
                    },
                    validator: (value) => value == null ? 'Bouquet plan is required' : null,
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              if (_isAutomatic && _serviceType == 'Electricity') ...[
                const Text('Electricity Biller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedProvider.isEmpty ? null : _selectedProvider,
                  hint: const Text('Select Electricity Disco'),
                  dropdownColor: _ddColor,
                  style: _ddStyle,
                  decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.zap)),
                  items: _electricityProviders.map((e) {
                    return DropdownMenuItem<String>(value: e, child: Text(e.replaceAll("-", " ").toUpperCase()));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedProvider = val;
                        _providerName = val;
                        if (_titleController.text.trim().isEmpty) {
                          _titleController.text = '${val.replaceAll("-", " ").toUpperCase()} Budget';
                        }
                      });
                    }
                  },
                  validator: (value) => value == null ? 'Electricity Biller is required' : null,
                ),
                const SizedBox(height: 16),
                const Text('Meter Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _variationCode.isEmpty ? 'prepaid' : _variationCode,
                  dropdownColor: _ddColor,
                  style: _ddStyle,
                  decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.activity)),
                  items: const [
                    DropdownMenuItem(value: 'prepaid', child: Text('Prepaid')),
                    DropdownMenuItem(value: 'postpaid', child: Text('Postpaid')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _variationCode = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (_isAutomatic && _serviceType == 'Betting') ...[
                const Text('Betting Company', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedProvider.isEmpty ? null : _selectedProvider,
                  hint: const Text('Select Betting Biller'),
                  dropdownColor: _ddColor,
                  style: _ddStyle,
                  decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.gamepad2)),
                  items: _bettingProviders.map((e) {
                    return DropdownMenuItem<String>(value: e, child: Text(e.toUpperCase()));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedProvider = val;
                        _providerName = val;
                        if (_titleController.text.trim().isEmpty) {
                          _titleController.text = '${val.toUpperCase()} Wallet Budget';
                        }
                      });
                    }
                  },
                  validator: (value) => value == null ? 'Betting company is required' : null,
                ),
                const SizedBox(height: 16),
              ],

              if (_isAutomatic && _serviceType == 'WAEC') ...[
                const Text('Exam Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedPackage,
                  hint: const Text('Select Checker/Reg Package'),
                  dropdownColor: _ddColor,
                  style: _ddStyle,
                  decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.graduationCap)),
                  items: _waecPackages.map((pkg) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: pkg,
                      child: Text('${pkg['name']} (${CurrencyFormatter.format(pkg['amount'])})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      _selectPackage(val);
                    }
                  },
                  validator: (value) => value == null ? 'Package is required' : null,
                ),
                const SizedBox(height: 16),
              ],

              if (_isAutomatic && _serviceType == 'JAMB') ...[
                const Text('Exam Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedPackage,
                  hint: const Text('Select JAMB Package'),
                  dropdownColor: _ddColor,
                  style: _ddStyle,
                  decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.award)),
                  items: _jambPackages.map((pkg) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: pkg,
                      child: Text('${pkg['name']} (${CurrencyFormatter.format(pkg['amount'])})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      _selectPackage(val);
                    }
                  },
                  validator: (value) => value == null ? 'Package is required' : null,
                ),
                const SizedBox(height: 16),
              ],

              const Text('Budget Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. MTN weekly data reserve',
                  prefixIcon: Icon(LucideIcons.fileText),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              const Text('Total Locked Reserve Sum (₦)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter sum to lock (e.g. 200000)',
                  prefixIcon: Icon(LucideIcons.coins),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Amount is required';
                  final val = double.tryParse(value.trim()) ?? 0.0;
                  if (val <= 0.0) return 'Invalid amount';
                  if (_selectedPackage != null) {
                    final pkgAmount = _selectedPackage!['amount'] as double;
                    if (val < pkgAmount) {
                      return 'Must lock at least package price (${CurrencyFormatter.format(pkgAmount)})';
                    }
                  }
                  return null;
                },
              ),
              if (_selectedPackage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentLime.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info, size: 16, color: AppColors.primaryForest),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${CurrencyFormatter.format(_selectedPackage!['amount'])} will be deducted from this budget per vending execution.',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryForest),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryForest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Create & Lock Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
