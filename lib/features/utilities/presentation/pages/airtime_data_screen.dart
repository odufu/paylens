import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/utils/currency_formatter.dart';
import 'package:mspay/core/presentation/widgets/branded_spinner.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/wallet/data/models/transaction_model.dart';
import 'package:mspay/features/utilities/data/datasources/vtpass_service.dart';
import 'package:mspay/features/utilities/presentation/widgets/receipt_modal.dart';

class AirtimeDataScreen extends StatefulWidget {
  final bool isData;
  final String? initialProvider;
  const AirtimeDataScreen({
    super.key,
    required this.isData,
    this.initialProvider,
  });

  @override
  State<AirtimeDataScreen> createState() => _AirtimeDataScreenState();
}

class _AirtimeDataScreenState extends State<AirtimeDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String _selectedProvider = 'MTN';
  late bool _isDataTab;
  Map<String, dynamic>? _selectedDataPackage;
  bool _isProcessing = false;
  List<String> _recentNumbers = [];
  String _selectedCategory = 'Monthly';

  final List<String> _categories = [
    'Monthly',
    'SME Data',
    'Daily/Weekly',
    'Corporate Gifting',
  ];

  final List<Map<String, dynamic>> _providers = [
    {
      'name': 'MTN',
      'color': const Color(0xFFFFCC00),
      'textColor': Colors.black,
    },
    {
      'name': 'Airtel',
      'color': const Color(0xFFFF0000),
      'textColor': Colors.white,
    },
    {
      'name': 'Glo',
      'color': const Color(0xFF00FF00),
      'textColor': Colors.black,
    },
    {
      'name': '9mobile',
      'color': const Color(0xFF006644),
      'textColor': Colors.white,
    },
  ];

  List<Map<String, dynamic>> _getFilteredPackages() {
    final provider = _selectedProvider.toLowerCase();

    if (_selectedCategory == 'SME Data') {
      if (provider == 'mtn') {
        return [
          {
            'id': 'mtn-sme-1',
            'name': 'MTN 1GB SME (30 Days)',
            'amount': 250.0,
            'variation': 'mtn-sme-1gb',
            'duration': '30 Days',
          },
          {
            'id': 'mtn-sme-2',
            'name': 'MTN 2GB SME (30 Days)',
            'amount': 500.0,
            'variation': 'mtn-sme-2gb',
            'duration': '30 Days',
          },
          {
            'id': 'mtn-sme-5',
            'name': 'MTN 5GB SME (30 Days)',
            'amount': 1250.0,
            'variation': 'mtn-sme-5gb',
            'duration': '30 Days',
          },
          {
            'id': 'mtn-sme-10',
            'name': 'MTN 10GB SME (30 Days)',
            'amount': 2500.0,
            'variation': 'mtn-sme-10gb',
            'duration': '30 Days',
          },
          {
            'id': 'mtn-sme-25',
            'name': 'MTN 25GB SME (30 Days)',
            'amount': 10000.0,
            'variation': 'mtn-25gb-sme-10000',
            'duration': '30 Days',
          },
        ];
      } else if (provider == 'airtel') {
        return [
          {
            'id': 'art-sme-1',
            'name': 'Airtel 1GB SME (30 Days)',
            'amount': 260.0,
            'variation': 'airtel-sme-1gb',
            'duration': '30 Days',
          },
          {
            'id': 'art-sme-2',
            'name': 'Airtel 2GB SME (30 Days)',
            'amount': 520.0,
            'variation': 'airtel-sme-2gb',
            'duration': '30 Days',
          },
          {
            'id': 'art-sme-5',
            'name': 'Airtel 5GB SME (30 Days)',
            'amount': 1300.0,
            'variation': 'airtel-sme-5gb',
            'duration': '30 Days',
          },
        ];
      }
      return [
        {
          'id': '${provider}-sme-1',
          'name': '$_selectedProvider 1GB SME',
          'amount': 280.0,
          'variation': '${provider}-sme-1gb',
          'duration': '30 Days',
        },
        {
          'id': '${provider}-sme-2',
          'name': '$_selectedProvider 2GB SME',
          'amount': 560.0,
          'variation': '${provider}-sme-2gb',
          'duration': '30 Days',
        },
      ];
    }

    if (_selectedCategory == 'Daily/Weekly') {
      if (provider == 'mtn') {
        return [
          {
            'id': 'mtn-d-100',
            'name': 'MTN 100MB (24 Hrs)',
            'amount': 100.0,
            'variation': 'mtn-10mb-100',
            'duration': '24 Hrs',
          },
          {
            'id': 'mtn-d-200',
            'name': 'MTN 200MB (2 Days)',
            'amount': 200.0,
            'variation': 'mtn-50mb-200',
            'duration': '2 Days',
          },
          {
            'id': 'mtn-w-6gb',
            'name': 'MTN 6GB (7 Days)',
            'amount': 1500.0,
            'variation': 'mtn-20hrs-1500',
            'duration': '7 Days',
          },
        ];
      }
      return [
        {
          'id': '${provider}-d-100',
          'name': '$_selectedProvider 100MB (24 Hrs)',
          'amount': 100.0,
          'variation': '${provider}-100mb-24h',
          'duration': '24 Hrs',
        },
        {
          'id': '${provider}-w-1gb',
          'name': '$_selectedProvider 1GB (7 Days)',
          'amount': 500.0,
          'variation': '${provider}-1gb-7d',
          'duration': '7 Days',
        },
      ];
    }

    if (_selectedCategory == 'Corporate Gifting') {
      return [
        {
          'id': '${provider}-cg-1',
          'name': '$_selectedProvider 1GB CG (30 Days)',
          'amount': 230.0,
          'variation': '${provider}-cg-1gb',
          'duration': '30 Days',
        },
        {
          'id': '${provider}-cg-2',
          'name': '$_selectedProvider 2GB CG (30 Days)',
          'amount': 460.0,
          'variation': '${provider}-cg-2gb',
          'duration': '30 Days',
        },
        {
          'id': '${provider}-cg-5',
          'name': '$_selectedProvider 5GB CG (30 Days)',
          'amount': 1150.0,
          'variation': '${provider}-cg-5gb',
          'duration': '30 Days',
        },
      ];
    }

    // Default: Monthly Plans
    if (provider == 'mtn') {
      return [
        {
          'id': 'mtn-m-1.5',
          'name': 'MTN 1.5GB Monthly',
          'amount': 1000.0,
          'variation': 'mtn-100mb-1000',
          'duration': '30 Days',
        },
        {
          'id': 'mtn-m-4.5',
          'name': 'MTN 4.5GB Monthly',
          'amount': 2000.0,
          'variation': 'mtn-500mb-2000',
          'duration': '30 Days',
        },
        {
          'id': 'mtn-m-6',
          'name': 'MTN 6GB Monthly',
          'amount': 2500.0,
          'variation': 'mtn-3gb-2500',
          'duration': '30 Days',
        },
        {
          'id': 'mtn-m-8',
          'name': 'MTN 8GB Monthly',
          'amount': 3000.0,
          'variation': 'mtn-data-3000',
          'duration': '30 Days',
        },
        {
          'id': 'mtn-m-10',
          'name': 'MTN 10GB Monthly',
          'amount': 3500.0,
          'variation': 'mtn-1gb-3500',
          'duration': '30 Days',
        },
        {
          'id': 'mtn-m-20',
          'name': 'MTN 20GB Monthly',
          'amount': 6000.0,
          'variation': 'mtn-3gb-6000',
          'duration': '30 Days',
        },
        {
          'id': 'mtn-m-40',
          'name': 'MTN 40GB Monthly',
          'amount': 10000.0,
          'variation': 'mtn-40gb-10000',
          'duration': '30 Days',
        },
      ];
    }

    return [
      {
        'id': '${provider}-m-1.5',
        'name': '$_selectedProvider 1.5GB Monthly',
        'amount': 1000.0,
        'variation': '${provider}-1-5gb',
        'duration': '30 Days',
      },
      {
        'id': '${provider}-m-3',
        'name': '$_selectedProvider 3GB Monthly',
        'amount': 1500.0,
        'variation': '${provider}-3gb',
        'duration': '30 Days',
      },
      {
        'id': '${provider}-m-10',
        'name': '$_selectedProvider 10GB Monthly',
        'amount': 3000.0,
        'variation': '${provider}-10gb',
        'duration': '30 Days',
      },
      {
        'id': '${provider}-m-20',
        'name': '$_selectedProvider 20GB Monthly',
        'amount': 5000.0,
        'variation': '${provider}-20gb',
        'duration': '30 Days',
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _isDataTab = widget.isData;
    if (widget.initialProvider != null) {
      _selectedProvider = widget.initialProvider!;
    }
    if (_isDataTab) {
      _selectedDataPackage = _getFilteredPackages().first;
    }
    _phoneController.addListener(_onPhoneChanged);
    _loadRecentNumbers();
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text.trim();
    String processed = phone;
    if (processed.startsWith('+234')) {
      processed = '0' + processed.substring(4);
    }
    if (processed.length >= 4) {
      final prefix = processed.substring(0, 4);
      final String? detectedProvider = _detectNetwork(prefix);
      if (detectedProvider != null && detectedProvider != _selectedProvider) {
        setState(() {
          _selectedProvider = detectedProvider;
          if (_isDataTab) {
            _selectedDataPackage = _getFilteredPackages().first;
          }
        });
      }
    }
  }

  String? _detectNetwork(String prefix) {
    const mtn = [
      '0703',
      '0706',
      '0803',
      '0806',
      '0810',
      '0813',
      '0814',
      '0816',
      '0903',
      '0906',
      '0913',
      '0916',
    ];
    const airtel = [
      '0701',
      '0708',
      '0802',
      '0808',
      '0812',
      '0901',
      '0902',
      '0904',
      '0907',
      '0912',
    ];
    const glo = ['0705', '0805', '0807', '0811', '0815', '0905', '0915'];
    const etisalat = ['0809', '0817', '0818', '0908', '0909'];

    if (mtn.contains(prefix)) return 'MTN';
    if (airtel.contains(prefix)) return 'Airtel';
    if (glo.contains(prefix)) return 'Glo';
    if (etisalat.contains(prefix)) return '9mobile';
    return null;
  }

  Future<void> _loadRecentNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _recentNumbers = prefs.getStringList('recent_phone_numbers') ?? [];
      });
    }
  }

  Future<void> _saveRecentNumber(String phone, String provider) async {
    final prefs = await SharedPreferences.getInstance();
    final record = '$phone:$provider';

    List<String> list = prefs.getStringList('recent_phone_numbers') ?? [];
    list.removeWhere((item) => item.startsWith('$phone:'));
    list.insert(0, record);

    if (list.length > 5) {
      list = list.sublist(0, 5);
    }

    await prefs.setStringList('recent_phone_numbers', list);
    if (mounted) {
      setState(() {
        _recentNumbers = list;
      });
    }
  }

  Future<void> _processPayment(WalletProvider walletProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final double amount = _isDataTab
        ? _selectedDataPackage!['amount']
        : double.parse(_amountController.text.trim());

    if (amount > walletProvider.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient wallet balance.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });
    BrandedLoadingOverlay.show(
      context,
      message: _isDataTab
          ? 'Processing data subscription...'
          : 'Processing airtime top-up...',
    );

    final purchaseResult = await VtPassService.purchaseProduct(
      serviceType: _isDataTab ? 'Data' : 'Airtime',
      target: _phoneController.text.trim(),
      amount: amount,
      providerName: _selectedProvider,
      packageName: _isDataTab ? _selectedDataPackage!['name'] : null,
      variationCode: _isDataTab ? _selectedDataPackage!['variation'] : null,
    );

    if (mounted) {
      if (purchaseResult.success) {
        final String serviceTitle = _isDataTab
            ? '$_selectedProvider Data Purchase'
            : '$_selectedProvider Airtime';
        final String serviceDetail = _isDataTab
            ? '${_selectedDataPackage!['name']} for ${_phoneController.text}'
            : 'Top-up for ${_phoneController.text}';

        final bool success = await walletProvider.payBill(
          amount: amount,
          serviceName: serviceTitle,
          billDetails: serviceDetail,
          category: TransactionCategory.bills,
        );

        if (mounted) {
          BrandedLoadingOverlay.hide(context);
          setState(() {
            _isProcessing = false;
          });

          if (success) {
            _saveRecentNumber(_phoneController.text.trim(), _selectedProvider);
            _selectedDataPackage = _getFilteredPackages().first; // Reset list
            ReceiptModal.show(
              context,
              serviceTitle: _isDataTab ? 'Mobile Data' : 'Airtime Top-up',
              recipient: _phoneController.text,
              amount: amount,
              transactionId: purchaseResult.transactionId ?? 'VTP-UNKNOWN',
              providerName: _selectedProvider,
            );
          }
        }
      } else {
        final errorMsg =
            purchaseResult.error ?? 'Transaction failed. Please try again.';
        final String serviceTitle = _isDataTab
            ? '$_selectedProvider Data Purchase'
            : '$_selectedProvider Airtime';
        final String serviceDetail = _isDataTab
            ? '${_selectedDataPackage!['name']} for ${_phoneController.text}'
            : 'Top-up for ${_phoneController.text}';

        final ticketId = await walletProvider.logFailedTransaction(
          amount: amount,
          serviceName: serviceTitle,
          billDetails: serviceDetail,
          category: TransactionCategory.bills,
          errorReason: errorMsg,
        );

        if (mounted) {
          BrandedLoadingOverlay.hide(context);
          setState(() {
            _isProcessing = false;
          });

          FailureDialog.show(
            context,
            title: 'Payment Failed',
            message: errorMsg,
            ticketId: ticketId ?? '#TKT-UNKNOWN',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isDataTab ? 'Buy Data Bundle' : 'Buy Airtime'),
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Toggle Slider (Airtime vs Data)
            Container(
              color: AppColors.primaryForest,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDataTab = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isDataTab
                                ? AppColors.accentLime
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Airtime',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isDataTab
                                  ? AppColors.textDark
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDataTab = true;
                            if (_selectedDataPackage == null) {
                              _selectedDataPackage =
                                  _getFilteredPackages().first;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isDataTab
                                ? AppColors.accentLime
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Mobile Data',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isDataTab
                                  ? AppColors.textDark
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Network Provider selection grid
                    Text(
                      'Select Provider Network',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _providers.map((p) {
                        final bool isSelected = _selectedProvider == p['name'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedProvider = p['name'];
                              if (_isDataTab) {
                                _selectedDataPackage =
                                    _getFilteredPackages().first;
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 76,
                            height: 60,
                            decoration: BoxDecoration(
                              color: p['color'],
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.primaryForest,
                                      width: 3,
                                    )
                                  : Border.all(color: Colors.transparent),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                p['name'],
                                style: TextStyle(
                                  color: p['textColor'],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_recentNumbers.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Recent Recipients',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recentNumbers.length,
                          itemBuilder: (context, index) {
                            final parts = _recentNumbers[index].split(':');
                            final phone = parts[0];
                            final provider = parts[1];
                            final provInfo = _providers.firstWhere(
                              (p) => p['name'] == provider,
                              orElse: () => _providers.first,
                            );

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ActionChip(
                                label: Text(
                                  phone,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : AppColors.textDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: provInfo['color'].withOpacity(
                                  0.12,
                                ),
                                side: BorderSide(
                                  color: provInfo['color'].withOpacity(0.4),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _phoneController.text = phone;
                                    _selectedProvider = provider;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Phone Number Input
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 14,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Phone Number',
                        hintText: 'e.g. 08149204910 or +2348149204910',
                        prefixIcon: Icon(LucideIcons.phone),
                        counterText: '',
                      ),
                      onChanged: (val) {
                        // Optional: Add prefix detection logic here
                      },
                      validator: (val) {
                        if (val == null) return 'Please enter a phone number';
                        final cleaned = val.trim().replaceAll(' ', '');
                        if (cleaned.startsWith('+234') &&
                            cleaned.length == 14) {
                          return null;
                        }
                        if (cleaned.length == 11 &&
                            RegExp(r'^\d+$').hasMatch(cleaned)) {
                          return null;
                        }
                        return 'Please enter a valid 11-digit or +234 phone number';
                      },
                    ),
                    const SizedBox(height: 20),

                    // Dynamic Amount or Package field
                    if (!_isDataTab) ...[
                      // Airtime amount field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Airtime Amount (₦)',
                          hintText: 'Enter top-up amount',
                          prefixIcon: Icon(LucideIcons.dollarSign),
                        ),
                        validator: (val) {
                          if (val == null ||
                              int.tryParse(val) == null ||
                              int.parse(val) < 50) {
                            return 'Minimum recharge is ₦50';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      // Category Selector ChoiceChips
                      Text(
                        'Select Category',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final bool isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.textDark
                                        : (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white70
                                              : AppColors.textGrey),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.accentLime,
                                backgroundColor:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withOpacity(0.06)
                                    : Colors.black.withOpacity(0.04),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.accentLime
                                      : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white12
                                            : AppColors.textLightGrey
                                                  .withOpacity(0.5)),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategory = cat;
                                      _selectedDataPackage =
                                          _getFilteredPackages().first;
                                    });
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Data Package Grid / List
                      Text(
                        'Select Data Plan',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _getFilteredPackages().length,
                        itemBuilder: (context, index) {
                          final pack = _getFilteredPackages()[index];
                          final bool isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          final bool isSelected =
                              _selectedDataPackage?['id'] == pack['id'];

                          final itemBgColor = isSelected
                              ? (isDark
                                    ? AppColors.accentLime.withOpacity(0.08)
                                    : AppColors.primaryForest.withOpacity(0.06))
                              : Theme.of(context).cardColor;

                          final itemBorderColor = isSelected
                              ? (isDark
                                    ? AppColors.accentLime
                                    : AppColors.primaryForest)
                              : (isDark
                                    ? Colors.white10
                                    : Colors.grey.shade300);

                          final itemTextColor = isSelected
                              ? (isDark
                                    ? AppColors.accentLime
                                    : AppColors.primaryForest)
                              : (isDark
                                    ? const Color(0xFFF0F4F2)
                                    : AppColors.textDark);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDataPackage = pack;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: itemBgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: itemBorderColor,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pack['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: itemTextColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        pack['duration'] ?? '30 Days',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    CurrencyFormatter.format(pack['amount']),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: itemTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Submit Purchase Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _processPayment(walletProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryForest,
                          foregroundColor: Colors.white,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.shoppingBag),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isDataTab
                                        ? 'Buy Bundle (${CurrencyFormatter.format(_selectedDataPackage?["amount"] ?? 0)})'
                                        : 'Pay Airtime',
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Available Balance: ${CurrencyFormatter.format(walletProvider.balance)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
