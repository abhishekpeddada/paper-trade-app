import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'watchlist_screen.dart';
import 'portfolio_screen.dart';
import 'ai_activity_screen.dart';
import '../../core/theme/app_theme.dart';

import 'orders_screen.dart';
import 'account_screen.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auto_trading_provider.dart';
import '../../logic/providers/ai_provider.dart';
import '../../logic/providers/portfolio_provider.dart';
import '../../logic/providers/watchlist_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}



class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ai = context.read<AIProvider>();
      final portfolio = context.read<PortfolioProvider>();
      final watchlist = context.read<WatchlistProvider>();
      context.read<AutoTradingProvider>().runDailyScan(ai, portfolio, watchlist);
    });
  }

  final List<Widget> _screens = [
    const WatchlistScreen(),
    const PortfolioScreen(),
    const AiActivityScreen(),
    const OrdersScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded),
              label: 'Watchlist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline_rounded),
              label: 'Portfolio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_graph_rounded),
              label: 'AI Desk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Account',
            ),
          ],
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
