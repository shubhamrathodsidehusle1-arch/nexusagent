import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFactor = false;
  bool _sessionTimeout = true;
  int _timeoutMinutes = 30;
  bool _ipWhitelist = false;
  bool _apiKeyRestriction = true;
  bool _webhookSignature = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        children: [
          // Security Score
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.success, AppColors.primary]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Center(child: Text('85%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Security Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Your account is well protected', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Password
          _buildSectionHeader('Authentication'),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            subtitle: const Text('Last changed 30 days ago'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          SwitchListTile(
            secondary: const Icon(Icons.security),
            title: const Text('Two-Factor Authentication'),
            subtitle: const Text('Add an extra layer of security'),
            value: _twoFactor,
            onChanged: (value) => setState(() => _twoFactor = value),
          ),

          // Sessions
          _buildSectionHeader('Sessions'),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Active Sessions'),
            subtitle: const Text('3 devices'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          SwitchListTile(
            secondary: const Icon(Icons.timer),
            title: const Text('Auto Session Timeout'),
            subtitle: Text('Logout after $_timeoutMinutes minutes of inactivity'),
            value: _sessionTimeout,
            onChanged: (value) => setState(() => _sessionTimeout = value),
          ),

          // API Security
          _buildSectionHeader('API Security'),
          SwitchListTile(
            secondary: const Icon(Icons.vpn_key),
            title: const Text('Restrict API Keys'),
            subtitle: const Text('Limit key usage to specific IPs'),
            value: _apiKeyRestriction,
            onChanged: (value) => setState(() => _apiKeyRestriction = value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.webhook),
            title: const Text('Webhook Signatures'),
            subtitle: const Text('Verify webhook authenticity'),
            value: _webhookSignature,
            onChanged: (value) => setState(() => _webhookSignature = value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.filter_alt),
            title: const Text('IP Whitelist'),
            subtitle: const Text('Restrict access to specific IPs'),
            value: _ipWhitelist,
            onChanged: (value) => setState(() => _ipWhitelist = value),
          ),

          // Execution Security
          _buildSectionHeader('Execution Security'),
          ListTile(
            leading: const Icon(Icons.terminal, color: AppColors.warning),
            title: const Text('Sandbox Settings'),
            subtitle: const Text('Configure agent execution environment'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSandboxSettings(context),
          ),
          ListTile(
            leading: const Icon(Icons.block, color: AppColors.error),
            title: const Text('Blocked Commands'),
            subtitle: const Text('Commands agents cannot execute'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          // Audit
          _buildSectionHeader('Audit & Compliance'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Audit Log'),
            subtitle: const Text('View security events'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Data'),
            subtitle: const Text('Download your data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text('Delete Account', style: TextStyle(color: AppColors.error)),
            subtitle: const Text('Permanently delete your account'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.error),
            onTap: () => _showDeleteConfirmation(context),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
    );
  }

  void _showSandboxSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sandbox Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Network Isolation'),
              subtitle: const Text('Block internet access in sandbox'),
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text('Resource Limits'),
              subtitle: const Text('Limit CPU and memory usage'),
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text('File System Isolation'),
              subtitle: const Text('Restrict file system access'),
              value: true,
              onChanged: (v) {},
            ),
            ListTile(
              title: const Text('Max Execution Time'),
              subtitle: const Text('30 seconds'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This action cannot be undone. All your data will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
