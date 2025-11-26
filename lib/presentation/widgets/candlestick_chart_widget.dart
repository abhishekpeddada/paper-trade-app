import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/ohlc_data.dart';
import '../../core/theme/app_theme.dart';

class CandlestickChartWidget extends StatefulWidget {
  final List<OHLCData> ohlcData;
  final List<double>? indicatorValues;
  final String? indicatorName;

  const CandlestickChartWidget({
    super.key,
    required this.ohlcData,
    this.indicatorValues,
    this.indicatorName,
  });

  @override
  State<CandlestickChartWidget> createState() => _CandlestickChartWidgetState();
}

class _CandlestickChartWidgetState extends State<CandlestickChartWidget> {
  double _minVisibleIndex = 0;
  double _maxVisibleIndex = 0;
  double? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _maxVisibleIndex = widget.ohlcData.length.toDouble();
    // Show last 50 candles initially
    _minVisibleIndex = (_maxVisibleIndex - 50).clamp(0, _maxVisibleIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ohlcData.isEmpty) {
      return Container(
        height: 450,
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

    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Chart info
          if (_touchedIndex != null) _buildChartInfo(),
          // Main chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              child: LineChart(
                _buildChartData(),
                duration: Duration.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartInfo() {
    final index = _touchedIndex!.round();
    if (index < 0 || index >= widget.ohlcData.length) return const SizedBox.shrink();
    
    final candle = widget.ohlcData[index];
    final indicatorValue = (widget.indicatorValues != null && 
                           index < widget.indicatorValues!.length)
        ? widget.indicatorValues![index]
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildInfoItem('O', candle.open, AppTheme.textPrimary),
          const SizedBox(width: 12),
          _buildInfoItem('H', candle.high, AppTheme.primaryColor),
          const SizedBox(width: 12),
          _buildInfoItem('L', candle.low, AppTheme.secondaryColor),
          const SizedBox(width: 12),
          _buildInfoItem('C', candle.close, candle.close >= candle.open 
              ? AppTheme.primaryColor 
              : AppTheme.secondaryColor),
          if (indicatorValue != null && !indicatorValue.isNaN) ...[
            const SizedBox(width: 12),
            _buildInfoItem(
              widget.indicatorName ?? 'IND',
              indicatorValue,
              AppTheme.accentColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, double value, Color color) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData() {
    final visibleStart = _minVisibleIndex.floor();
    final visibleEnd = _maxVisibleIndex.ceil().clamp(0, widget.ohlcData.length);
    final visibleData = widget.ohlcData.sublist(
      visibleStart.clamp(0, widget.ohlcData.length),
      visibleEnd,
    );

    // Find min/max for Y axis
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;
    for (var candle in visibleData) {
      if (candle.low < minPrice) minPrice = candle.low;
      if (candle.high > maxPrice) maxPrice = candle.high;
    }

    // Include indicator values in min/max if present
    if (widget.indicatorValues != null) {
      for (int i = visibleStart; i < visibleEnd && i < widget.indicatorValues!.length; i++) {
        final val = widget.indicatorValues![i];
        if (!val.isNaN) {
          if (val < minPrice) minPrice = val;
          if (val > maxPrice) maxPrice = val;
        }
      }
    }

    final padding = (maxPrice - minPrice) * 0.1;
    minPrice -= padding;
    maxPrice += padding;

    return LineChartData(
      minX: _minVisibleIndex,
      maxX: _maxVisibleIndex,
      minY: minPrice,
      maxY: maxPrice,
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: false,
        touchCallback: (event, response) {
          if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
            setState(() {
              _touchedIndex = response.lineBarSpots!.first.x;
            });
          }
        },
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(color: Colors.white.withValues(alpha: 0.3), strokeWidth: 2),
              FlDotData(show: false),
            );
          }).toList();
        },
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxPrice - minPrice) / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppTheme.textSecondary.withValues(alpha: 0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (visibleEnd - visibleStart) / 5,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= widget.ohlcData.length) {
                return const SizedBox.shrink();
              }
              final date = widget.ohlcData[index].timestamp;
              return Text(
                '${date.month}/${date.day}',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        // Candlesticks as vertical lines with colors
        ..._buildCandlestickBars(),
        // Indicator overlay line
        if (widget.indicatorValues != null) _buildIndicatorLine(),
      ],
    );
  }

  List<LineChartBarData> _buildCandlestickBars() {
    List<LineChartBarData> bars = [];
    
    for (int i = 0; i < widget.ohlcData.length; i++) {
      final candle = widget.ohlcData[i];
      final isGreen = candle.close >= candle.open;
      final color = isGreen ? AppTheme.primaryColor : AppTheme.secondaryColor;

      // High-Low wick
      bars.add(LineChartBarData(
        spots: [
          FlSpot(i.toDouble(), candle.low),
          FlSpot(i.toDouble(), candle.high),
        ],
        color: color.withValues(alpha: 0.5),
        barWidth: 1,
        dotData: const FlDotData(show: false),
        isCurved: false,
      ));

      // Open-Close body
      bars.add(LineChartBarData(
        spots: [
          FlSpot(i.toDouble(), candle.open),
          FlSpot(i.toDouble(), candle.close),
        ],
        color: color,
        barWidth: 3,
        dotData: const FlDotData(show: false),
        isCurved: false,
      ));
    }

    return bars;
  }

  LineChartBarData _buildIndicatorLine() {
    List<FlSpot> spots = [];
    
    for (int i = 0; i < widget.indicatorValues!.length && i < widget.ohlcData.length; i++) {
      final value = widget.indicatorValues![i];
      if (!value.isNaN) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }

    return LineChartBarData(
      spots: spots,
      color: AppTheme.accentColor,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      isCurved: true,
      curveSmoothness: 0.2,
      isStrokeCapRound: true,
    );
  }
}
