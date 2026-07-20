import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/core/presentation/widgets/branded_spinner.dart';
import 'package:mspay/features/auth/presentation/state/auth_provider.dart';
import 'package:mspay/core/services/network_status_provider.dart';

class ResumeSessionScreen extends StatefulWidget {
  const ResumeSessionScreen({super.key});

  @override
  State<ResumeSessionScreen> createState() => _ResumeSessionScreenState();
}

class _ResumeSessionScreenState extends State<ResumeSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final isOnline = Provider.of<NetworkStatusProvider>(context, listen: false).isOnline;
    if (!isOnline) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Internet Connection'),
          content: const Text('Please check your network settings and try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      BrandedLoadingOverlay.show(context, message: 'Unlocking wallet...');
      await authProvider.signIn(
        email: authProvider.userEmail,
        password: _passwordController.text,
      );
      if (mounted) {
        BrandedLoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome back!')),
        );
      }
    } catch (e) {
      if (mounted) {
        BrandedLoadingOverlay.hide(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unlock Failed'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildInitialsAvatar(String name, double size) {
    final initials = name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primaryForest, Color(0xFF005C3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.accentLime, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentLime.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String displayName = authProvider.userFullName;
    final String displayEmail = authProvider.userEmail;
    final String? avatar = authProvider.avatarUrl;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App branding / title
                  Text(
                    'PAYLENS',
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppColors.primaryForest,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // User Avatar (DP)
                  if (avatar != null && avatar.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accentLime, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentLime.withValues(alpha: 0.15),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(55),
                        child: Image.network(
                          avatar,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => _buildInitialsAvatar(displayName, 110),
                        ),
                      ),
                    )
                  else
                    _buildInitialsAvatar(displayName, 110),

                  const SizedBox(height: 24),

                  // Welcome greeting
                  Text(
                    'Welcome back,',
                    style: textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.white60 : AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayName,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white38 : AppColors.textLightGrey,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      prefixIcon: const Icon(LucideIcons.lock, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primaryForest,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Unlock CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _handleUnlock(authProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryForest,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.unlock, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Unlock Wallet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // "Or login with another account" link
                  GestureDetector(
                    onTap: () async {
                      try {
                        BrandedLoadingOverlay.show(context, message: 'Signing out...');
                        await authProvider.loginWithAnotherAccount();
                        if (mounted) {
                          BrandedLoadingOverlay.hide(context);
                        }
                      } catch (e) {
                        if (mounted) {
                          BrandedLoadingOverlay.hide(context);
                        }
                      }
                    },
                    child: const Text(
                      'or login with another account',
                      style: TextStyle(
                        color: AppColors.primaryForest,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
