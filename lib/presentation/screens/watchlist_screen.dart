import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../logic/providers/watchlist_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_card.dart';
import 'stock_detail_screen.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<WatchlistProvider>(
          builder: (context, provider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Watchlist', style: TextStyle(fontSize: 20)),
                if (provider.lastRefresh != null)
                  Text(
                    'Updated: ${DateFormat('HH:mm').format(provider.lastRefresh!)}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<WatchlistProvider>().fetchWatchlist();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Show search bottom sheet
              showModalBottomSheet(
                context: context,
                backgroundColor: AppTheme.surfaceColor,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => const SearchBottomSheet(),
              );
            },
          ),
        ],
      ),
      body: Consumer<WatchlistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.watchlist.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final stock = provider.watchlist[index];
              final isPositive = stock.change >= 0;

              return Dismissible(
                key: Key(stock.symbol),
                background: Container(
                  color: AppTheme.secondaryColor,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  provider.removeFromWatchlist(stock.symbol);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${stock.symbol} removed from watchlist')),
                  );
                },
                child: CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock.symbol,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'NSE', // Placeholder exchange
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                           Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${stock.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive ? AppTheme.primaryColor : AppTheme.secondaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${isPositive ? '+' : ''}${stock.change.toStringAsFixed(2)} (${stock.changePercent.toStringAsFixed(2)}%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isPositive ? AppTheme.primaryColor : AppTheme.secondaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.auto_awesome, size: 20, color: AppTheme.accentColor),
                            onPressed: () {
                               // Trigger AI Analysis
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Requesting AI Analysis... Check AI Desk.')),
                               );
                               // We need to access AIProvider here, but it might be better to do this in detail screen or have a direct call
                               // For now, let's just navigate to detail screen where we can put the button more prominently
                               // Or actually, let's just call it if we can
                               // Provider.of<AIProvider>(context, listen: false).analyzeAndTrade(stock.symbol, stock.price);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StockDetailScreen(initialStock: stock),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SearchBottomSheet extends StatelessWidget {
  const SearchBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            hintText: 'Search stocks...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
            onChanged: (value) {
              context.read<WatchlistProvider>().searchStocks(value);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Consumer<WatchlistProvider>(
              builder: (context, provider, child) {
                return ListView.builder(
                  itemCount: provider.searchResults.length,
                  itemBuilder: (context, index) {
                    final symbol = provider.searchResults[index];
                    return ListTile(
                      title: Text(symbol, style: const TextStyle(color: Colors.white)),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                        onPressed: () {
                          provider.addToWatchlist(symbol);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
