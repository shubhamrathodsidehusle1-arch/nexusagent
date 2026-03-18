import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SubAgentsScreen extends StatelessWidget {
  const SubAgentsScreen({super.key});

  final List<Map<String, dynamic>> _subAgents = [
    {'id': '1', 'name': 'Research Sub-Agent', 'parent': 'AI Assistant', 'status': 'running', 'tasks': 12, 'specialty': 'Web Research'},
    {'id': '2', 'name': 'Code Reviewer', 'parent': 'Code Expert', 'status': 'idle', 'tasks': 45, 'specialty': 'Code Analysis'},
    {'id': '3', 'name': 'Data Collector', 'parent': 'Data Analyst', 'status': 'running', 'tasks': 8, 'specialty': 'Data Gathering'},
    {'id': '4', 'name': 'Content Editor', 'parent': 'Content Writer', 'status': 'idle', 'tasks': 23, 'specialty': 'Editing'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sub-Agents'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.2), AppColors.secondary.withOpacity(0.2)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sub-agents are specialized AI agents that work under main agents to handle specific tasks in parallel.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats
          Row(
            children: [
              _buildStatCard('Total', '${_subAgents.length}', AppColors.primary),
              _buildStatCard('Running', '${_subAgents.where((a) => a['status'] == 'running').length}', AppColors.success),
              _buildStatCard('Idle', '${_subAgents.where((a) => a['status'] == 'idle').length}', AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 24),

          // Sub-agents
          Text('Active Sub-Agents', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ..._subAgents.map((agent) => _buildSubAgentCard(context, agent)),

          const SizedBox(height: 24),

          // Orchestration Settings
          Text('Orchestration Settings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.parallel_tasks,
            title: 'Parallel Execution',
            subtitle: 'Run sub-agents simultaneously',
            trailing: Switch(value: true, onChanged: (_) {}),
          ),
          _buildSettingTile(
            icon: Icons.merge,
            title: 'Auto-merge Results',
            subtitle: 'Combine outputs from sub-agents',
            trailing: Switch(value: true, onChanged: (_) {}),
          ),
          _buildSettingTile(
            icon: Icons.replay,
            title: 'Retry Failed Tasks',
            subtitle: 'Automatically retry failed subtasks',
            trailing: Switch(value: false, onChanged: (_) {}),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSubAgent(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Sub-Agent'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubAgentCard(BuildContext context, Map<String, dynamic> agent) {
    final isRunning = agent['status'] == 'running';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: isRunning ? AppColors.success.withOpacity(0.2) : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isRunning ? Icons.hourglass_bottom : Icons.smart_toy,
                  color: isRunning ? AppColors.success : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(agent['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text(agent['parent'], style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 8),
                        Text(agent['specialty'], style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isRunning ? AppColors.success.withOpacity(0.2) : AppColors.textMuted.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isRunning ? 'Running' : 'Idle',
                  style: TextStyle(fontSize: 11, color: isRunning ? AppColors.success : AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _buildMetric('Tasks', '${agent['tasks']}'),
              const Spacer(),
              _buildMetric('Success Rate', '94%'),
              const Spacer(),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.play_arrow, size: 20), onPressed: () {}, tooltip: 'Start'),
                  IconButton(icon: const Icon(Icons.stop, size: 20), onPressed: () {}, tooltip: 'Stop'),
                  IconButton(icon: const Icon(Icons.more_vert, size: 20), onPressed: () {}),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, required String subtitle, required Widget trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: trailing,
      ),
    );
  }

  void _showCreateSubAgent(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Sub-Agent', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Parent Agent'),
                items: const [
                  DropdownMenuItem(value: 'ai_assistant', child: Text('AI Assistant')),
                  DropdownMenuItem(value: 'code_expert', child: Text('Code Expert')),
                  DropdownMenuItem(value: 'data_analyst', child: Text('Data Analyst')),
                ],
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Specialty'),
                items: const [
                  DropdownMenuItem(value: 'research', child: Text('Web Research')),
                  DropdownMenuItem(value: 'analysis', child: Text('Data Analysis')),
                  DropdownMenuItem(value: 'coding', child: Text('Code Generation')),
                  DropdownMenuItem(value: 'writing', child: Text('Content Writing')),
                ],
                onChanged: (value) {},
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Create Sub-Agent'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
