import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  final List<Map<String, dynamic>> _schedules = [
    {'id': '1', 'name': 'Morning Report', 'agent': 'AI Assistant', 'schedule': 'Daily 8:00 AM', 'status': 'active', 'lastRun': 'Today 8:00 AM', 'nextRun': 'Tomorrow 8:00 AM'},
    {'id': '2', 'name': 'Weekly Digest', 'agent': 'Content Writer', 'schedule': 'Weekly Monday 9:00 AM', 'status': 'active', 'lastRun': 'Mon, Mar 10', 'nextRun': 'Mon, Mar 24'},
    {'id': '3', 'name': 'Data Backup', 'agent': 'Data Analyst', 'schedule': 'Daily 11:00 PM', 'status': 'paused', 'lastRun': 'Yesterday 11:00 PM', 'nextRun': 'Paused'},
    {'id': '4', 'name': 'Health Check', 'agent': 'Monitor Agent', 'schedule': 'Every 15 minutes', 'status': 'active', 'lastRun': '5 min ago', 'nextRun': '10 min'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduler'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick Stats
          Row(
            children: [
              _buildStatCard('Active', '4', AppColors.success),
              _buildStatCard('Paused', '1', AppColors.warning),
              _buildStatCard('Total Runs', '247', AppColors.primary),
            ],
          ),
          const SizedBox(height: 24),

          // Upcoming Runs
          Text('Upcoming Runs', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildUpcomingRun('In 5 min', 'Health Check', 'Monitor Agent'),
          _buildUpcomingRun('In 2 hours', 'Afternoon Sync', 'AI Assistant'),
          _buildUpcomingRun('Tomorrow 8AM', 'Morning Report', 'AI Assistant'),

          const SizedBox(height: 24),

          // Schedules
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Schedules', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => _showCreateSchedule(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._schedules.map((schedule) => _buildScheduleCard(context, schedule)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSchedule(context),
        icon: const Icon(Icons.add),
        label: const Text('New Schedule'),
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

  Widget _buildUpcomingRun(String time, String name, String agent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(time, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(agent, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.schedule, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, Map<String, dynamic> schedule) {
    final isActive = schedule['status'] == 'active';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? null : Border.all(color: AppColors.textMuted.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(schedule['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
              Switch(
                value: isActive,
                onChanged: (value) {},
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.smart_toy, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(schedule['agent'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(width: 16),
              const Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(schedule['schedule'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Last Run', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(schedule['lastRun'], style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Next Run', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(schedule['nextRun'], style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'run', child: Text('Run Now')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'logs', child: Text('View Logs')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateSchedule(BuildContext context) {
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
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              const Text('Create Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(decoration: const InputDecoration(labelText: 'Schedule Name', hintText: 'e.g., Morning Report')),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: 'Agent'),
                items: const [
                  DropdownMenuItem(value: 'ai_assistant', child: Text('AI Assistant')),
                  DropdownMenuItem(value: 'code_expert', child: Text('Code Expert')),
                  DropdownMenuItem(value: 'data_analyst', child: Text('Data Analyst')),
                ],
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              const Text('Frequency', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(label: const Text('Once'), selected: false, onSelected: (_) {}),
                  ChoiceChip(label: const Text('Daily'), selected: true, onSelected: (_) {}),
                  ChoiceChip(label: const Text('Weekly'), selected: false, onSelected: (_) {}),
                  ChoiceChip(label: const Text('Interval'), selected: false, onSelected: (_) {}),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Time', hintText: '8:00 AM'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Create Schedule'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
