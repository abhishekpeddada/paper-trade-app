import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/portfolio_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../../core/utils/currency_helper.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<PortfolioProvider>(
          builder: (context, provider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Portfolio', style: TextStyle(fontSize: 20)),
                if (provider.lastRefresh != null)
                  Text(
                    'Updated: ${provider.lastRefresh!.hour.toString().padLeft(2, '0')}:${provider.lastRefresh!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
              ],
            );
          },
        ),
        actions: [
          Consumer<PortfolioProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: provider.isRefreshing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh),
                onPressed: provider.isRefreshing ? null : () {
                  provider.refreshPrices();
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          final positions = provider.positions;
          final totalPL = provider.getTotalProfitLoss();
          final totalValue = provider.getTotalPortfolioValue();
          final isPLPositive = totalPL >= 0;
          
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                color: AppTheme.surfaceColor,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Value (INR)',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyHelper.formatInr(totalValue),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (positions.isNotEmpty && provider.currentPrices.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (isPLPositive ? AppTheme.primaryColor : AppTheme.secondaryColor).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isPLPositive ? AppTheme.primaryColor : AppTheme.secondaryColor,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'P&L',
                                  style: TextStyle(
                                    color: isPLPositive ? AppTheme.primaryColor : AppTheme.secondaryColor,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '${isPLPositive ? '+' : ''}${CurrencyHelper.formatInr(totalPL)}',
                                  style: TextStyle(
                                    color: isPLPositive ? AppTheme.primaryColor : AppTheme.secondaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cash: ${CurrencyHelper.formatInr(provider.balance)}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                        if (positions.isNotEmpty)
                          Text(
                            'Invested: ${CurrencyHelper.formatInr(totalValue - provider.balance)}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                          ),
                      ],
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
                          final currentPrice = provider.currentPrices[position.symbol];
                          final pl = provider.getProfitLoss(position);
                          final plPercent = provider.getProfitLossPercent(position);
                          final isPLPositive = pl >= 0;
                          
                          return CustomCard(
                            onTap: () => _showPositionDetails(context, position, provider),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
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
                                      if (currentPrice != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            CurrencyHelper.formatPrice(currentPrice, position.symbol),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Avg: ${CurrencyHelper.formatPrice(position.averagePrice, position.symbol)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (currentPrice != null)
                                      Text(
                                        '${isPLPositive ? '+' : ''}${CurrencyHelper.formatInr(pl)} (${isPLPositive ? '+' : ''}${plPercent.toStringAsFixed(2)}%)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isPLPositive ? AppTheme.primaryColor : AppTheme.secondaryColor,
                                        ),
                                      )
                                    else
                                      const Text(
                                        'Loading...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
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

  void _showPositionDetails(BuildContext context, position, PortfolioProvider provider) {
    final currentPrice = provider.currentPrices[position.symbol];
    final pl = provider.getProfitLoss(position);
    final plPercent = provider.getProfitLossPercent(position);
    final isPLPositive = pl >= 0;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              position.symbol,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Quantity', '${position.quantity.toStringAsFixed(2)} shares'),
            const SizedBox(height: 12),
            _buildDetailRow('Average Price', CurrencyHelper.formatPrice(position.averagePrice, position.symbol)),
            const SizedBox(height: 12),
            if (currentPrice != null) ...[
              _buildDetailRow('Current Price', CurrencyHelper.formatPrice(currentPrice, position.symbol)),
              const SizedBox(height: 12),
            ],
            // Show Cost Basis in INR as it's the actual invested amount
            _buildDetailRow('Cost Basis (INR)', CurrencyHelper.formatInr(CurrencyHelper.convertToInr(position.averagePrice * position.quantity, position.symbol))),
            if (currentPrice != null) ...[
              const SizedBox(height: 12),
              // Show Current Value in INR
              _buildDetailRow('Current Value (INR)', CurrencyHelper.formatInr(CurrencyHelper.convertToInr(currentPrice * position.quantity, position.symbol))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'P&L (INR)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isPLPositive ? '+' : ''}${CurrencyHelper.formatInr(pl)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isPLPositive ? AppTheme.primaryColor : AppTheme.secondaryColor,
                        ),
                      ),
                      Text(
                        '${isPLPositive ? '+' : ''}${plPercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isPLPositive ? AppTheme.primaryColor : AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
