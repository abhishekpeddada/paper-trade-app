import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/ai_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AiActivityScreen extends StatelessWidget {
  const AiActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AiProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Trading Desk'),
      ),
      body: Column(
        children: [
          _buildSystemCard(context, aiProvider),
          const Divider(height: 1, color: AppTheme.surfaceColor),
          Expanded(
            child: _buildActivityLog(aiProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: aiProvider.isAnalyzing ? null : () => aiProvider.generateSystem(),
        backgroundColor: AppTheme.accentColor,
        label: Text(aiProvider.isAnalyzing ? 'Analyzing...' : 'Generate New System'),
        icon: aiProvider.isAnalyzing 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Icon(Icons.auto_awesome),
      ),
    );
  }

  Widget _buildSystemCard(BuildContext context, AiProvider provider) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Trading System',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (provider.apiKey == null)
                  const Text(
                    'API Key Required',
                    style: TextStyle(color: AppTheme.secondaryColor, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 12),
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

  Widget _buildActivityLog(AiProvider provider) {
    if (provider.activityLog.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'No activity yet',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.activityLog.length,
      itemBuilder: (context, index) {
        final log = provider.activityLog[index];
        final isError = log.contains('Error');
        final isTrade = log.contains('Executing');
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: isTrade ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)) : null,
          ),
          child: Text(
            log,
            style: TextStyle(
              color: isError ? AppTheme.secondaryColor : AppTheme.textPrimary,
              fontSize: 13,
              fontFamily: 'Monospace',
            ),
          ),
        );
      },
    );
  }


}
