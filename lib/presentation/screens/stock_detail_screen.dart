import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/stock_model.dart';
import '../../data/repositories/stock_repository.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/trade_bottom_sheet.dart';
import '../../data/models/trade_models.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/ai_provider.dart';
import '../../logic/providers/portfolio_provider.dart';

class StockDetailScreen extends StatefulWidget {
  final Stock initialStock;

  const StockDetailScreen({super.key, required this.initialStock});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  late Stock stock;
  String selectedTimeframe = '1d';
  bool isLoading = false;
  final _repository = StockRepository();

  @override
  void initState() {
    super.initState();
    stock = widget.initialStock;
  }

  Future<void> _loadStockData(String timeframe) async {
    setState(() {
      isLoading = true;
      selectedTimeframe = timeframe;
    });

    try {
      final newStock = await _repository.getStock(stock.symbol, timeframe: timeframe);
      setState(() {
        stock = newStock;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading timeframe data: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = stock.change >= 0;
    final color = isPositive ? AppTheme.primaryColor : AppTheme.secondaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(stock.symbol),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${stock.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          color: color,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stock.change.toStringAsFixed(2)} (${stock.changePercent.toStringAsFixed(2)}%)',
                          style: TextStyle(
                            fontSize: 16,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                     final aiProvider = Provider.of<AIProvider>(context, listen: false);
                     final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
                     aiProvider.analyzeAndTrade(stock.symbol, stock.price, portfolio: portfolioProvider);
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('AI Analysis started...')),
                     );
                  },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('AI Trade'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildTimeframeSelector(),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            width: double.infinity,
            child: stock.chartSpots.isNotEmpty
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: stock.chartSpots,
                          isCurved: true,
                          color: color,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(child: Text('No chart data available', style: TextStyle(color: Colors.white54))),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'SELL',
                    color: AppTheme.secondaryColor,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppTheme.surfaceColor,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => TradeBottomSheet(
                          stock: stock,
                          type: OrderType.sell,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'BUY',
                    color: AppTheme.primaryColor,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppTheme.surfaceColor,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => TradeBottomSheet(
                          stock: stock,
                          type: OrderType.buy,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    final timeframes = ['1d', '1w', '1m', '3m', '1y', 'all'];
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: timeframes.map((tf) {
          final isSelected = selectedTimeframe == tf;
          return GestureDetector(
            onTap: isLoading ? null : () => _loadStockData(tf),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                tf.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
