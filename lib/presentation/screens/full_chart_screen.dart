import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ohlc_data.dart';
import '../../data/services/yahoo_finance_service.dart';
import '../../data/models/trading_strategy.dart';
import '../widgets/candlestick_chart_widget.dart';

class FullChartScreen extends StatefulWidget {
  final String symbol;
  final String companyName;
  final StrategyResult? strategyResult;

  const FullChartScreen({
    super.key,
    required this.symbol,
    required this.companyName,
    this.strategyResult,
  });

  @override
  State<FullChartScreen> createState() => _FullChartScreenState();
}

class _FullChartScreenState extends State<FullChartScreen> {
  final YahooFinanceService _yahooService = YahooFinanceService();
  
  String _selectedInterval = '1d'; // Default to daily candles
  List<OHLCData> _chartData = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Available candle intervals
  final List<Map<String, String>> _intervals = [
    {'label': '1m', 'value': '1m'},
    {'label': '5m', 'value': '5m'},
    {'label': '15m', 'value': '15m'},
    {'label': '30m', 'value': '30m'},
    {'label': '1h', 'value': '1h'},
    {'label': '1D', 'value': '1d'},
    {'label': '1W', 'value': '1wk'},
    {'label': '1M', 'value': '1mo'},
  ];

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _yahooService.getOHLCDataWithInterval(
        symbol: widget.symbol,
        interval: _selectedInterval,
      );
      
      setState(() {
        _chartData = data.map((json) => OHLCData.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading chart data: $e';
        _isLoading = false;
      });
    }
  }

  void _changeInterval(String interval) {
    if (_selectedInterval != interval) {
      setState(() {
        _selectedInterval = interval;
      });
      _loadChartData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.symbol,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.companyName,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChartData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Chart display (full width now)
          _buildChartContent(),
          
          // Compact timeframe dropdown in top-right corner
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButton<String>(
                value: _selectedInterval,
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                iconEnabledColor: AppTheme.accentColor,
                underline: const SizedBox(),
                dropdownColor: AppTheme.surfaceColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                items: _intervals.map((interval) {
                  return DropdownMenuItem<String>(
                    value: interval['value'],
                    child: Text(interval['label']!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _changeInterval(newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.secondaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadChartData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_chartData.isEmpty) {
      return Center(
        child: Text(
          'No chart data available',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart info
          Text(
            'Candle Interval: ${_getIntervalLabel()}',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            '${_chartData.length} candles',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          
          // Chart with zoom, pan, and crosshair
          Expanded(
            child: CandlestickChartWidget(
              ohlcData: _chartData,
              strategyResult: widget.strategyResult,
            ),
          ),
          
          // Interaction hints
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Pinch to zoom • Drag to pan • Tap for crosshair',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getIntervalLabel() {
    final interval = _intervals.firstWhere(
      (i) => i['value'] == _selectedInterval,
      orElse: () => {'label': _selectedInterval, 'value': _selectedInterval},
    );
    return interval['label']!;
  }
}
