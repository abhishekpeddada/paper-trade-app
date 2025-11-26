import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../data/models/ohlc_data.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_helper.dart';

class FullInteractiveChartWidget extends StatefulWidget {
  final List<OHLCData> ohlcData;
  final String symbol;

  const FullInteractiveChartWidget({
    super.key,
    required this.ohlcData,
    required this.symbol,
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

  String get _currencySymbol => CurrencyHelper.getCurrencySymbol(widget.symbol);

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
              if (details.scale != 1.0) {
                final newScale = (_baseScale * details.scale).clamp(0.5, 5.0);
                final focalPoint = details.localFocalPoint.dx;
                final relativeFocal = focalPoint - _offsetX;
                final newRelativeFocal = relativeFocal * (newScale / _scale);
                _offsetX += relativeFocal - newRelativeFocal;
                _scale = newScale;
              }

              final deltaX = details.localFocalPoint.dx - _lastFocalX;
              _offsetX += deltaX;
              _lastFocalX = details.localFocalPoint.dx;

              final size = context.size;
              if (size != null) {
                final candleWidth = 8.0 * _scale;
                final candleSpacing = 2.0 * _scale;
                final totalContentWidth = widget.ohlcData.length * (candleWidth + candleSpacing);
                final minOffset = size.width - totalContentWidth - 50;
                final maxOffset = 50.0;
                
                if (totalContentWidth > size.width) {
                  _offsetX = _offsetX.clamp(minOffset, maxOffset);
                } else {
                  _offsetX = 0;
                }
              }
            });
          },
          onTapDown: (details) => setState(() => _touchPosition = details.localPosition),
          onTapUp: (_) => setState(() => _touchPosition = null),
          onTapCancel: () => setState(() => _touchPosition = null),
          onLongPressStart: (details) => setState(() => _touchPosition = details.localPosition),
          onLongPressMoveUpdate: (details) => setState(() => _touchPosition = details.localPosition),
          onLongPressEnd: (_) => setState(() => _touchPosition = null),
          
          child: CustomPaint(
            painter: CandlestickChartPainter(
              ohlcData: widget.ohlcData,
              scale: _scale,
              offsetX: _offsetX,
              touchPosition: _touchPosition,
              currencySymbol: _currencySymbol,
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
  final String currencySymbol;

  CandlestickChartPainter({
    required this.ohlcData,
    required this.scale,
    required this.offsetX,
    this.touchPosition,
    required this.currencySymbol,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ohlcData.isEmpty) return;

    double minPrice = ohlcData.map((d) => d.low).reduce(math.min);
    double maxPrice = ohlcData.map((d) => d.high).reduce(math.max);
    final priceRange = maxPrice - minPrice;
    final padding = priceRange * 0.1;
    minPrice -= padding;
    maxPrice += padding;

    final chartHeight = size.height - 60;
    final candleWidth = 8.0 * scale;
    final candleSpacing = 2.0 * scale;
    final totalCandleWidth = candleWidth + candleSpacing;

    _drawGridLines(canvas, size, minPrice, maxPrice, chartHeight);

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

      final wickPaint = Paint()
        ..color = color.withValues(alpha: 0.7)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);

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

    if (touchPosition != null) {
      _drawCrosshair(canvas, size, touchPosition!, minPrice, maxPrice, chartHeight, totalCandleWidth);
    }

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

    canvas.drawLine(Offset(touch.dx, 0), Offset(touch.dx, chartHeight), crosshairPaint);
    canvas.drawLine(Offset(0, touch.dy), Offset(size.width, touch.dy), crosshairPaint);

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
      'O: $currencySymbol${candle.open.toStringAsFixed(2)}',
      'H: $currencySymbol${candle.high.toStringAsFixed(2)}',
      'L: $currencySymbol${candle.low.toStringAsFixed(2)}',
      'C: $currencySymbol${candle.close.toStringAsFixed(2)}',
    ];

    const lineHeight = 16.0;
    const padding = 8.0;
    const boxWidth = 150.0;
    final boxHeight = lines.length * lineHeight + padding * 2;

    var boxX = touch.dx + 10;
    var boxY = touch.dy - boxHeight - 10;
    if (boxX + boxWidth > size.width) boxX = touch.dx - boxWidth - 10;
    if (boxY < 0) boxY = touch.dy + 10;

    final boxPaint = Paint()
      ..color = AppTheme.backgroundColor.withValues(alpha: 0.95);
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight),
      const Radius.circular(8),
    );
    canvas.drawRRect(boxRect, boxPaint);

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
        text: TextSpan(text: '$currencySymbol${price.toStringAsFixed(2)}', style: textStyle),
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
        oldDelegate.ohlcData != ohlcData ||
        oldDelegate.currencySymbol != currencySymbol;
  }
}
