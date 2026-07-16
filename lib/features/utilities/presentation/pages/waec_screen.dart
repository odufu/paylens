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

class WaecScreen extends StatefulWidget {
  const WaecScreen({super.key});

  @override
  State<WaecScreen> createState() => _WaecScreenState();
}

class _WaecScreenState extends State<WaecScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedPackage = 'waecdirect';
  bool _isPaying = false;

  final Map<String, Map<String, dynamic>> _packages = {
    'waecdirect': {
      'name': 'WAEC Result Checker PIN',
      'amount': 2500.0,
    },
    'waec-registration': {
      'name': 'WAEC Registration PIN',
      'amount': 18000.0,
    },
  };

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment(WalletProvider walletProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final packageInfo = _packages[_selectedPackage]!;
    final double amount = packageInfo['amount'];
    final fee = walletProvider.cableFee; // standard vending fee
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
    BrandedLoadingOverlay.show(context, message: 'Processing e-PIN purchase...');

    final purchaseResult = await VtPassService.purchaseProduct(
      serviceType: 'WAEC',
      target: _phoneController.text.trim(),
      amount: amount,
      providerName: 'waec',
      packageName: packageInfo['name'],
      variationCode: _selectedPackage,
      phone: _phoneController.text.trim(),
    );

    if (mounted) {
      BrandedLoadingOverlay.hide(context);
      setState(() {
        _isPaying = false;
      });

      final String serviceTitle = packageInfo['name'];
      final String serviceDetail = 'Phone: ${_phoneController.text} • (Incl. Fee: ₦$fee)';

      if (purchaseResult.success) {
        final pinDetails = purchaseResult.carddetails ?? purchaseResult.token ?? 'Serial No & PIN sent via SMS';
        final bool success = await walletProvider.payBill(
          amount: totalDebit,
          serviceName: serviceTitle,
          billDetails: 'Phone: ${_phoneController.text} • Details: $pinDetails $serviceDetail',
          category: TransactionCategory.bills,
          vendorReference: purchaseResult.transactionId,
        );

        if (success && mounted) {
          ReceiptModal.show(
            context,
            serviceTitle: serviceTitle,
            recipient: _phoneController.text,
            amount: amount,
            transactionId: purchaseResult.transactionId ?? 'CK-UNKNOWN',
            providerName: 'WAEC',
            token: pinDetails, // Will show up beautifully in receipt token box!
          );
          _phoneController.clear();
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
            message: 'Your WAEC e-PIN purchase is being processed by the operator. Please do not retry. You can check status in transaction history.',
            ticketId: ticketId ?? '#TKT-UNKNOWN',
          );
          _phoneController.clear();
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
            title: 'Purchase Failed',
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
        title: const Text('Purchase WAEC e-PIN'),
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
                'Select e-PIN Package',
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
                    value: _selectedPackage,
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
                    items: _packages.keys.map((String key) {
                      final item = _packages[key]!;
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text('${item['name']} - ₦${CurrencyFormatter.format(item['amount'])}'),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedPackage = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recipient Phone Number',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'Enter Phone Number to receive PIN',
                  prefixIcon: Icon(LucideIcons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Recipient Phone Number is required';
                  }
                  if (value.trim().length < 10) {
                    return 'Please enter a valid phone number';
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
                    'Purchase e-PIN',
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
