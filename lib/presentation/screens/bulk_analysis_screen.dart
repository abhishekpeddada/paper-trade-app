import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../logic/providers/auto_trading_provider.dart';
import '../../logic/providers/ai_provider.dart';
import '../../logic/providers/portfolio_provider.dart';
import '../../logic/providers/watchlist_provider.dart';

class BulkAnalysisScreen extends StatefulWidget {
  const BulkAnalysisScreen({super.key});

  @override
  State<BulkAnalysisScreen> createState() => _BulkAnalysisScreenState();
}

class _BulkAnalysisScreenState extends State<BulkAnalysisScreen> {
  List<String> _symbols = [];
  bool _isParsing = false;
  String? _fileName;
  String? _error;

  Future<void> _pickAndParseCSV() async {
    setState(() {
      _isParsing = true;
      _error = null;
      _symbols = [];
      _fileName = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        allowMultiple: false,
        withData: true, 
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isParsing = false);
        return;
      }

      final file = result.files.first;
      _fileName = file.name;
      
      String csvContent = '';
      
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        csvContent = String.fromCharCodes(file.bytes!);
      } 
      else if (!kIsWeb && file.path != null) {
        csvContent = await File(file.path!).readAsString();
      }

      if (csvContent.isEmpty) {
        throw Exception('Could not read file content');
      }

      debugPrint('CSV Content: ${csvContent.substring(0, csvContent.length.clamp(0, 200))}...');

      // Parse CSV - try with auto-detection of line endings
      List<List<dynamic>> rows;
      try {
        rows = const CsvToListConverter(eol: '\n').convert(csvContent);
        if (rows.length <= 1) {
          // Try with Windows-style line endings
          rows = const CsvToListConverter(eol: '\r\n').convert(csvContent);
        }
      } catch (e) {
        // If CSV parsing fails, try simple line-by-line parsing
        debugPrint('CSV parser failed, trying line-by-line: $e');
        rows = csvContent
            .split(RegExp(r'\r?\n'))
            .where((line) => line.trim().isNotEmpty)
            .map((line) => [line.split(',')[0].trim()])
            .toList();
      }
      
      debugPrint('Parsed ${rows.length} rows');

      // Extract symbols from first column
      Set<String> symbols = {};
      for (int i = 0; i < rows.length; i++) {
        if (rows[i].isNotEmpty) {
          String value = rows[i][0].toString().trim().toUpperCase();
          debugPrint('Row $i: $value');
          // Skip header row if it looks like a header
          if (i == 0 && (value == 'SYMBOL' || value == 'TICKER' || value == 'STOCK')) {
            continue;
          }
          // Basic validation: alphanumeric with possible dots (for .NS, .BO etc.)
          if (value.isNotEmpty && RegExp(r'^[A-Z0-9.]+$').hasMatch(value)) {
            symbols.add(value);
          }
        }
      }

      debugPrint('Found ${symbols.length} symbols: $symbols');

      setState(() {
        _symbols = symbols.toList();
        _isParsing = false;
      });

    } catch (e) {
      debugPrint('CSV Parse Error: $e');
      setState(() {
        _error = 'Error parsing CSV: ${e.toString()}';
        _isParsing = false;
      });
    }
  }

  String _getEstimatedTime(int count) {
    // 3-4 seconds per symbol for rate limiting
    int seconds = count * 4;
    if (seconds < 60) {
      return '~$seconds seconds';
    } else {
      int minutes = (seconds / 60).ceil();
      return '~$minutes minutes';
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          '⚠️ Bulk Analysis',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to analyze ${_symbols.length} symbols.',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: AppTheme.accentColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Estimated time: ${_getEstimatedTime(_symbols.length)}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.speed, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rate limited to avoid API limits',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will:',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Analyze each symbol with AI\n'
              '• Add matching symbols to watchlist\n'
              '• Auto-trade high confidence signals',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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
              _startAnalysis();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _startAnalysis() {
    final autoTrading = context.read<AutoTradingProvider>();
    final ai = context.read<AIProvider>();
    final portfolio = context.read<PortfolioProvider>();
    final watchlist = context.read<WatchlistProvider>();

    autoTrading.analyzeBulkSymbols(
      symbols: _symbols,
      ai: ai,
      portfolio: portfolio,
      watchlist: watchlist,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Analysis'),
      ),
      body: Consumer<AutoTradingProvider>(
        builder: (context, autoTrading, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.upload_file, color: AppTheme.primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Import CSV',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Upload a CSV file containing stock symbols.\n'
                        'The first column should contain the ticker symbols.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isParsing || autoTrading.isRunning ? null : _pickAndParseCSV,
                        icon: _isParsing 
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.folder_open),
                        label: Text(_isParsing ? 'Parsing...' : 'Select CSV File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Parsed Symbols
                if (_symbols.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '📊 ${_symbols.length} Symbols Found',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_fileName != null)
                              Text(
                                _fileName!,
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _symbols.take(20).map((symbol) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              symbol,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                            ),
                          )).toList(),
                        ),
                        if (_symbols.length > 20)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '+${_symbols.length - 20} more...',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: autoTrading.isRunning ? null : _showConfirmationDialog,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Analysis'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Progress Section
                if (autoTrading.isRunning) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '🔄 Analyzing...',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${(autoTrading.progress * 100).toInt()}%',
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: autoTrading.progress,
                          backgroundColor: AppTheme.backgroundColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: autoTrading.cancelAnalysis,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Logs Section
                if (autoTrading.logs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    height: 300,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '📋 Analysis Log',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _showFullscreenLogs(context, autoTrading.logs),
                                  icon: const Icon(Icons.fullscreen, size: 20),
                                  tooltip: 'Fullscreen',
                                  color: AppTheme.textSecondary,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: autoTrading.clearLogs,
                                  child: const Text(
                                    'Clear',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            reverse: false,
                            itemCount: autoTrading.logs.length,
                            itemBuilder: (context, index) {
                              // Show from end for latest first
                              final log = autoTrading.logs[autoTrading.logs.length - 1 - index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  log,
                                  style: TextStyle(
                                    color: _getLogColor(log),
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('✓') || log.contains('BUY') || log.contains('Bullish')) {
      return Colors.green;
    }
    if (log.contains('❌') || log.contains('Error') || log.contains('failed')) {
      return Colors.red;
    }
    if (log.contains('═') || log.contains('╔') || log.contains('║') || log.contains('╚')) {
      return AppTheme.accentColor;
    }
    if (log.contains('📊') || log.contains('🤖') || log.contains('💰')) {
      return AppTheme.primaryColor;
    }
    if (log.contains('PSAR') || log.contains('RSI') || log.contains('MACD') || log.contains('SMA') || log.contains('Bollinger')) {
      return AppTheme.textPrimary;
    }
    return AppTheme.textSecondary;
  }

  void _showFullscreenLogs(BuildContext context, List<String> logs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Bulk Analysis Logs'),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: SelectableText(
                  log,
                  style: TextStyle(
                    color: _getLogColor(log),
                    fontFamily: 'monospace',
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
}
