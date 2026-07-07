import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';

class InAppDocumentationScreen extends StatelessWidget {
  const InAppDocumentationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Developer API Docs', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primaryForest,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.accentLime,
            labelColor: AppColors.accentLime,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Paystack'),
              Tab(text: 'VTPass'),
              Tab(text: 'Aimtoget'),
              Tab(text: 'Security Rules'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPaystackTab(context, textTheme, isDark),
            _buildVtPassTab(context, textTheme, isDark),
            _buildAimtogetTab(context, textTheme, isDark),
            _buildSecurityTab(context, textTheme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget child,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primaryForest, size: 24),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildParameterRow(String name, String type, String requiredStr, String description, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryForest,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  type,
                  style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
                ),
              ),
              const Spacer(),
              Text(
                requiredStr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: requiredStr == 'REQUIRED' ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String code, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.black38 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.4,
            color: isDark ? Colors.lightGreenAccent : Colors.green.shade900,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBox({
    required String text,
    required BuildContext context,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWarning
            ? Colors.red.withOpacity(0.08)
            : AppColors.accentLime.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning
              ? Colors.red.withOpacity(0.3)
              : AppColors.accentLime.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? LucideIcons.alertTriangle : LucideIcons.info,
            color: isWarning ? Colors.red : AppColors.primaryForest,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isWarning ? Colors.red.shade900 : AppColors.primaryForest,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: PAYSTACK ---
  Widget _buildPaystackTab(BuildContext context, TextTheme textTheme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDocCard(
          context: context,
          title: 'Paystack Wallet Services',
          subtitle: 'Handles instant virtual bank accounts & payment processing',
          icon: LucideIcons.creditCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We use Paystack primarily to automatically generate unique dedicated bank accounts for users. When bank transfers are made to these accounts, Paystack triggers webhook notifications to credit the user wallets instantly.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text('1. API ENDPOINT (CREATE DEDICATED ACCOUNT)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              _buildCodeBlock('POST /dedicated_account', context),
              const SizedBox(height: 16),
              const Text('REQUIRED API HEADERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              _buildCodeBlock(
                'Authorization: Bearer <Paystack_Secret_Key>\nContent-Type: application/json',
                context,
              ),
            ],
          ),
        ),
        _buildDocCard(
          context: context,
          title: 'Parameters Stated',
          subtitle: 'Required parameters to query Paystack dedicated accounts API',
          icon: LucideIcons.settings,
          child: Column(
            children: [
              _buildParameterRow('customer', 'String', 'REQUIRED', 'Customer ID or email representing the user.', context),
              _buildParameterRow('preferred_bank', 'String', 'OPTIONAL', 'Preferred partner bank code (e.g. wema-bank).', context),
              _buildParameterRow('first_name', 'String', 'REQUIRED', 'First name of the customer profile.', context),
              _buildParameterRow('last_name', 'String', 'REQUIRED', 'Last name of the customer profile.', context),
              _buildParameterRow('phone', 'String', 'REQUIRED', 'Contact number associated with user profile.', context),
            ],
          ),
        ),
        _buildDocCard(
          context: context,
          title: 'Security & Handling',
          subtitle: 'Best practices for securing Paystack keys',
          icon: LucideIcons.shieldCheck,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAlertBox(
                text: 'CRITICAL: Do NOT compile the Client Secret or API Key in the Dart application. All authentication tokens must be generated on a secure backend system and proxied.',
                context: context,
                isWarning: true,
              ),
              const SizedBox(height: 16),
              const Text('WEBHOOK SIGNATURE VERIFICATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              const Text(
                'When Paystack settles a wallet funding transaction, they call your backend listener. You MUST verify the header signature using HMAC-SHA512 to avoid simulated credit attacks:\n\n'
                'CalculatedHash = HMAC_SHA512(paystackSecretKey, requestBodyJson)\n\n'
                'Only proceed with crediting user balance if CalculatedHash matches the incoming request header "x-paystack-signature".',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 2: VTPASS ---
  Widget _buildVtPassTab(BuildContext context, TextTheme textTheme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDocCard(
          context: context,
          title: 'VTPass Services',
          subtitle: 'Utility bill payments (Airtime, Data, Electricity, Cable TV)',
          icon: LucideIcons.zap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VTPass powers all utility operations including airtime purchases, data bundle mapping, meter validations, and DSTV/GOTV subscriptions.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text('1. SERVICE VALIDATION ENDPOINT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              _buildCodeBlock('POST /api/merchant-verify', context),
              const SizedBox(height: 16),
              const Text('2. PURCHASE CHECKOUT ENDPOINT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              _buildCodeBlock('POST /api/pay', context),
            ],
          ),
        ),
        _buildDocCard(
          context: context,
          title: 'VTPass Parameters',
          subtitle: 'API request payload attributes',
          icon: LucideIcons.settings,
          child: Column(
            children: [
              _buildParameterRow('serviceID', 'String', 'REQUIRED', 'Vending category ID (e.g. mtn-data, eko-electric, dstv).', context),
              _buildParameterRow('billersCode', 'String', 'REQUIRED', 'The target meter number, phone number, or smartcard number.', context),
              _buildParameterRow('variation_code', 'String', 'OPTIONAL', 'Specific package ID code (e.g., gotv-lite, mtn-3gb-1500). Required for Data and TV.', context),
              _buildParameterRow('amount', 'Double', 'REQUIRED', 'Amount in Naira to vend/pay.', context),
              _buildParameterRow('phone', 'String', 'REQUIRED', 'The customer phone number receiving notifications.', context),
              _buildParameterRow('request_id', 'String', 'REQUIRED', 'Unique alphanumeric identifier starting with Lagostime (YYYYMMDDHHMM...).', context),
            ],
          ),
        ),
        _buildDocCard(
          context: context,
          title: 'VTPass Security & Keys',
          subtitle: 'Best practices for API keys',
          icon: LucideIcons.shieldCheck,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAlertBox(
                text: 'SECURITY NOTICE: Keep your VTPass API Key and Secret Key on a secure server environment variable. The app client should talk to a custom endpoint which appends headers before forwarding requests.',
                context: context,
                isWarning: true,
              ),
              const SizedBox(height: 16),
              const Text('REQUEST ID UNIQUENESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              const Text(
                'To prevent duplicate billing during connection drops, VTPass requires a strictly unique "request_id". It must follow the format:\n\n'
                'YYYYMMDDHHMM + 6 unique characters (e.g. 202607031445xyz123).\n\n'
                'If VTPass receives a duplicate request ID, it rejects the transaction automatically to prevent double-spending.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 3: AIMTOGET ---
  Widget _buildAimtogetTab(BuildContext context, TextTheme textTheme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDocCard(
          context: context,
          title: 'Aimtoget Airtime to Cash',
          subtitle: 'Automated conversion of carrier airtime to liquid bank deposits',
          icon: LucideIcons.repeat,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aimtoget API allows users to deposit carrier airtime (MTN, Airtel, Glo, 9mobile) to our system. Once confirmed, Aimtoget credits our merchant ledger and triggers webhook callbacks to fund the user wallet.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text('1. INIT TRANSACTION ENDPOINT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              _buildCodeBlock('POST /api/v1/airtime/transfer', context),
            ],
          ),
        ),
        _buildDocCard(
          context: context,
          title: 'Aimtoget Parameters',
          subtitle: 'Parameters to query carrier airtime liquidator API',
          icon: LucideIcons.settings,
          child: Column(
            children: [
              _buildParameterRow('network', 'String', 'REQUIRED', 'Carrier name (mtn, airtel, glo, 9mobile).', context),
              _buildParameterRow('phoneNumber', 'String', 'REQUIRED', 'Sender phone number from which airtime will be transferred.', context),
              _buildParameterRow('amount', 'Double', 'REQUIRED', 'Face value of the airtime to convert.', context),
              _buildParameterRow('recipient', 'String', 'REQUIRED', 'Merchant target number provided by API during initiation.', context),
              _buildParameterRow('pin', 'String', 'OPTIONAL', 'User SIM card transfer PIN (if required to trigger transfer via carrier gateway).', context),
            ],
          ),
        ),
        _buildDocCard(
          context: context,
          title: 'Aimtoget Security & Payouts',
          subtitle: 'Securing airtime liquidation flows',
          icon: LucideIcons.shieldCheck,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAlertBox(
                text: 'CAUTION: Airtime transfers are subject to network failures and delays. Transactions must be set as PENDING first, and only marked SUCCESS once the webhook settles.',
                context: context,
                isWarning: false,
              ),
              const SizedBox(height: 16),
              const Text('SECURE WEBHOOKS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              const Text(
                'Ensure your webhook URL uses SSL (HTTPS). \n'
                'Authenticate incoming webhook payloads with a Secret Signature header. Validate that the conversion percentage and target ledger IDs match before approving credit.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 4: SECURITY RULES ---
  Widget _buildSecurityTab(BuildContext context, TextTheme textTheme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDocCard(
          context: context,
          title: 'General API Security Rules',
          subtitle: 'Standards for maintaining security and compliance',
          icon: LucideIcons.shield,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'As a fintech app dealing with real money, airtime value, and sensitive customer profiles, security must be enforced at every layer of the architecture.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              _buildSecurityRuleItem(
                number: '1',
                title: 'Never Hardcode Keys in Codebase',
                desc: 'All sensitive data (VTPass ApiKey, Paystack Secret, Aimtoget tokens, database passwords) must be stored in secure environment variables (.env files) on your cloud backend (e.g. Supabase Secrets management or AWS Parameter Store).',
                context: context,
              ),
              _buildSecurityRuleItem(
                number: '2',
                title: 'Proxy Requests via Secure Backend',
                desc: 'The Flutter application should NEVER make direct calls to third-party endpoints. Instead, send request payloads to your API proxy server. The server appends authorization tokens, verifies payload safety, and forwards to the provider.',
                context: context,
              ),
              _buildSecurityRuleItem(
                number: '3',
                title: 'Enforce HTTPS & SSL Pinning',
                desc: 'Configure TLS/SSL verification. Protect requests against Man-In-The-Middle (MITM) attacks by verifying SSL certificates and employing SSL pinning for API hosts.',
                context: context,
              ),
              _buildSecurityRuleItem(
                number: '4',
                title: 'Sign and Authenticate Webhooks',
                desc: 'Third-party webhooks (payout notifications, virtual account deposits, utility purchase confirmations) MUST be signed with secret cryptographic keys. If signature checks fail, discard the call immediately.',
                context: context,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityRuleItem({
    required String number,
    required String title,
    required String desc,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.primaryForest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
