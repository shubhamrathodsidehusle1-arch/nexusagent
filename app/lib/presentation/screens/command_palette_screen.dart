import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CommandPaletteScreen extends StatefulWidget {
  const CommandPaletteScreen({super.key});

  @override
  State<CommandPaletteScreen> createState() => _CommandPaletteScreenState();
}

class _CommandPaletteScreenState extends State<CommandPaletteScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  final List<Map<String, dynamic>> _commands = [
    {'id': 'new_agent', 'title': 'Create New Agent', 'icon': '🤖', 'category': 'Agents'},
    {'id': 'new_channel', 'title': 'Connect Channel', 'icon': '💬', 'category': 'Channels'},
    {'id': 'new_workflow', 'title': 'Create Workflow', 'icon': '⚡', 'category': 'Workflows'},
    {'id': 'new_memory', 'title': 'Add Memory', 'icon': '🧠', 'category': 'Memory'},
    {'id': 'run_agent', 'title': 'Run Agent', 'icon': '▶️', 'category': 'Actions'},
    {'id': 'stop_agent', 'title': 'Stop Agent', 'icon': '⏹️', 'category': 'Actions'},
    {'id': 'view_logs', 'title': 'View Logs', 'icon': '📋', 'category': 'Debug'},
    {'id': 'settings', 'title': 'Open Settings', 'icon': '⚙️', 'category': 'System'},
    {'id': 'billing', 'title': 'View Billing', 'icon': '💳', 'category': 'Account'},
    {'id': 'help', 'title': 'Get Help', 'icon': '❓', 'category': 'System'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _commands
        : _commands.where((c) => c['title'].toString().toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Actions')),
      body: Column(
        children: [
          // Search
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search commands...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),

          // Commands
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final cmd = filtered[index];
                return _buildCommandItem(cmd);
              },
            ),
          ),

          // Quick Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.surfaceLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat('Active Agents', '3'),
                _buildQuickStat('Messages Today', '47'),
                _buildQuickStat('Uptime', '99.9%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandItem(Map<String, dynamic> cmd) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Text(cmd['icon'], style: const TextStyle(fontSize: 20)),
        title: Text(cmd['title']),
        subtitle: Text(cmd['category'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () {},
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}
