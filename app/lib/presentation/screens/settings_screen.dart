import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
                  child: Center(
                    child: Text(user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.email ?? 'User', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Starter Plan', style: TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Account Section
          _buildSection('Account', [
            _buildMenuItem(Icons.person, 'Profile', 'Manage your account'),
            _buildMenuItem(Icons.lock, 'Security', 'Password, 2FA'),
            _buildMenuItem(Icons.receipt_long, 'Billing', 'Plan & payments'),
          ]),
          const SizedBox(height: 16),
          
          // Preferences Section
          _buildSection('Preferences', [
            _buildMenuItem(Icons.notifications, 'Notifications', 'Push & email'),
            _buildMenuItem(Icons.palette, 'Appearance', 'Theme & display'),
            _buildMenuItem(Icons.language, 'Language', 'English'),
            _buildMenuItem(Icons.timer, 'Timeouts', 'Agent execution'),
          ]),
          const SizedBox(height: 16),
          
          // Integrations Section
          _buildSection('Integrations', [
            _buildMenuItem(Icons.api, 'API Keys', 'Manage API access'),
            _buildMenuItem(Icons.webhook, 'Webhooks', 'Configure webhooks'),
            _buildMenuItem(Icons.link, 'Connected Apps', 'Third-party'),
          ]),
          const SizedBox(height: 16),
          
          // Support Section
          _buildSection('Support', [
            _buildMenuItem(Icons.help_outline, 'Help Center', 'Documentation'),
            _buildMenuItem(Icons.feedback, 'Feedback', 'Send feedback'),
            _buildMenuItem(Icons.info_outline, 'About', 'Version 1.0.0'),
          ]),
          const SizedBox(height: 24),
          
          // Sign Out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
