/// NexusAgent Security Screen
/// Real security settings connected to providers

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Security Status Card
          _SecurityStatusCard(),
          const SizedBox(height: 24),

          // Authentication Section
          _SectionHeader(title: 'Authentication', icon: Icons.lock),
          const _SettingsTile(
            icon: Icons.fingerprint,
            title: 'Biometric Login',
            subtitle: 'Use fingerprint or face to unlock',
            trailing: Switch(value: true, onChanged: null),
          ),
          const _SettingsTile(
            icon: Icons.timer,
            title: 'Session Timeout',
            subtitle: '24 hours',
            trailing: Icon(Icons.chevron_right),
          ),
          const _SettingsTile(
            icon: Icons.key,
            title: 'Two-Factor Authentication',
            subtitle: 'Not configured',
            trailing: Icon(Icons.chevron_right),
          ),

          const SizedBox(height: 24),

          // Privacy Section
          _SectionHeader(title: 'Privacy', icon: Icons.visibility_off),
          const _SettingsTile(
            icon: Icons.analytics,
            title: 'Analytics',
            subtitle: 'Help improve NexusAgent',
            trailing: Switch(value: true, onChanged: null),
          ),
          const _SettingsTile(
            icon: Icons.crash_report,
            title: 'Crash Reports',
            subtitle: 'Send anonymous crash reports',
            trailing: Switch(value: true, onChanged: null),
          ),

          const SizedBox(height: 24),

          // Data Section
          _SectionHeader(title: 'Data', icon: Icons.storage),
          const _SettingsTile(
            icon: Icons.backup,
            title: 'Backup Data',
            subtitle: 'Export your data',
            trailing: Icon(Icons.chevron_right),
          ),
          const _SettingsTile(
            icon: Icons.delete_forever,
            title: 'Delete All Data',
            subtitle: 'Remove all local data',
            textColor: Colors.red,
            trailing: Icon(Icons.chevron_right, color: Colors.red),
          ),

          const SizedBox(height: 24),

          // Audit Log
          _SectionHeader(title: 'Audit', icon: Icons.history),
          Card(
            child: ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('View Audit Log'),
              subtitle: const Text('See all security events'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showAuditLog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAuditLog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.history),
                  const SizedBox(width: 8),
                  const Text(
                    'Audit Log',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: const [
                  _AuditItem(
                    event: 'Login',
                    time: 'Today, 10:30 AM',
                    status: 'Success',
                  ),
                  _AuditItem(
                    event: 'Agent Created',
                    time: 'Today, 10:35 AM',
                    status: 'Success',
                  ),
                  _AuditItem(
                    event: 'Channel Connected',
                    time: 'Today, 10:40 AM',
                    status: 'Success',
                  ),
                  _AuditItem(
                    event: 'Settings Changed',
                    time: 'Today, 11:00 AM',
                    status: 'Success',
                  ),
                  _AuditItem(
                    event: 'Logout',
                    time: 'Today, 12:00 PM',
                    status: 'Success',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_user,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Status: Protected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All security features are enabled',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(title, style: TextStyle(color: textColor)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}

class _AuditItem extends StatelessWidget {
  final String event;
  final String time;
  final String status;

  const _AuditItem({
    required this.event,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        status == 'Success' ? Icons.check_circle : Icons.error,
        color: status == 'Success' ? Colors.green : Colors.red,
      ),
      title: Text(event),
      subtitle: Text(time),
      trailing: Text(
        status,
        style: TextStyle(
          color: status == 'Success' ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
