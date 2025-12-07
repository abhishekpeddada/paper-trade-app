import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/providers/strategy_provider.dart';
import '../../data/models/trading_strategy.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/candlestick_chart_widget.dart';
import 'full_chart_screen.dart';
import 'backtesting_screen.dart';

class StrategyAnalyzerScreen extends StatefulWidget {
  const StrategyAnalyzerScreen({super.key});

  @override
  State<StrategyAnalyzerScreen> createState() => _StrategyAnalyzerScreenState();
}

class _StrategyAnalyzerScreenState extends State<StrategyAnalyzerScreen> {
  final TextEditingController _symbolController = TextEditingController();

  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strategy Analyzer'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BacktestingScreen(
                    initialSymbol: _symbolController.text.isNotEmpty 
                        ? _symbolController.text 
                        : null,
                    initialStrategy: Provider.of<StrategyProvider>(context, listen: false).selectedStrategy?.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Backtest Strategy',
          ),
        ],
      ),
      body: Consumer<StrategyProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSymbolInput(provider),
                const SizedBox(height: 20),
                _buildTimeframeSelector(provider),
                const SizedBox(height: 20),
                _buildStrategyButtons(provider),
                const SizedBox(height: 20),

                if (provider.errorMessage != null)
                  _buildErrorMessage(provider.errorMessage!),

                if (provider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                if (provider.hasData && !provider.isLoading) ...[
                  const SizedBox(height: 20),
                  _buildChartSection(provider),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSymbolInput(StrategyProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stock Symbol',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _symbolController,
            hintText: 'e.g., AAPL, TSLA, GOOGL',
            onChanged: provider.setSymbol,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector(StrategyProvider provider) {
    final timeframes = [
      {'label': '1D', 'value': '1d'},
      {'label': '1W', 'value': '1w'},
      {'label': '1M', 'value': '1mo'},
      {'label': '3M', 'value': '3mo'},
      {'label': '1Y', 'value': '1y'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeframe',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: timeframes.map((tf) {
              final isSelected = provider.timeframe == tf['value'];
              return GestureDetector(
                onTap: () {
                  provider.setTimeframe(tf['value']!);
                  if (provider.hasData && provider.selectedStrategy != null) {
                    provider.applyStrategy(strategy: provider.selectedStrategy!);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accentColor : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.accentColor 
                          : AppTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    tf['label']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyButtons(StrategyProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sample Scripts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TradingStrategy.allStrategies.map((strategy) {
              final isSelected = provider.selectedStrategy?.id == strategy.id;
              
              return GestureDetector(
                onTap: () {
                  provider.applyStrategy(strategy: strategy);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.accentColor
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.accentColor 
                          : AppTheme.textSecondary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    strategy.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // MA Period Selector - show when SMA is selected
          if (provider.selectedStrategy?.id == 'sma') ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'MA Period:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [20, 50, 100, 200].map((period) {
                      final isSelected = provider.maPeriod == period;
                      return GestureDetector(
                        onTap: () => provider.setMAPeriod(period),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppTheme.primaryColor
                                : AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                  ? AppTheme.primaryColor 
                                  : AppTheme.textSecondary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '$period',
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
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondaryColor),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.secondaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppTheme.secondaryColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(StrategyProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${provider.symbol} - ${provider.selectedStrategy?.name ?? "Chart"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white70),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullChartScreen(
                        symbol: provider.symbol,
                        companyName: provider.symbol,
                        strategyResult: provider.strategyResult,
                      ),
                    ),
                  );
                },
                tooltip: 'Fullscreen',
              ),
            ],
          ),
          const SizedBox(height: 16),
          CandlestickChartWidget(
            ohlcData: provider.chartData,
            strategyResult: provider.strategyResult,
          ),
          const SizedBox(height: 12),
          Text(
            'Pinch & pan to navigate • Tap candle for details',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

