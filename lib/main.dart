import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'logic/providers/portfolio_provider.dart';
import 'logic/providers/watchlist_provider.dart';
import 'logic/providers/ai_provider.dart';
import 'logic/providers/strategy_provider.dart';
import 'presentation/screens/strategy_analyzer_screen.dart';
import 'logic/providers/auto_trading_provider.dart';


import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/services/auth_service.dart';
import 'presentation/screens/login_screen.dart';
import 'config/firebase_options.dart';

// TODO: Replace with your actual OpenRouter API key
const String openRouterApiKey = 'YOUR_OPENROUTER_API_KEY';
const String defaultModel = 'z-ai/glm-4.5-air:free';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (defaultTargetPlatform != TargetPlatform.linux && defaultTargetPlatform != TargetPlatform.windows) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  runApp(const PaperTradeApp());
}

class PaperTradeApp extends StatelessWidget {
  const PaperTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(
          create: (_) => AIProvider(
            apiKey: openRouterApiKey,
            model: defaultModel,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => StrategyProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AutoTradingProvider(),
        ),
        StreamProvider<User?>(
          create: (_) => AuthService().user,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Paper Trade',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    
    if (user == null) {
      return const LoginScreen();
    }

    // Reload data when user changes/logs in
    // We can do this here or in the providers themselves listening to auth changes
    // But triggering it here ensures it happens on transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortfolioProvider>().reloadData();
      context.read<WatchlistProvider>().reloadData();
      context.read<AutoTradingProvider>().reloadData();
    });

    return const MainScreen();
  }
}
