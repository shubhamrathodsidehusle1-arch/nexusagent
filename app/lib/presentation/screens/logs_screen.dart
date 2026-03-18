import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> _logs = [
    {'time': '10:24:32', 'level': 'info', 'source': 'Agent', 'message': 'Agent "Code Expert" started execution'},
    {'time': '10:24:35', 'level': 'info', 'source': 'Memory', 'message': 'Loaded 5 context entries'},
    {'time': '10:24:40', 'level': 'info', 'source': 'GPT-4', 'message': 'Processing request (45 tokens)'},
    {'time': '10:24:45', 'level': 'warning', 'source': 'Rate Limit', 'message': 'Approaching rate limit (90%)'},
    {'time': '10:24:50', 'level': 'error', 'source': 'Agent', 'message': 'Execution timeout after 30s'},
    {'time': '10:25:00', 'level': 'info', 'source': 'Channel', 'message': 'Telegram message sent'},
    {'time': '10:25:15', 'level': 'info', 'source': 'Webhook', 'message': 'POST /hook/agent - 200 OK'},
    {'time': '10:25:30', 'level': 'debug', 'source': 'Cache', 'message': 'Redis hit for context'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Info'),
            Tab(text: 'Errors'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: [
                _buildFilterChip('All Sources', true),
                _buildFilterChip('Agent', false),
                _buildFilterChip('Channel', false),
                _buildFilterChip('API', false),
                _buildFilterChip('System', false),
              ],
            ),
          ),

          // Logs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return _buildLogItem(log);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) {},
        selectedColor: AppColors.primary,
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    Color levelColor;
    IconData levelIcon;
    
    switch (log['level']) {
      case 'error':
        levelColor = AppColors.error;
        levelIcon = Icons.error;
        break;
      case 'warning':
        levelColor = AppColors.warning;
        levelIcon = Icons.warning;
        break;
      case 'debug':
        levelColor = AppColors.textMuted;
        levelIcon = Icons.bug_report;
        break;
      default:
        levelColor = AppColors.info;
        levelIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: log['level'] == 'error' ? Border.all(color: AppColors.error.withOpacity(0.3)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            child: Text(
              log['time'],
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textMuted),
            ),
          ),
          Icon(levelIcon, size: 16, color: levelColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log['source'],
                        style: const TextStyle(fontSize: 10, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log['message'],
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
