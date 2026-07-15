import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/utils/currency_formatter.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/wallet/data/models/beneficiary_model.dart';
import 'package:mspay/features/utilities/presentation/widgets/receipt_modal.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNoController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrativeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String _selectedBank = 'Zenith Bank';
  bool _isValidatingAccount = false;
  bool _accountVerified = false;
  bool _isSending = false;

  final List<String> _nigerianBanks = [
    'Zenith Bank',
    'GTBank',
    'Access Bank',
    'United Bank for Africa (UBA)',
    'First Bank of Nigeria',
    'Fidelity Bank',
    'Wema Bank',
  ];

  @override
  void initState() {
    super.initState();
    _accountNoController.addListener(_onAccountNoChanged);
  }

  @override
  void dispose() {
    _accountNoController.removeListener(_onAccountNoChanged);
    _accountNoController.dispose();
    _amountController.dispose();
    _narrativeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onAccountNoChanged() {
    final text = _accountNoController.text.trim();
    if (text.length == 10 && RegExp(r'^\d+$').hasMatch(text)) {
      _simulateAccountNameResolve(text);
    } else {
      if (_accountVerified) {
        setState(() {
          _accountVerified = false;
          _nameController.clear();
        });
      }
    }
  }

  Future<void> _simulateAccountNameResolve(String accountNumber) async {
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    setState(() {
      _isValidatingAccount = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    // Check if matches default beneficiary
    final match = wallet.beneficiaries.where((b) => b.accountNumber == accountNumber);

    if (mounted) {
      setState(() {
        _isValidatingAccount = false;
        _accountVerified = true;
        if (match.isNotEmpty) {
          _nameController.text = match.first.name;
          _selectedBank = match.first.bankName;
        } else {
          // Mock verification name
          _nameController.text = 'Adewale Tunde Joseph';
        }
      });
    }
  }

  void _selectBeneficiary(BeneficiaryModel beneficiary) {
    setState(() {
      _accountNoController.text = beneficiary.accountNumber;
      _selectedBank = beneficiary.bankName;
      _nameController.text = beneficiary.name;
      _accountVerified = true;
    });
  }

  Future<void> _submitTransfer(WalletProvider walletProvider) async {
    if (!_formKey.currentState!.validate() || !_accountVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and enter a valid account.')),
      );
      return;
    }

    final double amount = double.parse(_amountController.text.trim());
    if (amount > walletProvider.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance to perform this transfer.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    final success = await walletProvider.transferMoney(
      amount: amount,
      beneficiaryName: _nameController.text,
      bankName: _selectedBank,
      accountNumber: _accountNoController.text,
      narrative: _narrativeController.text,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
      });

      if (success) {
        final refId = 'MNFY-${_accountNoController.text.hashCode.abs().toString().padRight(8, '4').substring(0, 8).toUpperCase()}';
        ReceiptModal.show(
          context,
          serviceTitle: 'Bank Transfer',
          recipient: '${_nameController.text} (${_accountNoController.text})',
          amount: amount,
          transactionId: refId,
          providerName: _selectedBank,
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
        title: const Text('Transfer Money'),
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // RECENT BENEFICIARIES HORIZONTAL CAROUSEL
            if (walletProvider.beneficiaries.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Recent Beneficiaries',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(
                height: 105,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: walletProvider.beneficiaries.length,
                  itemBuilder: (context, index) {
                    final b = walletProvider.beneficiaries[index];
                    return GestureDetector(
                      onTap: () => _selectBeneficiary(b),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 80,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                              child: Text(
                                b.initials,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              b.name.split(' ').first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 20),
            ],

            // TRANSFER FORM
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Details',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Bank Name Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedBank,
                      decoration: const InputDecoration(
                        labelText: 'Select Destination Bank',
                        prefixIcon: Icon(LucideIcons.building),
                      ),
                      items: _nigerianBanks.map((bank) {
                        return DropdownMenuItem<String>(
                          value: bank,
                          child: Text(bank),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedBank = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Account Number Input
                    TextFormField(
                      controller: _accountNoController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: InputDecoration(
                        labelText: 'Account Number',
                        hintText: 'Enter 10-digit account number',
                        prefixIcon: const Icon(LucideIcons.hash),
                        counterText: '',
                        suffixIcon: _isValidatingAccount
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
                        if (val == null || val.length != 10 || int.tryParse(val) == null) {
                          return 'Please enter a valid 10-digit account number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Verified Beneficiary Name Display
                    if (_accountVerified)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.checkCircle, color: AppColors.successGreen, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _nameController.text,
                                style: const TextStyle(
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Transfer Amount
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount (₦)',
                        hintText: '0.00',
                        prefixIcon: Icon(LucideIcons.dollarSign),
                      ),
                      validator: (val) {
                        if (val == null || double.tryParse(val) == null || double.parse(val) <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Optional Narrative
                    TextFormField(
                      controller: _narrativeController,
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: 'Narrative (Optional)',
                        hintText: 'e.g. For dinner bills',
                        prefixIcon: Icon(LucideIcons.alignLeft),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Send Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : () => _submitTransfer(walletProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryForest,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSending
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
                                  const Icon(LucideIcons.send),
                                  const SizedBox(width: 8),
                                  Text('Send ${walletProvider.isBalanceVisible ? "₦" : ""}${_amountController.text.isNotEmpty ? _amountController.text : "Money"}'),
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
