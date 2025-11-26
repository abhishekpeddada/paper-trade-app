import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'logic/providers/portfolio_provider.dart';
import 'logic/providers/watchlist_provider.dart';
import 'logic/providers/ai_provider.dart';
import 'logic/providers/pine_provider.dart';
import 'logic/providers/auto_trading_provider.dart';
import 'data/repositories/pine_repository.dart';
import 'data/services/openrouter_service.dart';
import 'data/services/yahoo_finance_service.dart';

// TODO: Replace with your actual OpenRouter API key
const String openRouterApiKey = 'YOUR_OPENROUTER_API_KEY';
const String defaultModel = 'z-ai/glm-4.5-air:free';

void main() {
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
          create: (_) {
            final openRouterService = OpenRouterService(
              openRouterApiKey,  // Now using the same API key
              model: defaultModel,
            );
            final yahooFinanceService = YahooFinanceService();
            final repository = PineScriptRepository(openRouterService, yahooFinanceService);
            return PineScriptProvider(repository);
          },
        ),
        ChangeNotifierProvider(
          create: (_) => AutoTradingProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Paper Trade',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainScreen(),
      ),
    );
  }
}
