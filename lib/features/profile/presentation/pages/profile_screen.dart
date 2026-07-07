import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mspay/core/constants/app_colors.dart';
import 'package:mspay/features/auth/presentation/state/auth_provider.dart';
import 'package:mspay/core/theme/theme_provider.dart';
import 'package:mspay/features/chatbot/presentation/pages/chatbot_screen.dart';
import 'package:mspay/features/profile/presentation/pages/account_settings_screen.dart';
import 'package:mspay/features/profile/presentation/pages/admin_console_screen.dart';
import 'package:mspay/features/auth/presentation/pages/kyc_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final bytes = await image.readAsBytes();
      final extension = image.name.split('.').last.toLowerCase();
      final validExtension = ['jpg', 'jpeg', 'png', 'webp'].contains(extension) ? extension : 'png';

      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.uploadAvatar(bytes, validExtension);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final initials = authProvider.userFullName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join()
        .toUpperCase();
    final shortInitials = initials.substring(0, initials.length > 2 ? 2 : initials.length);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section (Profile Card / Avatar)
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryForest,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 32, top: 16),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accentLime, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: Colors.white24,
                          backgroundImage: authProvider.avatarUrl != null
                              ? NetworkImage(authProvider.avatarUrl!)
                              : null,
                          child: authProvider.avatarUrl == null
                              ? Text(
                                  shortInitials.isNotEmpty ? shortInitials : 'DN',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentLime,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // Loading Overlay for image upload
                      if (_isUploadingImage)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accentLime,
                              ),
                            ),
                          ),
                        ),
                      // Camera edit button
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: _isUploadingImage ? null : _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.accentLime,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.camera,
                              size: 18,
                              color: AppColors.primaryForest,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authProvider.userFullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authProvider.userEmail,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLightGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Additional List Tiles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Theme.of(context).cardColor,
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ListTile(
                      leading: Icon(LucideIcons.user, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Account Settings'),
                      subtitle: const Text('Edit name and personal details'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(LucideIcons.shieldCheck, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Security & Verification'),
                      subtitle: const Text('BVN, ID Cards & Device Limits'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const KycVerificationScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(LucideIcons.creditCard, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Linked Cards & Banks'),
                      subtitle: const Text('Manage your funding sources'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(LucideIcons.bell, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Push Notifications'),
                      trailing: Switch(
                        value: true,
                        onChanged: (v) {},
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(LucideIcons.moon, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Dark Mode'),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (v) {
                          themeProvider.toggleTheme(v);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(LucideIcons.helpCircle, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Contact Support'),
                      subtitle: const Text('Help center and Chatbot'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                        );
                      },
                    ),
                    if (authProvider.isAdmin) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(LucideIcons.userCheck, color: Theme.of(context).colorScheme.primary),
                        title: const Text('Admin Console'),
                        subtitle: const Text('Manage operations, accounting & marketing'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminConsoleScreen()),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    authProvider.signOut();
                  },
                  icon: const Icon(LucideIcons.logOut, color: Colors.red),
                  label: const Text('Log Out', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
