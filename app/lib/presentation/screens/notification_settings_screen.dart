import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _agentCompleted = true;
  bool _agentError = true;
  bool _newMessage = true;
  bool _mentions = true;
  bool _weeklyDigest = true;
  bool _marketing = false;
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '08:00';
  bool _quietHoursEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          // Push Notifications
          _buildSectionHeader('Push Notifications'),
          SwitchListTile(
            value: _pushEnabled,
            onChanged: (value) => setState(() => _pushEnabled = value),
            title: const Text('Enable Push Notifications'),
            subtitle: const Text('Receive real-time alerts on your device'),
          ),
          
          // Email Notifications
          _buildSectionHeader('Email Notifications'),
          SwitchListTile(
            value: _emailEnabled,
            onChanged: (value) => setState(() => _emailEnabled = value),
            title: const Text('Enable Email Notifications'),
            subtitle: const Text('Receive updates via email'),
          ),
          
          // Agent Events
          _buildSectionHeader('Agent Events'),
          SwitchListTile(
            value: _agentCompleted,
            onChanged: (value) => setState(() => _agentCompleted = value),
            title: const Text('Agent Completed'),
            subtitle: const Text('When an agent finishes running'),
            secondary: const Icon(Icons.check_circle, color: AppColors.success),
          ),
          SwitchListTile(
            value: _agentError,
            onChanged: (value) => setState(() => _agentError = value),
            title: const Text('Agent Errors'),
            subtitle: const Text('When an agent encounters an error'),
            secondary: const Icon(Icons.error, color: AppColors.error),
          ),
          
          // Messages
          _buildSectionHeader('Messages'),
          SwitchListTile(
            value: _newMessage,
            onChanged: (value) => setState(() => _newMessage = value),
            title: const Text('New Messages'),
            subtitle: const Text('When you receive a new message'),
            secondary: const Icon(Icons.message, color: AppColors.info),
          ),
          SwitchListTile(
            value: _mentions,
            onChanged: (value) => setState(() => _mentions = value),
            title: const Text('Mentions'),
            subtitle: const Text('When someone mentions you'),
            secondary: const Icon(Icons.alternate_email, color: AppColors.accent),
          ),
          
          // Digests
          _buildSectionHeader('Digests'),
          SwitchListTile(
            value: _weeklyDigest,
            onChanged: (value) => setState(() => _weeklyDigest = value),
            title: const Text('Weekly Digest'),
            subtitle: const Text('Summary of your agent activity'),
            secondary: const Icon(Icons.calendar_view_week, color: AppColors.primary),
          ),
          SwitchListTile(
            value: _marketing,
            onChanged: (value) => setState(() => _marketing = value),
            title: const Text('Product Updates'),
            subtitle: const Text('News and feature announcements'),
            secondary: const Icon(Icons.campaign, color: AppColors.textMuted),
          ),
          
          // Quiet Hours
          _buildSectionHeader('Quiet Hours'),
          SwitchListTile(
            value: _quietHoursEnabled,
            onChanged: (value) => setState(() => _quietHoursEnabled = value),
            title: const Text('Enable Quiet Hours'),
            subtitle: const Text('Mute notifications during specific hours'),
          ),
          if (_quietHoursEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTimePicker('Start', _quietHoursStart, (value) => setState(() => _quietHoursStart = value)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker('End', _quietHoursEnd, (value) => setState(() => _quietHoursEnd = value)),
                  ),
                ],
              ),
            ),
          
          // Sound & Vibration
          _buildSectionHeader('Sound & Vibration'),
          ListTile(
            title: const Text('Notification Sound'),
            subtitle: const Text('Default'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          SwitchListTile(
            value: true,
            onChanged: (value) {},
            title: const Text('Vibration'),
            subtitle: const Text('Vibrate for notifications'),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, String time, Function(String) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: int.parse(time.split(':')[0]), minute: int.parse(time.split(':')[1])),
        );
        if (picked != null) {
          onChanged('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
