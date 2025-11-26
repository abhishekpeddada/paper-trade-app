import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../data/models/ohlc_data.dart';
import '../../core/theme/app_theme.dart';

class FullInteractiveChartWidget extends StatefulWidget {
  final List<OHLCData> ohlcData;

  const FullInteractiveChartWidget({
    super.key,
    required this.ohlcData,
  });

  @override
  State<FullInteractiveChartWidget> createState() => _FullInteractiveChartWidgetState();
}

class _FullInteractiveChartWidgetState extends State<FullInteractiveChartWidget> {
  double _scale = 1.0;
  double _baseScale = 1.0;
  double _offsetX = 0.0;
  double _baseOffsetX = 0.0;
  Offset? _touchPosition;
  double _lastFocalX = 0.0;

  @override
  Widget build(BuildContext context) {
    if (widget.ohlcData.isEmpty) {
      return Container(
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
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onScaleStart: (details) {
            _baseScale = _scale;
            _baseOffsetX = _offsetX;
            _lastFocalX = details.localFocalPoint.dx;
          },
          onScaleUpdate: (details) {
            setState(() {
              // Handle Zoom
              // Only zoom if scale changed significantly to avoid jitter during panning
              if (details.scale != 1.0) {
                final newScale = (_baseScale * details.scale).clamp(0.5, 5.0);
                
                // Adjust offset to zoom around focal point
                final focalPoint = details.localFocalPoint.dx;
                final relativeFocal = focalPoint - _offsetX;
                final newRelativeFocal = relativeFocal * (newScale / _scale);
                _offsetX += relativeFocal - newRelativeFocal;
                
                _scale = newScale;
              }

              // Handle Pan
              // Calculate delta since start of gesture
              final deltaX = details.localFocalPoint.dx - _lastFocalX;
              _offsetX += deltaX;
              _lastFocalX = details.localFocalPoint.dx;

              // Constrain panning
              final size = context.size;
              if (size != null) {
                final candleWidth = 8.0 * _scale;
                final candleSpacing = 2.0 * _scale;
                final totalContentWidth = widget.ohlcData.length * (candleWidth + candleSpacing);
                final minOffset = size.width - totalContentWidth - 50; // Allow some overscroll
                final maxOffset = 50.0; // Allow some overscroll
                
                if (totalContentWidth > size.width) {
                  _offsetX = _offsetX.clamp(minOffset, maxOffset);
                } else {
                  // If content fits, center or align left, don't allow pan
                  _offsetX = 0;
                }
              }
            });
          },
          
          // Tap to show crosshair
          onTapDown: (details) {
            setState(() {
              _touchPosition = details.localPosition;
            });
          },
          onTapUp: (_) {
            setState(() {
              _touchPosition = null;
            });
          },
          onTapCancel: () {
            setState(() {
              _touchPosition = null;
            });
          },
          
          // Long press for crosshair
          onLongPressStart: (details) {
            setState(() {
              _touchPosition = details.localPosition;
            });
          },
          onLongPressMoveUpdate: (details) {
            setState(() {
              _touchPosition = details.localPosition;
            });
          },
          onLongPressEnd: (_) {
            setState(() {
              _touchPosition = null;
            });
          },
          
          child: CustomPaint(
            painter: CandlestickChartPainter(
              ohlcData: widget.ohlcData,
              scale: _scale,
              offsetX: _offsetX,
              touchPosition: _touchPosition,
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

class CandlestickChartPainter extends CustomPainter {
  final List<OHLCData> ohlcData;
  final double scale;
  final double offsetX;
  final Offset? touchPosition;

  CandlestickChartPainter({
    required this.ohlcData,
    required this.scale,
    required this.offsetX,
    this.touchPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ohlcData.isEmpty) return;

    // Calculate price range
    double minPrice = ohlcData.map((d) => d.low).reduce(math.min);
    double maxPrice = ohlcData.map((d) => d.high).reduce(math.max);
    final priceRange = maxPrice - minPrice;
    final padding = priceRange * 0.1;
    minPrice -= padding;
    maxPrice += padding;

    // Chart dimensions
    final chartHeight = size.height - 60; // Reserve space for labels
    final candleWidth = 8.0 * scale;
    final candleSpacing = 2.0 * scale;
    final totalCandleWidth = candleWidth + candleSpacing;

    // Draw grid lines
    _drawGridLines(canvas, size, minPrice, maxPrice, chartHeight);

    // Draw candles
    for (int i = 0; i < ohlcData.length; i++) {
      final candle = ohlcData[i];
      final x = offsetX + i * totalCandleWidth + candleWidth / 2;

      if (x < -candleWidth || x > size.width + candleWidth) continue;

      final openY = _priceToY(candle.open, minPrice, maxPrice, chartHeight);
      final closeY = _priceToY(candle.close, minPrice, maxPrice, chartHeight);
      final highY = _priceToY(candle.high, minPrice, maxPrice, chartHeight);
      final lowY = _priceToY(candle.low, minPrice, maxPrice, chartHeight);

      final isGreen = candle.close >= candle.open;
      final color = isGreen ? AppTheme.primaryColor : AppTheme.secondaryColor;

      // Draw wick (high-low line)
      final wickPaint = Paint()
        ..color = color.withValues(alpha: 0.7)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);

      // Draw body (open-close rectangle)
      final bodyPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final bodyRect = Rect.fromLTRB(
        x - candleWidth / 2,
        math.min(openY, closeY),
        x + candleWidth / 2,
        math.max(openY, closeY),
      );
      canvas.drawRect(bodyRect, bodyPaint);
    }

    // Draw crosshair if touching
    if (touchPosition != null) {
      _drawCrosshair(canvas, size, touchPosition!, minPrice, maxPrice, chartHeight, totalCandleWidth);
    }

    // Draw price labels
    _drawPriceLabels(canvas, size, minPrice, maxPrice, chartHeight);
  }

  void _drawGridLines(Canvas canvas, Size size, double minPrice, double maxPrice, double chartHeight) {
    final gridPaint = Paint()
      ..color = AppTheme.textSecondary.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = i * chartHeight / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawCrosshair(Canvas canvas, Size size, Offset touch, double minPrice, double maxPrice, double chartHeight, double totalCandleWidth) {
    final crosshairPaint = Paint()
      ..color = AppTheme.accentColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.5;

    // Draw vertical line
    canvas.drawLine(
      Offset(touch.dx, 0),
      Offset(touch.dx, chartHeight),
      crosshairPaint,
    );

    // Draw horizontal line
    canvas.drawLine(
      Offset(0, touch.dy),
      Offset(size.width, touch.dy),
      crosshairPaint,
    );

    // Find which candle is touched
    final candleIndex = ((touch.dx - offsetX) / totalCandleWidth).floor();
    if (candleIndex >= 0 && candleIndex < ohlcData.length) {
      final candle = ohlcData[candleIndex];
      _drawInfoBox(canvas, size, candle, touch);
    }
  }

  void _drawInfoBox(Canvas canvas, Size size, OHLCData candle, Offset touch) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    final lines = [
      'O: \$${candle.open.toStringAsFixed(2)}',
      'H: \$${candle.high.toStringAsFixed(2)}',
      'L: \$${candle.low.toStringAsFixed(2)}',
      'C: \$${candle.close.toStringAsFixed(2)}',
    ];

    // Calculate box size
    const lineHeight = 16.0;
    const padding = 8.0;
    const boxWidth = 150.0;
    final boxHeight = lines.length * lineHeight + padding * 2;

    // Position box to avoid edges
    var boxX = touch.dx + 10;
    var boxY = touch.dy - boxHeight - 10;
    if (boxX + boxWidth > size.width) boxX = touch.dx - boxWidth - 10;
    if (boxY < 0) boxY = touch.dy + 10;

    // Draw box background
    final boxPaint = Paint()
      ..color = AppTheme.backgroundColor.withValues(alpha: 0.95);
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight),
      const Radius.circular(8),
    );
    canvas.drawRRect(boxRect, boxPaint);

    // Draw text
    for (int i = 0; i < lines.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(text: lines[i], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(boxX + padding, boxY + padding + i * lineHeight));
    }
  }

  void _drawPriceLabels(Canvas canvas, Size size, double minPrice, double maxPrice, double chartHeight) {
    final textStyle = TextStyle(
      color: AppTheme.textSecondary,
      fontSize: 10,
    );

    for (int i = 0; i <= 4; i++) {
      final price = minPrice + (maxPrice - minPrice) * (4 - i) / 4;
      final y = i * chartHeight / 4;

      final textPainter = TextPainter(
        text: TextSpan(text: '\$${price.toStringAsFixed(2)}', style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - 60, y - 6));
    }
  }

  double _priceToY(double price, double minPrice, double maxPrice, double chartHeight) {
    return chartHeight - ((price - minPrice) / (maxPrice - minPrice)) * chartHeight;
  }

  @override
  bool shouldRepaint(CandlestickChartPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.offsetX != offsetX ||
        oldDelegate.touchPosition != touchPosition ||
        oldDelegate.ohlcData != ohlcData;
  }
}
