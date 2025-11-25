import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/portfolio_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _qtyController.addListener(_updateTotal);
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
          const SizedBox(height: 24),
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
