import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/presentation/widgets/branded_spinner.dart';
import 'package:mspay/features/auth/presentation/pages/sign_in_screen.dart';
import 'package:mspay/features/auth/presentation/pages/sign_up_screen.dart';
import 'package:mspay/core/utils/security_utils.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Run cyber security integrity audit
    final isSecured = SecurityUtils.verifyDeviceIntegrity();

    if (!isSecured) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C1013),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.security,
                  color: Colors.redAccent,
                  size: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  'Security Violation',
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pay Lenses cannot run on compromised, rooted, or jailbroken devices to protect your wallet and financial assets.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Decoration
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryForest,
                  Color(0xFF012115), // Darker shade of forest green
                ],
              ),
            ),
          ),

          // Subtle background decorative circles for a premium aesthetic
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: Colors.white.withOpacity(0.03),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -80,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: AppColors.accentLime.withOpacity(0.02),
            ),
          ),

          // Content Layout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // App Branding Logo Placeholder
                  Center(
                    child: AnimatedLogoBorder(
                      child: const FintechWalletLensLogo(
                        size: 80,
                        isAnimating: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Brand Name and Caption
                  Center(
                    child: Text(
                      'PAY LENSES',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Experience premium mobile wealth management and automated utilities. Settle bills instantly via Paystack and VTPass.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLightGrey.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // CTAs
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentLime,
                      foregroundColor: AppColors.textDark,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Log In to Account'),
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Create New Account'),
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () async {
                        final url = Uri.parse('PayLense.apk');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          await launchUrl(url);
                        }
                      },
                      icon: const Icon(
                        Icons.android,
                        color: AppColors.accentLime,
                      ),
                      label: const Text(
                        'Download Android App (APK)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
