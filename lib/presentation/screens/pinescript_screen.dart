import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/providers/pine_provider.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../widgets/interactive_chart_widget.dart';
import '../widgets/candlestick_chart_widget.dart';

class PineScriptScreen extends StatefulWidget {
  const PineScriptScreen({super.key});

  @override
  State<PineScriptScreen> createState() => _PineScriptScreenState();
}

class _PineScriptScreenState extends State<PineScriptScreen> {
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _pineScriptController = TextEditingController();
  bool _showConvertedCode = false;

  @override
  void dispose() {
    _symbolController.dispose();
    _pineScriptController.dispose();
    super.dispose();
  }

  void _loadExample() {
    _symbolController.text = 'AAPL';
    _pineScriptController.text = '''
//@version=5
indicator("SMA 20", overlay=true)
length = 20
sma20 = ta.sma(close, length)
plot(sma20, color=color.blue, linewidth=2)
''';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PineScript Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _loadExample,
            tooltip: 'Load Example',
          ),
        ],
      ),
      body: Consumer<PineScriptProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Input Section
                _buildInputSection(provider),
                const SizedBox(height: 20),

                // Timeframe Selector
                _buildTimeframeSelector(provider),
                const SizedBox(height: 20),

                // Convert Button
                _buildConvertButton(provider),
                const SizedBox(height: 20),

                // Error Message
                if (provider.errorMessage != null)
                  _buildErrorMessage(provider.errorMessage!),

                // Loading Indicator
                if (provider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Chart Section
                if (provider.hasData && !provider.isLoading) ...[
                  const SizedBox(height: 20),
                  _buildChartSection(provider),
                ],

                // Converted Code Section
                if (provider.hasConversion && !provider.isLoading) ...[
                  const SizedBox(height: 20),
                  _buildConvertedCodeSection(provider),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputSection(PineScriptProvider provider) {
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
          const SizedBox(height: 16),
          const Text(
            'PineScript Code',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pineScriptController,
            maxLines: 10,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your PineScript indicator code...',
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: provider.setPineScriptCode,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector(PineScriptProvider provider) {
    final timeframes = [
      {'label': '1D', 'value': '1d'},
      {'label': '1W', 'value': '1w'},
      {'label': '1M', 'value': '1m'},
      {'label': '3M', 'value': '3m'},
      {'label': '6M', 'value': '6m'},
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
                  if (provider.hasData) {
                    provider.refreshChartData();
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

  Widget _buildConvertButton(PineScriptProvider provider) {
    if (provider.isLoading) {
      return CustomButton(
        text: 'Converting...',
        color: AppTheme.accentColor.withValues(alpha: 0.5),
        onPressed: () {}, // Disabled state
      );
    }
    
    return CustomButton(
      text: 'Convert & Plot',
      color: AppTheme.accentColor,
      onPressed: () {
        provider.convertAndPlot();
      },
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

  Widget _buildChartSection(PineScriptProvider provider) {
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
              Text(
                '${provider.symbol} Chart',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (provider.conversion?.indicatorName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    provider.conversion!.indicatorName!,
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          CandlestickChartWidget(
            ohlcData: provider.chartData,
            indicatorValues: provider.indicatorValues.isNotEmpty 
                ? provider.indicatorValues 
                : null,
            indicatorName: provider.conversion?.indicatorName,
          ),
          const SizedBox(height: 12),
          Text(
            'Hover over chart to see values',
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

  Widget _buildConvertedCodeSection(PineScriptProvider provider) {
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
                'Converted Dart Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showConvertedCode ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.accentColor,
                ),
                onPressed: () {
                  setState(() {
                    _showConvertedCode = !_showConvertedCode;
                  });
                },
              ),
            ],
          ),
          if (_showConvertedCode) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  provider.conversion!.convertedDartCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
