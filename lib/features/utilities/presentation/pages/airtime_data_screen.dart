import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/utils/currency_formatter.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/wallet/data/models/transaction_model.dart';
import 'package:mspay/features/utilities/data/datasources/vtpass_simulator.dart';
import 'package:mspay/features/utilities/presentation/widgets/receipt_modal.dart';

class AirtimeDataScreen extends StatefulWidget {
  final bool isData;
  const AirtimeDataScreen({super.key, required this.isData});

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

  final List<Map<String, dynamic>> _providers = [
    {'name': 'MTN', 'color': const Color(0xFFFFCC00), 'textColor': Colors.black},
    {'name': 'Airtel', 'color': const Color(0xFFFF0000), 'textColor': Colors.white},
    {'name': 'Glo', 'color': const Color(0xFF00FF00), 'textColor': Colors.black},
    {'name': '9mobile', 'color': const Color(0xFF006644), 'textColor': Colors.white},
  ];

  final List<Map<String, dynamic>> _dataPackages = [
    {'id': 'd1', 'name': '1.5 GB Monthly', 'amount': 1200.0, 'duration': '30 Days'},
    {'id': 'd2', 'name': '3 GB Monthly', 'amount': 1600.0, 'duration': '30 Days'},
    {'id': 'd3', 'name': '10 GB Monthly', 'amount': 3500.0, 'duration': '30 Days'},
    {'id': 'd4', 'name': '20 GB Monthly', 'amount': 6000.0, 'duration': '30 Days'},
    {'id': 'd5', 'name': '40 GB Monthly', 'amount': 11000.0, 'duration': '30 Days'},
  ];

  @override
  void initState() {
    super.initState();
    _isDataTab = widget.isData;
    if (_isDataTab) {
      _selectedDataPackage = _dataPackages.first;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
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

    final purchaseResult = await VtPassSimulator.purchaseProduct(
      serviceType: _isDataTab ? 'Data' : 'Airtime',
      target: _phoneController.text.trim(),
      amount: amount,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

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

        if (success && mounted) {
          ReceiptModal.show(
            context,
            serviceTitle: _isDataTab ? 'Mobile Data' : 'Airtime Top-up',
            recipient: _phoneController.text,
            amount: amount,
            transactionId: purchaseResult.transactionId ?? 'VTP-UNKNOWN',
            providerName: _selectedProvider,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(purchaseResult.error ?? 'Transaction failed. Please try again.')),
        );
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
                            color: !_isDataTab ? AppColors.accentLime : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Airtime',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isDataTab ? AppColors.textDark : Colors.white,
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
                              _selectedDataPackage = _dataPackages.first;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isDataTab ? AppColors.accentLime : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Mobile Data',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isDataTab ? AppColors.textDark : Colors.white,
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
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
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
                                  ? Border.all(color: AppColors.primaryForest, width: 3)
                                  : Border.all(color: Colors.transparent),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))]
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
                    const SizedBox(height: 24),

                    // Phone Number Input
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Phone Number',
                        hintText: 'e.g. 08149204910',
                        prefixIcon: Icon(LucideIcons.phone),
                        counterText: '',
                      ),
                      validator: (val) {
                        if (val == null || val.length != 11 || !RegExp(r'^\d+$').hasMatch(val)) {
                          return 'Please enter a valid 11-digit phone number';
                        }
                        return null;
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
                          if (val == null || int.tryParse(val) == null || int.parse(val) < 50) {
                            return 'Minimum recharge is ₦50';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      // Data Package Grid / List
                      Text(
                        'Select Data Plan',
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _dataPackages.length,
                        itemBuilder: (context, index) {
                          final pack = _dataPackages[index];
                          final bool isSelected = _selectedDataPackage?['id'] == pack['id'];
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
                                color: isSelected 
                                    ? AppColors.primaryForest.withOpacity(0.06) 
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected 
                                      ? AppColors.primaryForest 
                                      : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade300),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pack['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? AppColors.primaryForest : AppColors.textDark,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        pack['duration'],
                                        style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    CurrencyFormatter.format(pack['amount']),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? AppColors.primaryForest : AppColors.textDark,
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
                        onPressed: _isProcessing ? null : () => _processPayment(walletProvider),
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
                        style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600),
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
