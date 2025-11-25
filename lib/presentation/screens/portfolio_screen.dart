import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/portfolio_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_card.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          final positions = provider.positions;
          
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                color: AppTheme.surfaceColor,
                child: Column(
                  children: [
                    const Text(
                      'Available Cash',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${provider.balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: positions.isEmpty
                    ? const Center(child: Text('No positions yet', style: TextStyle(color: Colors.white54)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: positions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final position = positions[index];
                          // Note: In a real app we'd need to fetch current price to show P&L
                          // For now showing avg price and quantity
                          
                          return CustomCard(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      position.symbol,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${position.quantity.toStringAsFixed(2)} shares',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Avg: \$${position.averagePrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
