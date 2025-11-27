import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/ohlc_data.dart';
import '../../data/models/trading_strategy.dart';
import '../../core/theme/app_theme.dart';

class CandlestickChartWidget extends StatefulWidget {
  final List<OHLCData> ohlcData;
  final StrategyResult? strategyResult;

  const CandlestickChartWidget({
    super.key,
    required this.ohlcData,
    this.strategyResult,
  });

  @override
  State<CandlestickChartWidget> createState() => _CandlestickChartWidgetState();
}

class _CandlestickChartWidgetState extends State<CandlestickChartWidget> {
  double _minVisibleIndex = 0;
  double _maxVisibleIndex = 50;
  double? _touchedX;
  
  // For gestures
  double _lastScale = 1.0;
  double _lastFocalPointX = 0;

  bool get _isOscillator {
    if (widget.strategyResult == null) return false;
    final name = widget.strategyResult!.indicatorName.toLowerCase();
    return name.contains('rsi') || name.contains('macd');
  }

  @override
  void initState() {
    super.initState();
    _resetView();
  }

  @override
  void didUpdateWidget(CandlestickChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ohlcData.length != oldWidget.ohlcData.length) {
      _resetView();
    }
  }

  void _resetView() {
    _maxVisibleIndex = widget.ohlcData.length.toDouble();
    _minVisibleIndex = (_maxVisibleIndex - 50).clamp(0, _maxVisibleIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ohlcData.isEmpty) {
      return Container(
        height: 500,
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
      height: _isOscillator ? 600 : 500,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          if (_touchedX != null) _buildInfoBar(),
          Expanded(
            flex: _isOscillator ? 2 : 1,
            child: _buildPriceChart(),
          ),
          if (_isOscillator) ...[
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              flex: 1,
              child: _buildOscillatorChart(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    final index = _touchedX!.round().clamp(0, widget.ohlcData.length - 1);
    final candle = widget.ohlcData[index];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.backgroundColor.withValues(alpha: 0.8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _infoChip('O', candle.open, Colors.white70),
            _infoChip('H', candle.high, AppTheme.primaryColor),
            _infoChip('L', candle.low, AppTheme.secondaryColor),
            _infoChip('C', candle.close, 
              candle.close >= candle.open ? AppTheme.primaryColor : AppTheme.secondaryColor),
            
            if (widget.strategyResult != null && index < widget.strategyResult!.indicatorLine.length) ...[
              const SizedBox(width: 8),
              const Text('|', style: TextStyle(color: Colors.white24)),
              const SizedBox(width: 8),
              _buildIndicatorInfo(index),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
            TextSpan(
              text: value.toStringAsFixed(2),
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorInfo(int index) {
    final result = widget.strategyResult!;
    List<Widget> widgets = [];

    if (index < result.indicatorLine.length && !result.indicatorLine[index].isNaN) {
      widgets.add(_infoChip(
        result.indicatorName,
        result.indicatorLine[index],
        AppTheme.accentColor,
      ));
    }

    if (result.secondaryLine != null && 
        index < result.secondaryLine!.length && 
        !result.secondaryLine![index].isNaN) {
      widgets.add(_infoChip(
        result.secondaryName ?? 'Sig',
        result.secondaryLine![index],
        Colors.orange,
      ));
    }

    final signals = result.signals.where((s) => s.index == index).toList();
    for (var signal in signals) {
      widgets.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: signal.type == SignalType.buy 
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : AppTheme.secondaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          signal.type == SignalType.buy ? '📈 BUY' : '📉 SELL',
          style: TextStyle(
            color: signal.type == SignalType.buy ? AppTheme.primaryColor : AppTheme.secondaryColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
    }

    return Row(children: widgets);
  }

  Widget _buildPriceChart() {
    return GestureDetector(
      onLongPressStart: (details) {
        // Find the x position and convert to data index
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        final chartWidth = renderBox.size.width - 24; // Account for padding
        final relativeX = (localPosition.dx - 8) / chartWidth;
        final dataIndex = _minVisibleIndex + (relativeX * (_maxVisibleIndex - _minVisibleIndex));
        
        setState(() {
          _touchedX = dataIndex.clamp(0, widget.ohlcData.length - 1).toDouble();
        });
      },
      onLongPressMoveUpdate: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        final chartWidth = renderBox.size.width - 24;
        final relativeX = (localPosition.dx - 8) / chartWidth;
        final dataIndex = _minVisibleIndex + (relativeX * (_maxVisibleIndex - _minVisibleIndex));
        
        setState(() {
          _touchedX = dataIndex.clamp(0, widget.ohlcData.length - 1).toDouble();
        });
      },
      onLongPressEnd: (details) {
        setState(() {
          _touchedX = null;
        });
      },
      onScaleStart: (details) {
        _lastScale = 1.0;
        _lastFocalPointX = details.focalPoint.dx;
      },
      onScaleUpdate: (details) {
        setState(() {
          final visibleRange = _maxVisibleIndex - _minVisibleIndex;
          
          // Zoom (pinch gesture)
          if (details.scale != _lastScale && details.scale != 1.0) {
            final zoomFactor = details.scale / _lastScale;
            final newRange = (visibleRange / zoomFactor).clamp(10.0, widget.ohlcData.length.toDouble());
            final center = (_minVisibleIndex + _maxVisibleIndex) / 2;
            
            _minVisibleIndex = (center - newRange / 2).clamp(0, widget.ohlcData.length.toDouble());
            _maxVisibleIndex = (center + newRange / 2).clamp(0, widget.ohlcData.length.toDouble());
            _lastScale = details.scale;
          }
          
          // Pan (drag gesture) - only if not zooming
          if (details.scale == 1.0 || details.scale == _lastScale) {
            final dx = details.focalPoint.dx - _lastFocalPointX;
            final shift = -(dx / 500) * visibleRange; // Increased divisor for smoother scroll
            
            final newMin = (_minVisibleIndex + shift).clamp(0.0, widget.ohlcData.length.toDouble());
            final newMax = (_maxVisibleIndex + shift).clamp(0.0, widget.ohlcData.length.toDouble());
            
            // Only update if both are valid
            if (newMin >= 0 && newMax <= widget.ohlcData.length.toDouble()) {
              _minVisibleIndex = newMin.toDouble();
              _maxVisibleIndex = newMax.toDouble();
            }
          }
          
          _lastFocalPointX = details.focalPoint.dx;
        });
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: LineChart(
          _buildPriceChartData(),
          duration: Duration.zero,
        ),
      ),
    );
  }

  Widget _buildOscillatorChart() {
    return GestureDetector(
      onLongPressStart: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        final chartWidth = renderBox.size.width - 24;
        final relativeX = (localPosition.dx - 8) / chartWidth;
        final dataIndex = _minVisibleIndex + (relativeX * (_maxVisibleIndex - _minVisibleIndex));
        
        setState(() {
          _touchedX = dataIndex.clamp(0, widget.ohlcData.length - 1).toDouble();
        });
      },
      onLongPressMoveUpdate: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        final chartWidth = renderBox.size.width - 24;
        final relativeX = (localPosition.dx - 8) / chartWidth;
        final dataIndex = _minVisibleIndex + (relativeX * (_maxVisibleIndex - _minVisibleIndex));
        
        setState(() {
          _touchedX = dataIndex.clamp(0, widget.ohlcData.length - 1).toDouble();
        });
      },
      onLongPressEnd: (details) {
        setState(() {
          _touchedX = null;
        });
      },
      onScaleStart: (details) {
        _lastScale = 1.0;
        _lastFocalPointX = details.focalPoint.dx;
      },
      onScaleUpdate: (details) {
        setState(() {
          final visibleRange = _maxVisibleIndex - _minVisibleIndex;
          
          // Zoom
          if (details.scale != _lastScale && details.scale != 1.0) {
            final zoomFactor = details.scale / _lastScale;
            final newRange = (visibleRange / zoomFactor).clamp(10.0, widget.ohlcData.length.toDouble());
            final center = (_minVisibleIndex + _maxVisibleIndex) / 2;
            
            _minVisibleIndex = (center - newRange / 2).clamp(0, widget.ohlcData.length.toDouble());
            _maxVisibleIndex = (center + newRange / 2).clamp(0, widget.ohlcData.length.toDouble());
            _lastScale = details.scale;
          }
          
          // Pan
          if (details.scale == 1.0 || details.scale == _lastScale) {
            final dx = details.focalPoint.dx - _lastFocalPointX;
            final shift = -(dx / 500) * visibleRange;
            
            final newMin = (_minVisibleIndex + shift).clamp(0.0, widget.ohlcData.length.toDouble());
            final newMax = (_maxVisibleIndex + shift).clamp(0.0, widget.ohlcData.length.toDouble());
            
            if (newMin >= 0 && newMax <= widget.ohlcData.length.toDouble()) {
              _minVisibleIndex = newMin.toDouble();
              _maxVisibleIndex = newMax.toDouble();
            }
          }
          
          _lastFocalPointX = details.focalPoint.dx;
        });
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: LineChart(
          _buildOscillatorChartData(),
          duration: Duration.zero,
        ),
      ),
    );
  }

  LineChartData _buildPriceChartData() {
    final visibleStart = _minVisibleIndex.floor();
    final visibleEnd = _maxVisibleIndex.ceil().clamp(0, widget.ohlcData.length);
    final visibleData = widget.ohlcData.sublist(
      visibleStart.clamp(0, widget.ohlcData.length),
      visibleEnd,
    );

    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;
    
    for (var candle in visibleData) {
      if (candle.low < minPrice) minPrice = candle.low;
      if (candle.high > maxPrice) maxPrice = candle.high;
    }

    // Include price-based indicators
    if (widget.strategyResult != null && !_isOscillator) {
      for (int i = visibleStart; i < visibleEnd; i++) {
        if (i < widget.strategyResult!.indicatorLine.length) {
          final val = widget.strategyResult!.indicatorLine[i];
          if (!val.isNaN) {
            if (val < minPrice) minPrice = val;
            if (val > maxPrice) maxPrice = val;
          }
        }
        if (widget.strategyResult!.secondaryLine != null &&
            i < widget.strategyResult!.secondaryLine!.length) {
          final val = widget.strategyResult!.secondaryLine![i];
          if (!val.isNaN) {
            if (val < minPrice) minPrice = val;
            if (val > maxPrice) maxPrice = val;
          }
        }
      }
    }

    final padding = (maxPrice - minPrice) * 0.05;
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
          setState(() {
            if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
              _touchedX = response.lineBarSpots!.first.x;
            }
          });
        },
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(color: Colors.white.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [5, 5]),
              FlDotData(show: false),
            );
          }).toList();
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.transparent,
          tooltipBorder: const BorderSide(color: Colors.transparent),
          getTooltipItems: (spots) => [],
        ),
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
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: !_isOscillator,
            reservedSize: 30,
            interval: (visibleEnd - visibleStart) / 5,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= widget.ohlcData.length) return const SizedBox.shrink();
              final date = widget.ohlcData[index].timestamp;
              return Text(
                '${date.month}/${date.day}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        ..._buildCandlestickBars(),
        if (widget.strategyResult != null && !_isOscillator) ..._buildIndicatorLines(),
      ],
      extraLinesData: _touchedX != null ? ExtraLinesData(
        verticalLines: [
          VerticalLine(
            x: _touchedX!,
            color: Colors.white.withValues(alpha: 0.3),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ],
      ) : null,
    );
  }

  LineChartData _buildOscillatorChartData() {
    if (widget.strategyResult == null) {
      return LineChartData(lineBarsData: []);
    }

    final visibleStart = _minVisibleIndex.floor();
    final visibleEnd = _maxVisibleIndex.ceil().clamp(0, widget.ohlcData.length);

    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;

    for (int i = visibleStart; i < visibleEnd; i++) {
      if (i < widget.strategyResult!.indicatorLine.length) {
        final val = widget.strategyResult!.indicatorLine[i];
        if (!val.isNaN) {
          if (val < minVal) minVal = val;
          if (val > maxVal) maxVal = val;
        }
      }
      if (widget.strategyResult!.secondaryLine != null &&
          i < widget.strategyResult!.secondaryLine!.length) {
        final val = widget.strategyResult!.secondaryLine![i];
        if (!val.isNaN) {
          if (val < minVal) minVal = val;
          if (val > maxVal) maxVal = val;
        }
      }
    }

    final padding = (maxVal - minVal) * 0.1;
    minVal -= padding;
    maxVal += padding;

    return LineChartData(
      minX: _minVisibleIndex,
      maxX: _maxVisibleIndex,
      minY: minVal,
      maxY: maxVal,
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: false,
        touchCallback: (event, response) {
          setState(() {
            if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
              _touchedX = response.lineBarSpots!.first.x;
            }
          });
        },
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(color: Colors.white.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [5, 5]),
              FlDotData(show: false),
            );
          }).toList();
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.transparent,
          tooltipBorder: const BorderSide(color: Colors.transparent),
          getTooltipItems: (spots) => [],
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxVal - minVal) / 4,
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
                value.toStringAsFixed(1),
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
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
              if (index < 0 || index >= widget.ohlcData.length) return const SizedBox.shrink();
              final date = widget.ohlcData[index].timestamp;
              return Text(
                '${date.month}/${date.day}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: _buildIndicatorLines(),
      extraLinesData: _touchedX != null ? ExtraLinesData(
        verticalLines: [
          VerticalLine(
            x: _touchedX!,
            color: Colors.white.withValues(alpha: 0.3),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ],
      ) : null,
    );
  }

  List<LineChartBarData> _buildCandlestickBars() {
    List<LineChartBarData> bars = [];
    
    for (int i = 0; i < widget.ohlcData.length; i++) {
      final candle = widget.ohlcData[i];
      final isGreen = candle.close >= candle.open;
      final color = isGreen ? AppTheme.primaryColor : AppTheme.secondaryColor;

      // Wick (high-low)
      bars.add(LineChartBarData(
        spots: [FlSpot(i.toDouble(), candle.low), FlSpot(i.toDouble(), candle.high)],
        color: color.withValues(alpha: 0.5),
        barWidth: 1,
        dotData: const FlDotData(show: false),
        isCurved: false,
      ));

      // Body (open-close)
      bars.add(LineChartBarData(
        spots: [FlSpot(i.toDouble(), candle.open), FlSpot(i.toDouble(), candle.close)],
        color: color,
        barWidth: 4,
        dotData: const FlDotData(show: false),
        isCurved: false,
        isStrokeCapRound: true,
      ));
    }

    return bars;
  }

  List<LineChartBarData> _buildIndicatorLines() {
    if (widget.strategyResult == null) return [];
    
    List<LineChartBarData> lines = [];

    // Main indicator
    List<FlSpot> mainSpots = [];
    for (int i = 0; i < widget.strategyResult!.indicatorLine.length && i < widget.ohlcData.length; i++) {
      final value = widget.strategyResult!.indicatorLine[i];
      if (!value.isNaN) {
        mainSpots.add(FlSpot(i.toDouble(), value));
      }
    }
    if (mainSpots.isNotEmpty) {
      lines.add(LineChartBarData(
        spots: mainSpots,
        color: AppTheme.accentColor,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        isCurved: true,
        curveSmoothness: 0.2,
      ));
    }

    // Secondary line
    if (widget.strategyResult!.secondaryLine != null) {
      List<FlSpot> secondarySpots = [];
      for (int i = 0; i < widget.strategyResult!.secondaryLine!.length && i < widget.ohlcData.length; i++) {
        final value = widget.strategyResult!.secondaryLine![i];
        if (!value.isNaN) {
          secondarySpots.add(FlSpot(i.toDouble(), value));
        }
      }
      if (secondarySpots.isNotEmpty) {
        lines.add(LineChartBarData(
          spots: secondarySpots,
          color: Colors.orange,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          isCurved: true,
          curveSmoothness: 0.2,
        ));
      }
    }

    return lines;
  }
}
