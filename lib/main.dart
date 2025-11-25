import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'logic/providers/portfolio_provider.dart';
import 'logic/providers/watchlist_provider.dart';
import 'logic/providers/ai_provider.dart';

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
        ChangeNotifierProxyProvider<PortfolioProvider, AiProvider>(
          create: (context) => AiProvider(Provider.of<PortfolioProvider>(context, listen: false)),
          update: (context, portfolio, previous) => previous ?? AiProvider(portfolio),
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
