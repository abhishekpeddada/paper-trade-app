import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/portfolio_provider.dart';
import '../../logic/providers/ai_provider.dart';
import '../../data/models/ai_signal.dart';
import '../../data/models/stock_model.dart';
import '../../data/models/trade_models.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class TradeBottomSheet extends StatefulWidget {
  final Stock stock;
  final OrderType type;

  const TradeBottomSheet({super.key, required this.stock, required this.type});

  @override
  State<TradeBottomSheet> createState() => _TradeBottomSheetState();
}

class _TradeBottomSheetState extends State<TradeBottomSheet> {
  final TextEditingController _qtyController = TextEditingController();
  double _estimatedTotal = 0.0;
  AISignal? _aiSignal;
  bool _showingAIAnalysis = false;

  @override
  void initState() {
    super.initState();
    _qtyController.addListener(_updateTotal);
    _fetchAISignal();
  }

  void _fetchAISignal() async {
    final aiProvider = context.read<AIProvider>();
    final signal = await aiProvider.analyzeStock(widget.stock.symbol);
    if (mounted) {
      setState(() {
        _aiSignal = signal;
      });
    }
  }

  void _updateTotal() {
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    setState(() {
      _estimatedTotal = qty * widget.stock.price;
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = widget.type == OrderType.buy;
    final color = isBuy ? AppTheme.primaryColor : AppTheme.secondaryColor;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isBuy ? 'Buy' : 'Sell'} ${widget.stock.symbol}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '\$${widget.stock.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<AIProvider>(
            builder: (context, aiProvider, child) {
              if (aiProvider.isAnalyzing) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Analyzing with AI...', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                );
              }
              
              if (_aiSignal != null) {
                final signalColor = _aiSignal!.signal == 'BUY' 
                    ? AppTheme.primaryColor 
                    : _aiSignal!.signal == 'SELL' 
                        ? AppTheme.secondaryColor 
                        : Colors.grey;
                        
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: signalColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: signalColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: signalColor, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'AI Signal: ${_aiSignal!.signal}',
                                style: TextStyle(
                                  color: signalColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: signalColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${(_aiSignal!.confidence * 100).toStringAsFixed(0)}% confidence',
                              style: TextStyle(
                                color: signalColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _aiSignal!.reasoning,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  hintText: 'Quantity',
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_estimatedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<PortfolioProvider>(
            builder: (context, provider, child) {
              return Text(
                'Available Balance: \$${provider.balance.toStringAsFixed(2)}',
                style: const TextStyle(color: AppTheme.textSecondary),
              );
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: isBuy ? 'BUY ORDER' : 'SELL ORDER',
            color: color,
            onPressed: () {
              final qty = double.tryParse(_qtyController.text) ?? 0.0;
              if (qty <= 0) return;

              try {
                context.read<PortfolioProvider>().executeOrder(
                  widget.stock.symbol,
                  qty,
                  widget.stock.price,
                  widget.type,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${isBuy ? 'Buy' : 'Sell'} order executed!'),
                    backgroundColor: color,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
