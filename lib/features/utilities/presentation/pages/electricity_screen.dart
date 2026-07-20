import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mspay/core/presentation/widgets/transaction_security_gate.dart';
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

class ElectricityScreen extends StatefulWidget {
  final BudgetModel? budget;
  const ElectricityScreen({super.key, this.budget});

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String _selectedDisco = 'IKEDC (Ikeja Electric)';
  String _discoCode = 'ikeja-electric';
  
  bool _isValidating = false;
  bool _isVerified = false;
  String? _verifiedCustomerName;
  String? _verifiedAddress;
  String? _validationError;
  bool _isPaying = false;
  bool _useCashback = false;

  final Map<String, String> _discos = {
    'IKEDC (Ikeja Electric)': 'ikeja-electric',
    'EKEDC (Eko Electric)': 'eko-electric',
    'AEDC (Abuja Electric)': 'abuja-electric',
    'IBEDC (Ibadan Electric)': 'ibadan-electric',
    'KEDCO (Kano Electric)': 'kano-electric',
    'PHED (Port Harcourt Electric)': 'port-harcourt',
  };

  @override
  void initState() {
    super.initState();
    _meterController.addListener(_onMeterChanged);
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _meterController.removeListener(_onMeterChanged);
    _amountController.removeListener(_onAmountChanged);
    _meterController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  void _onMeterChanged() {
    final text = _meterController.text.trim();
    if (text.length == 11 && RegExp(r'^\d+$').hasMatch(text)) {
      _verifyMeterNumber(text);
    } else {
      if (_isVerified || _validationError != null) {
        setState(() {
          _isVerified = false;
          _verifiedCustomerName = null;
          _verifiedAddress = null;
          _validationError = null;
        });
      }
    }
  }

  Future<void> _verifyMeterNumber(String meterNo) async {
    setState(() {
      _isValidating = true;
      _validationError = null;
      _isVerified = false;
    });

    // 1. Try to auto-detect the Disco provider first by validating across all available Discos in parallel
    final detectResult = await VtPassService.autoDetectDisco(meterNumber: meterNo);

    if (mounted) {
      if (detectResult != null) {
        final String detectedCode = detectResult['discoCode'];
        final MeterValidationResult validation = detectResult['validationResult'];
        
        // Find matching key for the dropdown UI
        final String detectedDisplayName = _discos.keys.firstWhere(
          (k) => _discos[k] == detectedCode,
          orElse: () => _discos.keys.first,
        );

        setState(() {
          _isValidating = false;
          _isVerified = true;
          _discoCode = detectedCode;
          _selectedDisco = detectedDisplayName;
          _verifiedCustomerName = validation.customerName;
          _verifiedAddress = validation.address;
        });
      } else {
        // 2. Fallback to validating the manually selected Disco if auto-detect fails
        final result = await VtPassService.validateMeter(
          meterNumber: meterNo,
          discoCode: _discoCode,
        );

        setState(() {
          _isValidating = false;
          if (result.isValid) {
            _isVerified = true;
            _verifiedCustomerName = result.customerName;
            _verifiedAddress = result.address;
          } else {
            _validationError = 'Meter number could not be auto-detected or verified. Please check the number or select your provider manually.';
          }
        });
      }
    }
  }

  Future<void> _submitPayment(WalletProvider walletProvider) async {
    if (!_formKey.currentState!.validate() || !_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify the meter number before payment.')),
      );
      return;
    }

    final double baseAmount = double.parse(_amountController.text.trim());
    final double amount = walletProvider.getElectricityPrice(baseAmount);
    final fee = walletProvider.electricityFee;
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

    final String reasonText;
    if (widget.budget != null) {
      reasonText = _useCashback && cashbackApplied > 0.0
          ? 'Authorize electricity payment of ₦$walletDeduction (Subsidized by ₦$cashbackApplied cashback) paid from budget ${widget.budget!.title}'
          : 'Authorize electricity payment of ₦$totalDebit paid from budget ${widget.budget!.title}';
    } else {
      reasonText = _useCashback && cashbackApplied > 0.0
          ? 'Authorize electricity payment of ₦$walletDeduction (Subsidized by ₦$cashbackApplied cashback) for meter ${_meterController.text.trim()}'
          : 'Authorize electricity payment of ₦$totalDebit for meter ${_meterController.text.trim()}';
    }

    final authorized = await TransactionSecurityGate.authorize(
      context,
      reason: reasonText,
    );
    if (!authorized) return;

    setState(() {
      _isPaying = true;
    });
    BrandedLoadingOverlay.show(context, message: 'Processing payment...');

    final purchaseResult = await VtPassService.purchaseProduct(
      serviceType: 'Electricity',
      target: _meterController.text.trim(),
      amount: baseAmount, // Base amount sent to VtPass!
      providerName: _discoCode,
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

      if (isActuallySuccess) {
        final bool success = await walletProvider.payBill(
          amount: totalDebit,
          serviceName: widget.budget != null ? widget.budget!.title : 'Electricity Bill ($_selectedDisco)',
          billDetails: widget.budget != null
              ? 'Meter: ${_meterController.text} • Customer: $_verifiedCustomerName (Incl. Fee: ₦$fee) (Paid from Budget: ${widget.budget!.title})'
              : (_useCashback && cashbackApplied > 0.0
                  ? 'Meter: ${_meterController.text} • Customer: $_verifiedCustomerName (Incl. Fee: ₦$fee) (Cashback Applied: ₦$cashbackApplied)'
                  : 'Meter: ${_meterController.text} • Customer: $_verifiedCustomerName (Incl. Fee: ₦$fee)'),
          category: TransactionCategory.bills,
          vendorReference: actualTransactionId,
          baseAmount: baseAmount,
          serviceType: 'electricity',
          providerName: _discoCode,
          cashbackApplied: cashbackApplied,
          isBudgetExecution: widget.budget != null,
        );

        if (success) {
          if (widget.budget != null) {
            await walletProvider.deductFromBudget(widget.budget!.id, totalDebit);
          } else {
            final earnedPoints = (amount * walletProvider.pointsRate).toInt();
            if (earnedPoints > 0) {
              await walletProvider.addLoyaltyPoints(earnedPoints);
            }
          }
        }

        if (mounted) {
          BrandedLoadingOverlay.hide(context);
          setState(() {
            _isPaying = false;
          });

          if (success) {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ReceiptModal(
                serviceTitle: 'Electricity Bill ($_selectedDisco)',
                recipient: '$_verifiedCustomerName (${_meterController.text})',
                amount: totalDebit,
                transactionId: actualTransactionId ?? 'CK-UNKNOWN',
                token: purchaseResult.token,
                providerName: 'ClubKonnect',
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
          serviceName: 'Electricity Bill ($_selectedDisco)',
          billDetails: 'Meter: ${_meterController.text} • Customer: $_verifiedCustomerName',
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
            message: 'Your payment is being processed by the operator. Please do not retry to avoid duplicate debit. You can check status in transaction history.',
            ticketId: ticketId ?? '#TKT-UNKNOWN',
          );
          if (mounted) {
            Navigator.of(context).pop(); // Go back to home
          }
        }
      } else {
        final errorMsg = actualError ?? 'Transaction failed. Please try again.';
        
        final ticketId = await walletProvider.logFailedTransaction(
          amount: totalDebit,
          serviceName: 'Electricity Bill ($_selectedDisco)',
          billDetails: 'Meter: ${_meterController.text} • Customer: $_verifiedCustomerName',
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
            title: 'Payment Failed',
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Electricity Bills'),
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
              // Info note about validation
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryForest.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryForest.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.shieldCheck, color: AppColors.primaryForest, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Meter verification is automated to prevent incorrect payments. Input exactly 11 digits to resolve account details.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryForest,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Payment Details',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Disco Select dropdown
              DropdownButtonFormField<String>(
                value: _selectedDisco,
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
                decoration: const InputDecoration(
                  labelText: 'Select Disco Provider',
                  prefixIcon: Icon(LucideIcons.zap),
                ),
                items: _discos.keys.map((name) {
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedDisco = val;
                      _discoCode = _discos[val]!;
                      // Re-trigger verification if meter number is 11 digits
                      if (_meterController.text.trim().length == 11) {
                        _verifyMeterNumber(_meterController.text.trim());
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Meter Number Input
              TextFormField(
                controller: _meterController,
                keyboardType: TextInputType.number,
                maxLength: 11,
                decoration: InputDecoration(
                  labelText: 'Meter Number',
                  hintText: 'Enter 11-digit meter number',
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
                    return 'Please enter a valid 11-digit meter number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Validation Result displays
              if (_isVerified)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.checkCircle, color: AppColors.successGreen, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Account Verified',
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
                        'ADDRESS: $_verifiedAddress',
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
                    color: AppColors.errorRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
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

              const SizedBox(height: 16),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                enabled: _isVerified,
                decoration: InputDecoration(
                  labelText: 'Amount (₦)',
                  hintText: _isVerified ? 'Enter billing amount' : 'Verify meter first',
                  prefixIcon: const Icon(LucideIcons.dollarSign),
                  fillColor: _isVerified 
                      ? Theme.of(context).cardColor 
                      : (Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withValues(alpha: 0.05) 
                          : Colors.grey.shade100),
                ),
                validator: (val) {
                  if (val == null || double.tryParse(val) == null) {
                    return 'Please enter a valid amount';
                  }
                  final parsedVal = double.parse(val);
                  if (parsedVal < 50) {
                    return 'Minimum amount is ₦50';
                  }
                  if (parsedVal > 200000) {
                    return 'Maximum amount is ₦200,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price Breakdown Card
              if (_isVerified && _amountController.text.trim().isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final baseAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
                    if (baseAmount > 0) {
                      final amount = walletProvider.getElectricityPrice(baseAmount);
                      final fee = walletProvider.electricityFee;
                      final total = amount + fee;
                      final earnedPoints = (amount * walletProvider.pointsRate).toInt();
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.02)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Vending Amount', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
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
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],

              Builder(
                builder: (context) {
                  final double baseAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
                  final double amount = walletProvider.getElectricityPrice(baseAmount);
                  final double fee = walletProvider.electricityFee;
                  final double totalAmount = baseAmount == 0.0 ? 0.0 : amount + fee;

                  final double cashbackApplied = _useCashback 
                      ? (totalAmount < walletProvider.cashbackBalance ? totalAmount : walletProvider.cashbackBalance)
                      : 0.0;
                  final double walletDeduction = totalAmount - cashbackApplied;

                  return Column(
                    children: [
                      if (_isVerified && totalAmount > 0.0) ...[
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
                      ],
                      // Pay Bill Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isPaying || !_isVerified ? null : () => _submitPayment(walletProvider),
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
                                    const Icon(LucideIcons.zap),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isVerified && totalAmount > 0.0
                                          ? 'Confirm Payment (${CurrencyFormatter.format(walletDeduction)})'
                                          : 'Confirm Payment',
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  );
                }
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
    );
  }
}
