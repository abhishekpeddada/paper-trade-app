import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/ai_provider.dart';
import '../../logic/providers/auto_trading_provider.dart';
import '../../logic/providers/portfolio_provider.dart';
import '../../logic/providers/watchlist_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import 'strategy_analyzer_screen.dart';
import 'bulk_analysis_screen.dart';

class AiActivityScreen extends StatelessWidget {
  const AiActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AIProvider>(context);
    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    final watchlistProvider = Provider.of<WatchlistProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Trading Desk'),
      ),
      body: Column(
        children: [
          _buildPineScriptCard(context),
          const SizedBox(height: 8),
          _buildSystemCard(context, aiProvider),
          const SizedBox(height: 8),
          _buildAutomationCard(context, aiProvider, portfolioProvider, watchlistProvider),
          const Divider(height: 1, color: AppTheme.surfaceColor),
          Expanded(
            child: _buildConsole(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationCard(BuildContext context, AIProvider ai, PortfolioProvider portfolio, WatchlistProvider watchlist) {
    return Consumer<AutoTradingProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Auto-Trading & Analysis',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              if (provider.isRunning)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: provider.progress,
                      backgroundColor: AppTheme.backgroundColor,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Processing... ${(provider.progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => provider.analyzeWatchlist(ai, portfolio, watchlist),
                            icon: const Icon(Icons.list_alt, size: 18),
                            label: const Text('Watchlist'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => provider.analyzePortfolio(ai, portfolio, watchlist, force: true),
                            icon: const Icon(Icons.pie_chart, size: 18),
                            label: const Text('Portfolio'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              side: const BorderSide(color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BulkAnalysisScreen()),
                          );
                        },
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Import CSV for Bulk Analysis'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsole(BuildContext context) {
    return Consumer<AutoTradingProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Console header with clear button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Analysis Logs',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (provider.logs.isNotEmpty)
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _copyLogsToClipboard(context, provider.logs),
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copy Logs',
                          color: AppTheme.textSecondary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => _showFullscreenLogs(context, provider.logs),
                          icon: const Icon(Icons.fullscreen, size: 18),
                          tooltip: 'Fullscreen',
                          color: AppTheme.textSecondary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: () => provider.clearLogs(),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Clear'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.surfaceColor),
            Expanded(child: _buildConsoleContent(provider)),
          ],
        );
      },
    );
  }

  Widget _buildConsoleContent(AutoTradingProvider provider) {
        if (provider.logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.terminal, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                const Text(
                  'Ready for automated analysis',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          reverse: false, // Show oldest first (chronological order)
          itemCount: provider.logs.length,
          itemBuilder: (context, index) {
            final log = provider.logs[index];
            final isError = log.contains('Error') || log.contains('failed');
            final isTrade = log.contains('Trade executed');
            final isSignal = log.contains('BUY') || log.contains('SELL');

            Color color = AppTheme.textSecondary;
            if (isError) color = AppTheme.secondaryColor;
            if (isTrade) color = AppTheme.primaryColor;
            if (isSignal) color = Colors.white;

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                log,
                style: TextStyle(
                  color: color,
                  fontFamily: 'Monospace',
                  fontSize: 12,
                ),
              ),
            );
          },
        );
      }

  Widget _buildPineScriptCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentColor.withOpacity(0.3), AppTheme.primaryColor.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StrategyAnalyzerScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.code, color: AppTheme.accentColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Strategy Analyzer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analyze stocks with built-in trading strategies',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: AppTheme.accentColor, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemCard(BuildContext context, AIProvider provider) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.psychology, color: AppTheme.accentColor.withValues(alpha: 0.7), size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'AI Trading System',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  // Enlarge button
                  IconButton(
                    onPressed: () => _showFullscreenSystem(context, provider.tradingSystem),
                    icon: const Icon(Icons.fullscreen, size: 20),
                    tooltip: 'Fullscreen',
                    color: AppTheme.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  // Clear button
                  IconButton(
                    onPressed: () => _confirmClearSystem(context, provider),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Clear System',
                    color: AppTheme.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  // Generate button
                  IconButton(
                    onPressed: provider.isAnalyzing ? null : () => _showPreferencesDialog(context, provider),
                    icon: provider.isAnalyzing 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentColor))
                        : const Icon(Icons.refresh, size: 20),
                    tooltip: provider.isAnalyzing ? 'Generating...' : 'Generate New',
                    color: AppTheme.accentColor,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.surfaceColor),
            // System content
            Expanded(
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: provider.tradingSystem,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5),
                    h1: const TextStyle(color: AppTheme.primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                    h2: const TextStyle(color: AppTheme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                    h3: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    strong: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                    listBullet: const TextStyle(color: AppTheme.accentColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreferencesDialog(BuildContext context, AIProvider provider) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'System Preferences',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add your trading preferences or requirements:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g., "Focus on momentum trading", "Include MACD indicator", "Low risk tolerance"...',
                hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Leave blank for general system',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.generateSystem(userPreferences: controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _copyLogsToClipboard(BuildContext context, List<String> logs) {
    final allLogs = logs.join('\n');
    Clipboard.setData(ClipboardData(text: allLogs));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copied to clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showFullscreenLogs(BuildContext context, List<String> logs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Analysis Logs'),
            actions: [
              IconButton(
                onPressed: () => _copyLogsToClipboard(context, logs),
                icon: const Icon(Icons.copy),
                tooltip: 'Copy All',
              ),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final isError = log.contains('Error') || log.contains('failed') || log.contains('❌');
              final isTrade = log.contains('Trade executed') || log.contains('💰');
              final isSignal = log.contains('BUY') || log.contains('SELL');
              final isHeader = log.contains('╔') || log.contains('║') || log.contains('╚');

              Color color = AppTheme.textSecondary;
              if (isError) color = AppTheme.secondaryColor;
              if (isTrade) color = AppTheme.primaryColor;
              if (isSignal) color = Colors.white;
              if (isHeader) color = AppTheme.accentColor;

              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: SelectableText(
                  log,
                  style: TextStyle(
                    color: color,
                    fontFamily: 'Monospace',
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFullscreenSystem(BuildContext context, String system) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('AI Trading System'),
            actions: [
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: system));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('System copied to clipboard'),
                      duration: Duration(seconds: 2),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                tooltip: 'Copy System',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(
              data: system,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5),
                h1: const TextStyle(color: AppTheme.primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                h2: const TextStyle(color: AppTheme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                h3: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                strong: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                listBullet: const TextStyle(color: AppTheme.accentColor),
                code: TextStyle(
                  backgroundColor: AppTheme.surfaceColor,
                  color: AppTheme.accentColor,
                  fontFamily: 'Monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmClearSystem(BuildContext context, AIProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Clear Trading System?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This will delete your current trading system. You can generate a new one anytime.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearTradingSystem();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Trading system cleared'),
                  duration: Duration(seconds: 2),
                  backgroundColor: AppTheme.accentColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
