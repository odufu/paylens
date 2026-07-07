import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/utils/currency_formatter.dart';
import 'package:mspay/core/presentation/widgets/branded_spinner.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/wallet/data/models/transaction_model.dart';
import 'package:mspay/features/utilities/data/datasources/vtpass_service.dart';
import 'package:mspay/features/utilities/presentation/widgets/receipt_modal.dart';

class CableTvScreen extends StatefulWidget {
  const CableTvScreen({super.key});

  @override
  State<CableTvScreen> createState() => _CableTvScreenState();
}

class _CableTvScreenState extends State<CableTvScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _smartcardController = TextEditingController();

  String _selectedProvider = 'DSTV';
  Map<String, dynamic>? _selectedPackage;
  
  bool _isValidating = false;
  bool _isVerified = false;
  String? _verifiedCustomerName;
  String? _currentPackage;
  String? _validationError;
  bool _isPaying = false;

  final Map<String, List<Map<String, dynamic>>> _providerPackages = {
    'DSTV': [
      {'name': 'DSTV Premium Package', 'amount': 24500.0},
      {'name': 'DSTV Compact Plus', 'amount': 16600.0},
      {'name': 'DSTV Compact Package', 'amount': 10500.0},
      {'name': 'DSTV Confam', 'amount': 6200.0},
    ],
    'GOTV': [
      {'name': 'GOtv Supa', 'amount': 6400.0},
      {'name': 'GOtv Max', 'amount': 4850.0},
      {'name': 'GOtv Jolli', 'amount': 3300.0},
      {'name': 'GOtv Jinja', 'amount': 2250.0},
    ],
    'StarTimes': [
      {'name': 'StarTimes Super Bouquet', 'amount': 4900.0},
      {'name': 'StarTimes Smart Bouquet', 'amount': 3000.0},
      {'name': 'StarTimes Nova Bouquet', 'amount': 1200.0},
    ],
  };

  @override
  void initState() {
    super.initState();
    _smartcardController.addListener(_onSmartcardChanged);
    _selectedPackage = _providerPackages[_selectedProvider]!.first;
  }

  @override
  void dispose() {
    _smartcardController.removeListener(_onSmartcardChanged);
    _smartcardController.dispose();
    super.dispose();
  }

  void _onSmartcardChanged() {
    final text = _smartcardController.text.trim();
    if (text.length == 11 && RegExp(r'^\d+$').hasMatch(text)) {
      _verifySmartcard(text);
    } else {
      if (_isVerified || _validationError != null) {
        setState(() {
          _isVerified = false;
          _verifiedCustomerName = null;
          _currentPackage = null;
          _validationError = null;
        });
      }
    }
  }

  Future<void> _verifySmartcard(String cardNo) async {
    setState(() {
      _isValidating = true;
      _validationError = null;
      _isVerified = false;
    });

    final result = await VtPassService.validateSmartcard(
      smartcardNumber: cardNo,
      provider: _selectedProvider,
    );

    if (mounted) {
      setState(() {
        _isValidating = false;
        if (result.isValid) {
          _isVerified = true;
          _verifiedCustomerName = result.customerName;
          _currentPackage = result.activePackage;
        } else {
          _validationError = result.error;
        }
      });
    }
  }

  Future<void> _submitPayment(WalletProvider walletProvider) async {
    if (!_formKey.currentState!.validate() || !_isVerified || _selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify the smartcard number and select a package.')),
      );
      return;
    }

    final double amount = _selectedPackage!['amount'];
    final fee = walletProvider.cableFee;
    final totalDebit = amount + fee;

    if (totalDebit > walletProvider.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient wallet balance.')),
      );
      return;
    }

    setState(() {
      _isPaying = true;
    });
    BrandedLoadingOverlay.show(context, message: 'Processing subscription...');

    final purchaseResult = await VtPassService.purchaseProduct(
      serviceType: 'Cable TV',
      target: _smartcardController.text.trim(),
      amount: amount,
      providerName: _selectedProvider,
      packageName: _selectedPackage!['name'],
    );

    if (mounted) {
      if (purchaseResult.success) {
        final bool success = await walletProvider.payBill(
          amount: totalDebit,
          serviceName: '$_selectedProvider Subscription',
          billDetails: 'Card: ${_smartcardController.text} • ${_selectedPackage!['name']} (Incl. Fee: ₦$fee)',
          category: TransactionCategory.bills,
        );

        if (success) {
          final earnedPoints = (amount * walletProvider.pointsRate).toInt();
          if (earnedPoints > 0) {
            await walletProvider.addLoyaltyPoints(earnedPoints);
          }
        }

        if (mounted) {
          BrandedLoadingOverlay.hide(context);
          setState(() {
            _isPaying = false;
          });

          if (success) {
            ReceiptModal.show(
              context,
              serviceTitle: '$_selectedProvider Subscription',
              recipient: '$_verifiedCustomerName (${_smartcardController.text})',
              amount: totalDebit,
              transactionId: purchaseResult.transactionId ?? 'VTP-UNKNOWN',
              providerName: 'VTPass',
            );
          }
        }
      } else {
        final errorMsg = purchaseResult.error ?? 'Transaction failed. Please try again.';
        
        final ticketId = await walletProvider.logFailedTransaction(
          amount: totalDebit,
          serviceName: '$_selectedProvider Subscription',
          billDetails: 'Card: ${_smartcardController.text} • ${_selectedPackage!['name']}',
          category: TransactionCategory.bills,
          errorReason: errorMsg,
        );

        if (mounted) {
          BrandedLoadingOverlay.hide(context);
          setState(() {
            _isPaying = false;
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
        title: const Text('Cable TV Subscription'),
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Cable Provider',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              
              // Provider selection Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _providerPackages.keys.map((prov) {
                  final bool isSelected = _selectedProvider == prov;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedProvider = prov;
                        _selectedPackage = _providerPackages[_selectedProvider]!.first;
                        if (_smartcardController.text.trim().length == 11) {
                          _verifySmartcard(_smartcardController.text.trim());
                        }
                      });
                    },
                    child: Container(
                      width: 100,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryForest : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryForest : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade300),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          prov,
                          style: TextStyle(
                            color: isSelected 
                                ? Colors.white 
                                : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF0F4F2) : AppColors.textDark),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              Text(
                'Subscriber Details',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Smartcard Number Input
              TextFormField(
                controller: _smartcardController,
                keyboardType: TextInputType.number,
                maxLength: 11,
                decoration: InputDecoration(
                  labelText: 'Smartcard / IUC / Decoder Number',
                  hintText: 'Enter 11-digit number',
                  prefixIcon: const Icon(LucideIcons.hash),
                  counterText: '',
                  suffixIcon: _isValidating
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.length != 11 || int.tryParse(val) == null) {
                    return 'Please enter a valid 11-digit smartcard number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Verification status display
              if (_isVerified)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.checkCircle, color: AppColors.successGreen, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Smartcard Validated',
                            style: TextStyle(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CUSTOMER: $_verifiedCustomerName',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'CURRENT PACKAGE: $_currentPackage',
                        style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),

              if (_validationError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: AppColors.errorRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: const TextStyle(
                            color: AppColors.errorRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Package selection selector
              if (_isVerified) ...[
                Text(
                  'Select Package Plan',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedPackage,
                  decoration: const InputDecoration(
                    labelText: 'Select Subscription Plan',
                    prefixIcon: Icon(LucideIcons.tv),
                  ),
                  items: _providerPackages[_selectedProvider]!.map((pack) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: pack,
                      child: Text('${pack['name']} - ${CurrencyFormatter.format(pack['amount'])}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPackage = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Price Breakdown Card
                if (_isVerified && _selectedPackage != null) ...[
                  Builder(
                    builder: (context) {
                      final amount = _selectedPackage!['amount'];
                      final fee = walletProvider.cableFee;
                      final total = amount + fee;
                      final earnedPoints = (amount * walletProvider.pointsRate).toInt();
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.02)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subscription Amount', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                                Text(CurrencyFormatter.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Convenience Fee', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                                Text(CurrencyFormatter.format(fee), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryForest)),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Debit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(CurrencyFormatter.format(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryForest)),
                              ],
                            ),
                            if (earnedPoints > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Rewards Earned', style: TextStyle(color: AppColors.successGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text('+$earnedPoints LensPoints', style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Confirm Payment Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isPaying ? null : () => _submitPayment(walletProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryForest,
                      foregroundColor: Colors.white,
                    ),
                    child: _isPaying
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
                              const Icon(LucideIcons.creditCard),
                              const SizedBox(width: 8),
                              Text('Renew Bouquet (${CurrencyFormatter.format(_selectedPackage?["amount"] ?? 0)})'),
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
            ],
          ),
        ),
      ),
    );
  }
}
