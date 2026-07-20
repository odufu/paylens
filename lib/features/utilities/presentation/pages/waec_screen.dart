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
import 'package:mspay/core/presentation/widgets/cashback_toggle_widget.dart';

import 'package:mspay/features/wallet/data/models/budget_model.dart';

class WaecScreen extends StatefulWidget {
  final BudgetModel? budget;
  const WaecScreen({super.key, this.budget});

  @override
  State<WaecScreen> createState() => _WaecScreenState();
}

class _WaecScreenState extends State<WaecScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedPackage = 'waecdirect';
  bool _isPaying = false;
  bool _useCashback = false;

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
    final double totalDebit = amount + fee;
    final double cashbackApplied = _useCashback ? (totalDebit < walletProvider.cashbackBalance ? totalDebit : walletProvider.cashbackBalance) : 0.0;
    final double walletDeduction = totalDebit - cashbackApplied;

    if (widget.budget != null) {
      if (walletDeduction > widget.budget!.amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient budget pool balance.')),
        );
        return;
      }
    } else {
      if (walletDeduction > walletProvider.balance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient wallet balance.')),
        );
        return;
      }
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
      bool isActuallySuccess = purchaseResult.success;
      bool isActuallyPending = purchaseResult.isPending;
      String? actualTransactionId = purchaseResult.transactionId;
      String? actualError = purchaseResult.error;

      if (purchaseResult.isPending && purchaseResult.transactionId != null && purchaseResult.transactionId!.isNotEmpty) {
        int attempts = 0;
        const maxAttempts = 5;
        bool resolved = false;

        while (attempts < maxAttempts && !resolved) {
          if (!mounted) break;
          attempts++;
          BrandedLoadingOverlay.show(
            context,
            message: 'Verifying transaction status (attempt $attempts of $maxAttempts)...',
          );
          await Future.delayed(const Duration(seconds: 3));
          
          try {
            final res = await walletProvider.requeryTransaction(purchaseResult.transactionId!);
            if (res != null) {
              final status = res['status']?.toString().toLowerCase();
              final remark = res['remark']?.toString();
              if (status == 'success') {
                resolved = true;
                isActuallySuccess = true;
                isActuallyPending = false;
              } else if (status == 'failed') {
                resolved = true;
                isActuallySuccess = false;
                isActuallyPending = false;
                actualError = remark ?? 'Transaction failed.';
              }
            }
          } catch (e) {
            debugPrint('Error during status requery: $e');
          }
        }
      }

      final String serviceTitle = packageInfo['name'];
      final String serviceDetail = 'Phone: ${_phoneController.text} • (Incl. Fee: ₦$fee)';
      final String recipientPhone = _phoneController.text.trim();

      if (isActuallySuccess) {
        final pinDetails = purchaseResult.carddetails ?? purchaseResult.token ?? 'Serial No & PIN sent via SMS';
        final bool success = await walletProvider.payBill(
          amount: totalDebit,
          serviceName: widget.budget != null ? widget.budget!.title : serviceTitle,
          billDetails: widget.budget != null
              ? 'Phone: $recipientPhone • Details: $pinDetails $serviceDetail (Paid from Budget: ${widget.budget!.title})'
              : (_useCashback && cashbackApplied > 0.0
                  ? 'Phone: $recipientPhone • Details: $pinDetails $serviceDetail (Cashback Applied: ₦$cashbackApplied)'
                  : 'Phone: $recipientPhone • Details: $pinDetails $serviceDetail'),
          category: TransactionCategory.bills,
          vendorReference: actualTransactionId,
          cashbackApplied: cashbackApplied,
          isBudgetExecution: widget.budget != null,
        );

        if (success) {
          if (widget.budget != null) {
            await walletProvider.deductFromBudget(widget.budget!.id, totalDebit);
          }
        }

        if (mounted) {
          BrandedLoadingOverlay.hide(context);
          setState(() {
            _isPaying = false;
          });

          if (success) {
            _phoneController.clear();
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ReceiptModal(
                serviceTitle: serviceTitle,
                recipient: recipientPhone,
                amount: amount,
                transactionId: actualTransactionId ?? 'CK-UNKNOWN',
                providerName: 'WAEC',
                token: pinDetails,
              ),
            );
            if (mounted) {
              Navigator.of(context).pop(); // Go back to home
            }
          }
        }
      } else if (isActuallyPending) {
        final ticketId = await walletProvider.logPendingTransaction(
          amount: totalDebit,
          serviceName: serviceTitle,
          billDetails: serviceDetail,
          category: TransactionCategory.bills,
          errorReason: actualError ?? 'Transaction is pending network operator confirmation.',
          vendorReference: actualTransactionId,
        );

        if (mounted) {
          BrandedLoadingOverlay.hide(context);
          setState(() {
            _isPaying = false;
          });

          await PendingDialog.show(
            context,
            title: 'Transaction Pending',
            message: 'Your WAEC e-PIN purchase is being processed by the operator. Please do not retry. You can check status in transaction history.',
            ticketId: ticketId ?? '#TKT-UNKNOWN',
          );
          _phoneController.clear();
          if (mounted) {
            Navigator.of(context).pop(); // Go back to home
          }
        }
      } else {
        final errorMsg = actualError ?? 'Transaction failed. Please try again.';
        final ticketId = await walletProvider.logFailedTransaction(
          amount: totalDebit,
          serviceName: serviceTitle,
          billDetails: serviceDetail,
          category: TransactionCategory.bills,
          errorReason: errorMsg,
          vendorReference: actualTransactionId,
        );

        if (mounted) {
          BrandedLoadingOverlay.hide(context);
          setState(() {
            _isPaying = false;
          });

          await FailureDialog.show(
            context,
            title: 'Purchase Failed',
            message: errorMsg,
            ticketId: ticketId ?? '#TKT-UNKNOWN',
          );
          if (mounted) {
            Navigator.of(context).pop(); // Go back to home
          }
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
              if (widget.budget != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentLime.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentLime.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.briefcase, color: AppColors.primaryForest),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '💼 Paying from budget: ${widget.budget!.title} (Available: ₦${widget.budget!.amount})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryForest),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                        child: Text('${item['name']} - ${CurrencyFormatter.format(item['amount'])}'),
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
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final packageInfo = _packages[_selectedPackage]!;
                  final double amount = packageInfo['amount'];
                  final double fee = walletProvider.cableFee;
                  final double totalAmount = amount + fee;

                  final double cashbackApplied = _useCashback 
                      ? (totalAmount < walletProvider.cashbackBalance ? totalAmount : walletProvider.cashbackBalance)
                      : 0.0;
                  final double walletDeduction = totalAmount - cashbackApplied;

                  return Column(
                    children: [
                      CashbackToggleWidget(
                        totalAmount: totalAmount,
                        cashbackBalance: walletProvider.cashbackBalance,
                        value: _useCashback,
                        onChanged: (val) {
                          setState(() {
                            _useCashback = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
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
                          child: Text(
                            'Purchase e-PIN (${CurrencyFormatter.format(walletDeduction)})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
