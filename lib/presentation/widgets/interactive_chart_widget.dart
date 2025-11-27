import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart';
import '../../data/models/ohlc_data.dart';
import '../../data/models/trading_strategy.dart';
import '../../core/theme/app_theme.dart';

class InteractiveChartWidget extends StatelessWidget {
  final List<OHLCData> ohlcData;
  final StrategyResult? strategyResult;

  const InteractiveChartWidget({
    super.key,
    required this.ohlcData,
    this.strategyResult,
  });

  @override
  Widget build(BuildContext context) {
    if (ohlcData.isEmpty) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No chart data available',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    // Convert OHLCData to CandleData format
    final candleData = ohlcData.map((data) {
      return CandleData(
        timestamp: data.timestamp.millisecondsSinceEpoch,
        open: data.open,
        high: data.high,
        low: data.low,
        close: data.close,
        volume: data.volume,
      );
    }).toList();

    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveChart(
          candles: candleData,
          style: ChartStyle(
            // Candle colors
            priceGainColor: const Color(0xFF26A69A), // Green
            priceLossColor: const Color(0xFFEF5350), // Red
            volumeColor: const Color(0xFF424242).withValues(alpha: 0.3),
            
            // Very dark background like reference image
            priceGridLineColor: const Color(0xFF2A2E39), // Subtle grid lines
            
            // Labels
            priceLabelStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11),
            timeLabelStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11),
            
            // Crosshair styling
            selectionHighlightColor: Colors.white.withValues(alpha: 0.2),
            overlayBackgroundColor: const Color(0xFF1A1D24).withValues(alpha: 0.95), // Dark overlay
            overlayTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          timeLabel: (timestamp, visibleDataCount) {
            final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
            if (visibleDataCount > 20) {
              return '${date.month}/${date.day}';
            } else {
              return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
            }
          },
          priceLabel: (price) => '\$${price.toStringAsFixed(2)}',
          overlayInfo: (candle) {
            final Map<String, String> info = {
              'Date': DateTime.fromMillisecondsSinceEpoch(candle.timestamp).toString().split('.')[0],
              'Open': '\$${candle.open?.toStringAsFixed(2)}',
              'High': '\$${candle.high?.toStringAsFixed(2)}',
              'Low': '\$${candle.low?.toStringAsFixed(2)}',
              'Close': '\$${candle.close?.toStringAsFixed(2)}',
              'Volume': candle.volume?.toStringAsFixed(0) ?? 'N/A',
           };

            // Add strategy indicator values
            if (strategyResult != null) {
              final index = ohlcData.indexWhere((d) => 
                d.timestamp.millisecondsSinceEpoch == candle.timestamp);
              
              if (index >= 0 && index < strategyResult!.indicatorLine.length) {
                final indicatorValue = strategyResult!.indicatorLine[index];
                if (!indicatorValue.isNaN) {
                  info[strategyResult!.indicatorName] = indicatorValue.toStringAsFixed(2);
                }

                if (strategyResult!.secondaryLine != null && 
                    index < strategyResult!.secondaryLine!.length) {
                  final secondaryValue = strategyResult!.secondaryLine![index];
                  if (!secondaryValue.isNaN) {
                    info[strategyResult!.secondaryName ?? 'Secondary'] = 
                      secondaryValue.toStringAsFixed(2);
                  }
                }
              }

              // Show signals at this candle
              final signals = strategyResult!.signals.where((s) => s.index == index).toList();
              for (var signal in signals) {
                switch (signal.type) {
                  case SignalType.buy:
                    info['Signal'] = '📈 BUY';
                    if (signal.stopLoss != null) {
                      info['Stop Loss'] = '\$${signal.stopLoss!.toStringAsFixed(2)}';
                    }
                    if (signal.target != null) {
                      info['Target'] = '\$${signal.target!.toStringAsFixed(2)}';
                    }
                    break;
                  case SignalType.sell:
                    info['Signal'] = '📉 SELL';
                    break;
                  default:
                    break;
                }
              }
            }

            return info;
          },
        ),
      ),
    );
  }
}
