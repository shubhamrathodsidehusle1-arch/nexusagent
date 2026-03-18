import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/agent_model.dart';

class AgentsScreen extends StatelessWidget {
  const AgentsScreen({super.key});

  // Mock agents
  final List<Agent> _agents = [
    Agent(
      id: '1', orgId: 'org1', name: 'AI Assistant',
      description: 'General purpose assistant for daily tasks',
      status: 'online', config: AgentConfig(),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      lastRunAt: DateTime.now().subtract(const Duration(hours: 2)),
      runCount: 156,
    ),
    Agent(
      id: '2', orgId: 'org1', name: 'Code Expert',
      description: 'Helps with programming and debugging',
      status: 'running', config: AgentConfig(model: 'gpt-4'),
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      lastRunAt: DateTime.now().subtract(const Duration(minutes: 30)),
      runCount: 89,
    ),
    Agent(
      id: '3', orgId: 'org1', name: 'Content Writer',
      description: 'Creates articles and marketing content',
      status: 'online', config: AgentConfig(),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      lastRunAt: DateTime.now().subtract(const Duration(hours: 6)),
      runCount: 45,
    ),
    Agent(
      id: '4', orgId: 'org1', name: 'Data Analyst',
      description: 'Analyzes data and generates insights',
      status: 'offline', config: AgentConfig(),
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      lastRunAt: DateTime.now().subtract(const Duration(days: 2)),
      runCount: 23,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Agents'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _agents.length,
        itemBuilder: (context, index) {
          return _buildAgentCard(context, _agents[index]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAgentSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Agent'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildAgentCard(BuildContext context, Agent agent) {
    Color statusColor;
    String statusIcon;
    
    switch (agent.status) {
      case 'online':
        statusColor = AppColors.online;
        statusIcon = '🟢';
        break;
      case 'running':
        statusColor = AppColors.running;
        statusIcon = '🟡';
        break;
      case 'error':
        statusColor = AppColors.error;
        statusIcon = '🔴';
        break;
      default:
        statusColor = AppColors.offline;
        statusIcon = '⚫';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(agent.name.substring(0, 1).toUpperCase(), 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(agent.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(statusIcon, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Text(agent.description, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'run', child: Text('Run')),
                  const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip('⚡', '${agent.runCount} runs'),
              const SizedBox(width: 8),
              _buildStatChip('⏱️', _formatLastRun(agent.lastRunAt)),
              const SizedBox(width: 8),
              _buildStatChip('🧠', agent.config.model),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Run'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Chat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  String _formatLastRun(DateTime? date) {
    if (date == null) return 'Never';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showCreateAgentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text('Create New Agent', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              const Text('Choose a template:', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ...AgentTemplates.templates.map((template) => _buildTemplateOption(context, template)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateOption(BuildContext context, Map<String, dynamic> template) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Text(template['icon'], style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(template['description'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
