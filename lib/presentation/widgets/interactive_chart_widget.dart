import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart';
import '../../data/models/ohlc_data.dart';
import '../../core/theme/app_theme.dart';

class InteractiveChartWidget extends StatelessWidget {
  final List<OHLCData> ohlcData;
  final List<double>? indicatorValues;
  final String? indicatorName;

  const InteractiveChartWidget({
    super.key,
    required this.ohlcData,
    this.indicatorValues,
    this.indicatorName,
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

    // Convert OHLCData to CandleData format required by interactive_chart
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
      height: 400,
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
            priceGainColor: AppTheme.primaryColor,
            priceLossColor: AppTheme.secondaryColor,
            volumeColor: AppTheme.textSecondary.withValues(alpha: 0.3),
            // Dark theme
            priceGridLineColor: AppTheme.textSecondary.withValues(alpha: 0.1),
            priceLabelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            timeLabelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            selectionHighlightColor: Colors.white.withValues(alpha: 0.1),
            overlayBackgroundColor: AppTheme.backgroundColor.withValues(alpha: 0.9),
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
            return {
              'Date': DateTime.fromMillisecondsSinceEpoch(candle.timestamp).toString().split('.')[0],
              'Open': '\$${candle.open?.toStringAsFixed(2)}',
              'High': '\$${candle.high?.toStringAsFixed(2)}',
              'Low': '\$${candle.low?.toStringAsFixed(2)}',
              'Close': '\$${candle.close?.toStringAsFixed(2)}',
              'Volume': candle.volume?.toStringAsFixed(0) ?? 'N/A',
              if (indicatorName != null) indicatorName!: getIndicatorValueAtIndex(candle),
            };
          },
        ),
      ),
    );
  }

  String getIndicatorValueAtIndex(CandleData candle) {
    if (indicatorValues == null) return 'N/A';
    
    // Find the index of this candle
    int index = ohlcData.indexWhere((d) => d.timestamp.millisecondsSinceEpoch == candle.timestamp);
    
    if (index >= 0 && index < indicatorValues!.length) {
      final value = indicatorValues![index];
      if (value.isNaN) return 'N/A';
      return value.toStringAsFixed(2);
    }
    return 'N/A';
  }
}
