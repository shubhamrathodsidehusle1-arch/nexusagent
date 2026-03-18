import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class ApiKeysScreen extends StatefulWidget {
  const ApiKeysScreen({super.key});

  @override
  State<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends State<ApiKeysScreen> {
  final List<Map<String, dynamic>> _apiKeys = [
    {'id': '1', 'name': 'Production Key', 'key': 'nx_live_xxxx...xxxx1234', 'created': '2024-01-15', 'lastUsed': '2 hours ago', 'expires': null},
    {'id': '2', 'name': 'Development Key', 'key': 'nx_test_xxxx...xxxx5678', 'created': '2024-01-10', 'lastUsed': '5 days ago', 'expires': '2024-06-01'},
    {'id': '3', 'name': 'CI/CD Pipeline', 'key': 'nx_live_xxxx...xxxxabcd', 'created': '2024-01-08', 'lastUsed': null, 'expires': null},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Keys'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'API keys grant full access to your NexusAgent account. Keep them secure!',
                    style: TextStyle(fontSize: 13, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Keys List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your API Keys', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => _showCreateKeyDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Key'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          ..._apiKeys.map((key) => _buildApiKeyCard(context, key)),
          
          const SizedBox(height: 24),
          
          // Usage Stats
          Text('Usage This Month', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildUsageRow('API Requests', '12,547'),
                const Divider(height: 24),
                _buildUsageRow('Tokens Used', '2.4M'),
                const Divider(height: 24),
                _buildUsageRow('Avg Response Time', '145ms'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Webhooks
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Webhooks', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => _showCreateWebhookDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Webhook'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildWebhookRow('Agent Completed', 'https://api.example.com/hook/agent', true),
                const Divider(height: 24),
                _buildWebhookRow('Message Received', 'https://api.example.com/hook/msg', true),
                const Divider(height: 24),
                _buildWebhookRow('Error Alert', 'https://api.example.com/hook/error', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyCard(BuildContext context, Map<String, dynamic> key) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(key['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'copy', child: Text('Copy Key')),
                  const PopupMenuItem(value: 'regenerate', child: Text('Regenerate')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(4)),
                child: SelectableText(
                  key['key'],
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: key['key']));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                tooltip: 'Copy',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildKeyInfo('Created', key['created']),
              const SizedBox(width: 16),
              _buildKeyInfo('Last Used', key['lastUsed'] ?? 'Never'),
              if (key['expires'] != null) ...[
                const SizedBox(width: 16),
                _buildKeyInfo('Expires', key['expires'], isWarning: true),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyInfo(String label, String value, {bool isWarning = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text(
          value,
          style: TextStyle(fontSize: 12, color: isWarning ? AppColors.warning : AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildUsageRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildWebhookRow(String event, String url, bool enabled) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? AppColors.success : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(url, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Switch(
          value: enabled,
          onChanged: (value) {},
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  void _showCreateKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g., Production Key'),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Expires (optional)',
                hintText: 'YYYY-MM-DD',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Create')),
        ],
      ),
    );
  }

  void _showCreateWebhookDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Webhook'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'URL', hintText: 'https://...'),
            ),
            const SizedBox(height: 16),
            const Text('Events', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(label: const Text('agent.completed'), selected: true, onSelected: (_) {}),
                FilterChip(label: const Text('message.received'), selected: true, onSelected: (_) {}),
                FilterChip(label: const Text('error'), selected: false, onSelected: (_) {}),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Add')),
        ],
      ),
    );
  }
}
