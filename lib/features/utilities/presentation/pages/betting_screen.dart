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

class BettingScreen extends StatefulWidget {
  const BettingScreen({super.key});

  @override
  State<BettingScreen> createState() => _BettingScreenState();
}

class _BettingScreenState extends State<BettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String _selectedProvider = 'BetKing';
  bool _isValidating = false;
  bool _isVerified = false;
  String? _verifiedCustomerName;
  String? _validationError;
  bool _isPaying = false;

  final Map<String, String> _providerCodes = {
    'BetKing': 'betking',
    'SportyBet': 'sportybet',
    '1xBet': '1xbet',
    'BetWay': 'betway',
    'Nairabet': 'nairabet',
    'BangBet': 'bangbet',
    'BetLand': 'betland',
    'NaijaBet': 'naijabet',
    'MerryBet': 'merrybet',
  };

  @override
  void initState() {
    super.initState();
    _customerIdController.addListener(_onCustomerIdChanged);
  }

  @override
  void dispose() {
    _customerIdController.removeListener(_onCustomerIdChanged);
    _customerIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onCustomerIdChanged() {
    final text = _customerIdController.text.trim();
    if (text.length >= 6 && RegExp(r'^\d+$').hasMatch(text)) {
      _verifyCustomerId(text);
    } else {
      if (_isVerified || _validationError != null) {
        setState(() {
          _isVerified = false;
          _verifiedCustomerName = null;
          _validationError = null;
        });
      }
    }
  }

  Future<void> _verifyCustomerId(String customerId) async {
    setState(() {
      _isValidating = true;
      _validationError = null;
      _isVerified = false;
    });

    final providerCode = _providerCodes[_selectedProvider]!;
    final result = await VtPassService.validateSmartcard(
      smartcardNumber: customerId,
      provider: providerCode,
    );

    if (mounted) {
      setState(() {
        _isValidating = false;
        if (result.isValid) {
          _isVerified = true;
          _verifiedCustomerName = result.customerName;
        } else {
          _validationError = result.error;
        }
      });
    }
  }

  Future<void> _submitPayment(WalletProvider walletProvider) async {
    if (!_formKey.currentState!.validate() || !_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify the Customer ID first.')),
      );
      return;
    }

    final double amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum funding amount is ₦100.')),
      );
      return;
    }

    final fee = walletProvider.cableFee; // Reuse same vending fee or config
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
    BrandedLoadingOverlay.show(context, message: 'Processing funding...');

    final providerCode = _providerCodes[_selectedProvider]!;
    final purchaseResult = await VtPassService.purchaseProduct(
      serviceType: 'Betting',
      target: _customerIdController.text.trim(),
      amount: amount,
      providerName: providerCode,
      packageName: 'Wallet Funding',
    );

    if (mounted) {
      BrandedLoadingOverlay.hide(context);
      setState(() {
        _isPaying = false;
      });

      final String serviceTitle = '$_selectedProvider Wallet Funding';
      final String serviceDetail = 'ID: ${_customerIdController.text} • ₦${CurrencyFormatter.format(amount)} (Fee: ₦$fee)';

      if (purchaseResult.success) {
        final bool success = await walletProvider.payBill(
          amount: totalDebit,
          serviceName: serviceTitle,
          billDetails: serviceDetail,
          category: TransactionCategory.bills,
          vendorReference: purchaseResult.transactionId,
        );

        if (success && mounted) {
          ReceiptModal.show(
            context,
            serviceTitle: 'Betting Funding',
            recipient: '${_customerIdController.text} ($_selectedProvider)',
            amount: amount,
            transactionId: purchaseResult.transactionId ?? 'CK-UNKNOWN',
            providerName: _selectedProvider,
          );
          _customerIdController.clear();
          _amountController.clear();
        }
      } else if (purchaseResult.isPending) {
        final ticketId = await walletProvider.logPendingTransaction(
          amount: totalDebit,
          serviceName: serviceTitle,
          billDetails: serviceDetail,
          category: TransactionCategory.bills,
          errorReason: purchaseResult.error ?? 'Transaction is pending network operator confirmation.',
          vendorReference: purchaseResult.transactionId,
        );

        if (mounted) {
          PendingDialog.show(
            context,
            title: 'Transaction Pending',
            message: 'Your betting wallet funding is being processed by the operator. Please do not retry. You can check status in transaction history.',
            ticketId: ticketId ?? '#TKT-UNKNOWN',
          );
          _customerIdController.clear();
          _amountController.clear();
        }
      } else {
        final errorMsg = purchaseResult.error ?? 'Transaction failed. Please try again.';
        final ticketId = await walletProvider.logFailedTransaction(
          amount: totalDebit,
          serviceName: serviceTitle,
          billDetails: serviceDetail,
          category: TransactionCategory.bills,
          errorReason: errorMsg,
          vendorReference: purchaseResult.transactionId,
        );

        if (mounted) {
          FailureDialog.show(
            context,
            title: 'Funding Failed',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Betting Wallet Funding'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Provider',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E201E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedProvider,
                    isExpanded: true,
                    dropdownColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1B2420)
                        : Colors.white,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFF0F4F2)
                          : const Color(0xFF1A1A1A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    items: _providerCodes.keys.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedProvider = newValue;
                          _isVerified = false;
                          _verifiedCustomerName = null;
                          _validationError = null;
                        });
                        if (_customerIdController.text.isNotEmpty) {
                          _verifyCustomerId(_customerIdController.text.trim());
                        }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Customer ID',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _customerIdController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Enter Betting Account Customer ID',
                  prefixIcon: const Icon(LucideIcons.user),
                  suffixIcon: _isValidating
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_isVerified
                          ? const Icon(LucideIcons.checkCircle2, color: AppColors.successGreen)
                          : null),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Customer ID is required';
                  }
                  return null;
                },
              ),
              if (_isVerified && _verifiedCustomerName != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verified Customer',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.successGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _verifiedCustomerName!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_validationError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _validationError!,
                  style: const TextStyle(color: AppColors.errorRed, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Amount',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixText: '₦ ',
                  prefixStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount < 100) {
                    return 'Minimum amount is ₦100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPaying ? null : () => _submitPayment(walletProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryForest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Fund Wallet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
