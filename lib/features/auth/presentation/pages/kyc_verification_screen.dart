import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/utils/currency_formatter.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/notifications/presentation/state/notification_provider.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _bvnController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _bvnController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)), // Minimum 16 years old
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryForest,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _verifyIdentity(WalletProvider walletProvider) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final success = await walletProvider.verifyBvnAndProvisionWallet(
        bvn: _bvnController.text.trim(),
        dob: _dobController.text.trim(),
      );

      if (success) {
        if (mounted) {
          Provider.of<NotificationProvider>(context, listen: false).addNotification(
            context,
            title: 'Identity Verification Successful',
            body: 'Your dedicated Paystack Wema Bank & Titan Trust accounts have been activated.',
            category: 'alerts',
          );
        }
        setState(() {
          _currentStep = 2; // Advance to success step
        });
      } else {
        setState(() {
          _errorMessage = 'Verification failed. Please check your BVN and Date of Birth details and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Verification', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        color: isDark ? const Color(0xFF0C1013) : const Color(0xFFF8F9FA),
        child: Column(
          children: [
            // STEP INDICATOR HEADERS
            if (_currentStep < 2) _buildStepIndicators(),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _currentStep == 0
                    ? _buildStep1Disclosure(textTheme, isDark)
                    : _currentStep == 1
                        ? _buildStep2Form(walletProvider, textTheme, isDark)
                        : _buildStep3Success(walletProvider, textTheme, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      color: AppColors.primaryForest.withValues(alpha: 0.05),
      child: Row(
        children: [
          _buildStepNode(0, 'Disclosure', _currentStep >= 0),
          _buildStepConnector(_currentStep >= 1),
          _buildStepNode(1, 'Verify ID', _currentStep >= 1),
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String label, bool isActive) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primaryForest : Colors.grey.shade400,
          ),
          alignment: Alignment.center,
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primaryForest : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: isActive ? AppColors.primaryForest : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildStep1Disclosure(TextTheme textTheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Your Identity',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'To generate your dedicated Wema and Titan Trust funding accounts, CBN guidelines require us to verify your Bank Verification Number (BVN).',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textGrey, height: 1.5),
        ),
        const SizedBox(height: 24),

        // NDPR / SECURITY CARD
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryForest.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryForest.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, color: AppColors.primaryForest, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Security Assurances',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryForest),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDisclosureBullet(
                icon: LucideIcons.lock,
                title: 'Fully Encrypted',
                subtitle: 'Your BVN data is sent securely using HTTPS to backend verification channels and is never saved locally.',
              ),
              const SizedBox(height: 12),
              _buildDisclosureBullet(
                icon: LucideIcons.ban,
                title: 'No Fund Access',
                subtitle: 'Entering your BVN does NOT give Pay Lenses access to your bank balance, account credentials, or funds.',
              ),
              const SizedBox(height: 12),
              _buildDisclosureBullet(
                icon: LucideIcons.checkCircle,
                title: 'Regulatory Compliance',
                subtitle: 'Strictly matching your BVN record details ensures compliance with Nigeria Anti-Money Laundering (AML) standards.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 1;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('I Understand, Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(width: 8),
                Icon(LucideIcons.arrowRight, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisclosureBullet({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryForest),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryForest)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textGrey, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Form(WalletProvider walletProvider, TextTheme textTheme, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Credentials',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please input your details exactly as they appear on your official bank registration documents.',
            style: TextStyle(color: AppColors.textGrey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),

          // BVN Input
          TextFormField(
            controller: _bvnController,
            keyboardType: TextInputType.number,
            maxLength: 11,
            decoration: const InputDecoration(
              labelText: 'Bank Verification Number (BVN)',
              hintText: 'Enter 11-digit BVN',
              prefixIcon: Icon(LucideIcons.hash),
              counterText: '',
            ),
            validator: (val) {
              if (val == null || val.length != 11 || int.tryParse(val) == null) {
                return 'Please enter a valid 11-digit Bank Verification Number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Date of Birth Input
          TextFormField(
            controller: _dobController,
            readOnly: true,
            onTap: () => _selectDate(context),
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
              hintText: 'YYYY-MM-DD',
              prefixIcon: Icon(LucideIcons.calendar),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please select your Date of Birth';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone Number Input
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Associated Phone Number',
              hintText: 'e.g. 08012345678',
              prefixIcon: Icon(LucideIcons.phone),
            ),
            validator: (val) {
              if (val == null || val.trim().length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: AppColors.errorRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.errorRed, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _verifyIdentity(walletProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryForest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Verify Identity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _isSubmitting ? null : () => setState(() => _currentStep = 0),
              child: const Text('Back to assurances', style: TextStyle(color: AppColors.primaryForest, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Success(WalletProvider walletProvider, TextTheme textTheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.successGreen,
          ),
          child: const Icon(LucideIcons.check, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 24),
        Text(
          'Verification Successful!',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Your identity has been verified successfully. Your dedicated bank accounts have been generated.',
          style: TextStyle(color: AppColors.textGrey, fontSize: 13, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Accounts list cards
        _buildSuccessAccountCard(
          bankName: walletProvider.paystackBankName,
          accountNumber: walletProvider.paystackAccountNumber,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildSuccessAccountCard(
          bankName: 'Titan Trust Bank',
          accountNumber: walletProvider.sterlingAccountNumber,
          isDark: isDark,
        ),
        const SizedBox(height: 48),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessAccountCard({
    required String bankName,
    required String accountNumber,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bankName.toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textGrey, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                accountNumber,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(color: AppColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
