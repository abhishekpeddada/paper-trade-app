import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ohlc_data.dart';
import '../../data/models/trading_strategy.dart';
import '../../data/models/backtest_result.dart';
import '../../data/services/yahoo_finance_service.dart';
import '../../logic/services/backtest_engine.dart';

class BacktestingScreen extends StatefulWidget {
  final String? initialSymbol;
  final String? initialStrategy;

  const BacktestingScreen({
    super.key,
    this.initialSymbol,
    this.initialStrategy,
  });

  @override
  State<BacktestingScreen> createState() => _BacktestingScreenState();
}

class _BacktestingScreenState extends State<BacktestingScreen> {
  final TextEditingController _symbolController = TextEditingController();
  final YahooFinanceService _yahooService = YahooFinanceService();
  
  String _selectedStrategy = 'psar';
  String _selectedPeriod = '1y';
  bool _isLoading = false;
  String? _error;
  BacktestResult? _result;

  final Map<String, String> _periods = {
    '6m': '6 Months',
    '1y': '1 Year',
    '2y': '2 Years',
  };

  @override
  void initState() {
    super.initState();
    _symbolController.text = widget.initialSymbol ?? 'AAPL';
    _selectedStrategy = widget.initialStrategy ?? 'psar';
  }

  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }

  Future<void> _runBacktest() async {
    final symbol = _symbolController.text.trim().toUpperCase();
    if (symbol.isEmpty) {
      setState(() => _error = 'Please enter a symbol');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      int days;
      switch (_selectedPeriod) {
        case '6m':
          days = 180;
          break;
        case '2y':
          days = 730;
          break;
        default:
          days = 365;
      }

      final ohlcJson = await _yahooService.getOHLCData(symbol, timeframe: '1d');
      
      if (ohlcJson.isEmpty) {
        throw Exception('No data available for $symbol');
      }

      final allCandles = ohlcJson.map((json) => OHLCData.fromJson(json)).toList();
      
      final candles = allCandles.length > days 
          ? allCandles.sublist(allCandles.length - days)
          : allCandles;

      if (candles.length < 50) {
        throw Exception('Insufficient data for backtesting (need at least 50 candles)');
      }

      final result = BacktestEngine.runBacktest(
        candles: candles,
        strategyId: _selectedStrategy,
        symbol: symbol,
      );

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strategy Backtester'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputSection(),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _runBacktest,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isLoading ? 'Running...' : 'Run Backtest'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResultsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
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
            'Backtest Configuration',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _symbolController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Symbol',
              hintText: 'e.g., AAPL, TCS.NS',
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          
          const SizedBox(height: 12),
          
          DropdownButtonFormField<String>(
            value: _selectedStrategy,
            decoration: const InputDecoration(
              labelText: 'Strategy',
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            dropdownColor: AppTheme.surfaceColor,
            style: const TextStyle(color: AppTheme.textPrimary),
            items: TradingStrategy.allStrategies.map((s) {
              return DropdownMenuItem(
                value: s.id,
                child: Text(s.name),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedStrategy = value);
            },
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              const Text('Period: ', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(width: 8),
              ..._periods.entries.map((entry) {
                final isSelected = _selectedPeriod == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedPeriod = entry.key);
                    },
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.backgroundColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    final r = _result!;
    final isProfit = r.totalReturn >= 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isProfit 
                  ? [Colors.green.withValues(alpha: 0.3), AppTheme.surfaceColor]
                  : [Colors.red.withValues(alpha: 0.3), AppTheme.surfaceColor],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '${r.symbol} - ${_getStrategyName(r.strategy)}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDate(r.startDate)} → ${_formatDate(r.endDate)}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${r.totalReturnPct >= 0 ? '+' : ''}${r.totalReturnPct.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isProfit ? Colors.green : Colors.red,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                'Total Return',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2,
          children: [
            _buildMetricCard('Win Rate', '${r.winRate.toStringAsFixed(1)}%', 
                r.winRate >= 50 ? Colors.green : Colors.orange),
            _buildMetricCard('Total Trades', '${r.totalTrades}', AppTheme.accentColor),
            _buildMetricCard('Winning', '${r.winningTrades}', Colors.green),
            _buildMetricCard('Losing', '${r.losingTrades}', Colors.red),
            _buildMetricCard('Avg Win', '+${r.avgWin.toStringAsFixed(2)}%', Colors.green),
            _buildMetricCard('Avg Loss', '${r.avgLoss.toStringAsFixed(2)}%', Colors.red),
            _buildMetricCard('Max Drawdown', '-${r.maxDrawdownPct.toStringAsFixed(2)}%', Colors.orange),
            _buildMetricCard('Profit Factor', r.profitFactor.toStringAsFixed(2), 
                r.profitFactor >= 1.5 ? Colors.green : AppTheme.textSecondary),
          ],
        ),
        
        const SizedBox(height: 16),
        
        if (r.equityCurve.length > 1) _buildEquityCurve(r),
        
        const SizedBox(height: 16),
        
        _buildTradeHistory(r),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEquityCurve(BacktestResult r) {
    final minY = r.equityCurve.reduce((a, b) => a < b ? a : b);
    final maxY = r.equityCurve.reduce((a, b) => a > b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Equity Curve',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: minY * 0.95,
                maxY: maxY * 1.05,
                lineBarsData: [
                  LineChartBarData(
                    spots: r.equityCurve.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true,
                    color: r.totalReturn >= 0 ? Colors.green : Colors.red,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (r.totalReturn >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeHistory(BacktestResult r) {
    if (r.trades.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No trades generated',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

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
              const Text(
                'Trade History',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${r.trades.length} trades',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...r.trades.take(10).map((trade) => _buildTradeRow(trade)),
          if (r.trades.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${r.trades.length - 10} more trades...',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTradeRow(BacktestTrade trade) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            trade.isWin ? Icons.arrow_upward : Icons.arrow_downward,
            color: trade.isWin ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_formatDate(trade.entryDate)} → ${_formatDate(trade.exitDate)}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
          Text(
            '${trade.profitLossPct >= 0 ? '+' : ''}${trade.profitLossPct.toStringAsFixed(2)}%',
            style: TextStyle(
              color: trade.isWin ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }

  String _getStrategyName(String id) {
    return TradingStrategy.allStrategies
        .firstWhere((s) => s.id == id, orElse: () => TradingStrategy.allStrategies.first)
        .name;
  }
}
