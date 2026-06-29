import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/utils/currency_formatter.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/wallet/data/models/transaction_model.dart';
import 'package:mspay/features/utilities/data/datasources/vtpass_simulator.dart';
import 'package:mspay/features/utilities/presentation/widgets/receipt_modal.dart';

class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({super.key});

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
  }

  @override
  void dispose() {
    _meterController.removeListener(_onMeterChanged);
    _meterController.dispose();
    _amountController.dispose();
    super.dispose();
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

    final result = await VtPassSimulator.validateMeter(
      meterNumber: meterNo,
      discoCode: _discoCode,
    );

    if (mounted) {
      setState(() {
        _isValidating = false;
        if (result.isValid) {
          _isVerified = true;
          _verifiedCustomerName = result.customerName;
          _verifiedAddress = result.address;
        } else {
          _validationError = result.error;
        }
      });
    }
  }

  Future<void> _submitPayment(WalletProvider walletProvider) async {
    if (!_formKey.currentState!.validate() || !_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify the meter number before payment.')),
      );
      return;
    }

    final double amount = double.parse(_amountController.text.trim());
    if (amount > walletProvider.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient wallet balance.')),
      );
      return;
    }

    setState(() {
      _isPaying = true;
    });

    final purchaseResult = await VtPassSimulator.purchaseProduct(
      serviceType: 'Electricity',
      target: _meterController.text.trim(),
      amount: amount,
    );

    if (mounted) {
      setState(() {
        _isPaying = false;
      });

      if (purchaseResult.success) {
        final bool success = await walletProvider.payBill(
          amount: amount,
          serviceName: 'Electricity Bill ($_selectedDisco)',
          billDetails: 'Meter: ${_meterController.text} • Customer: $_verifiedCustomerName',
          category: TransactionCategory.bills,
        );

        if (success && mounted) {
          ReceiptModal.show(
            context,
            serviceTitle: 'Electricity Bill ($_selectedDisco)',
            recipient: '$_verifiedCustomerName (${_meterController.text})',
            amount: amount,
            transactionId: purchaseResult.transactionId ?? 'VTP-UNKNOWN',
            token: purchaseResult.token,
            providerName: 'VTPass',
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
              // Info note about validation
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryForest.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryForest.withOpacity(0.15)),
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
                          ? Colors.white.withOpacity(0.05) 
                          : Colors.grey.shade100),
                ),
                validator: (val) {
                  if (val == null || double.tryParse(val) == null || double.parse(val) < 500) {
                    return 'Minimum amount is ₦500';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.zap),
                            SizedBox(width: 8),
                            Text('Confirm Payment'),
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
    );
  }
}
