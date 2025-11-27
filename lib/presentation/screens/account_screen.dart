import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/portfolio_provider.dart';
import '../../logic/providers/ai_provider.dart';
import '../../data/services/openrouter_service.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_button.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AIProvider>(context);
    final portfolioProvider = Provider.of<PortfolioProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(portfolioProvider),
            const SizedBox(height: 24),
            const Text(
              'AI Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildApiKeySection(context, aiProvider),
            const SizedBox(height: 16),
            _buildModelSelector(context, aiProvider),
            const SizedBox(height: 24),
            const Text(
              'Data Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Clear AI Logs',
              color: AppTheme.surfaceColor,
              textColor: AppTheme.textPrimary,
              onPressed: () {
                aiProvider.clearLogs();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI Logs cleared')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(PortfolioProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withValues(alpha: 0.2), AppTheme.surfaceColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Funds',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyHelper.formatInr(provider.balance),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeySection(BuildContext context, AIProvider provider) {
    final TextEditingController controller = TextEditingController(text: provider.apiKey);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OpenRouter API Key',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Required for AI features. Stored securely on your device.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'sk-or-v1-...',
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Save Key',
              onPressed: () {
                provider.setApiKey(controller.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API Key saved securely')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector(BuildContext context, AIProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Model',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select which AI model to use for analysis. Free models have usage limits.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showModelPicker(context, provider),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _getModelName(provider.selectedModel),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getModelName(String modelId) {
    final model = OpenRouterService.popularModels.firstWhere(
      (m) => m['id'] == modelId,
      orElse: () => {'id': modelId, 'name': modelId},
    );
    return model['name']!;
  }

  void _showModelPicker(BuildContext context, AIProvider provider) {
    final TextEditingController searchController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final models = OpenRouterService.popularModels.where((model) {
            final query = searchController.text.toLowerCase();
            return model['name']!.toLowerCase().contains(query) ||
                   model['id']!.toLowerCase().contains(query);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Select AI Model',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Search models...',
                    hintStyle: TextStyle(color: AppTheme.textSecondary),
                    prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: models.length,
                    itemBuilder: (context, index) {
                      final model = models[index];
                      final isSelected = model['id'] == provider.selectedModel;
                      
                      return ListTile(
                        title: Text(
                          model['name']!,
                          style: TextStyle(
                            color: isSelected ? AppTheme.accentColor : AppTheme.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          model['id']!,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        trailing: isSelected 
                          ? const Icon(Icons.check_circle, color: AppTheme.accentColor)
                          : null,
                        onTap: () {
                          provider.setModel(model['id']!);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Model changed to ${model['name']}')),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
