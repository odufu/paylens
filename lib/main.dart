import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mspay/core/theme/app_theme.dart';
import 'package:mspay/core/services/supabase_service.dart';
import 'package:mspay/core/di/injection_container.dart';
import 'package:mspay/features/auth/presentation/state/auth_provider.dart';
import 'package:mspay/features/wallet/presentation/state/wallet_provider.dart';
import 'package:mspay/features/chatbot/presentation/state/chat_provider.dart';
import 'package:mspay/core/theme/theme_provider.dart';
import 'package:mspay/features/auth/presentation/pages/welcome_screen.dart';
import 'package:mspay/features/dashboard/presentation/pages/main_navigation_holder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService.initialize();
    await initGlobalDI();
  } catch (e) {
    debugPrint('Supabase failed to initialize: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => sl<AuthProvider>()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const PayLensesApp(),
    ),
  );
}

class PayLensesApp extends StatelessWidget {
  const PayLensesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Pay Lenses',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: authProvider.isAuthenticated 
          ? const MainNavigationHolder() 
          : const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
