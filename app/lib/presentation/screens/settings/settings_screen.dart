/// NexusAgent Settings Screen - Connected
/// Real settings with providers

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, _) {
          return ListView(
            children: [
              // Account section
              _SectionHeader(title: 'Account'),
              _SettingsTile(
                icon: Icons.person,
                title: 'Profile',
                subtitle: 'Manage your account',
                onTap: () => _showProfileDialog(context),
              ),
              _SettingsTile(
                icon: Icons.lock,
                title: 'Security',
                subtitle: 'Password, 2FA',
                onTap: () {},
              ),

              // Appearance section
              _SectionHeader(title: 'Appearance'),
              _SettingsTile(
                icon: Icons.dark_mode,
                title: 'Theme',
                subtitle: provider.themeMode.name,
                onTap: () => _showThemeDialog(context, provider),
              ),
              _SettingsTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: provider.language,
                onTap: () => _showLanguageDialog(context, provider),
              ),

              // Notifications section
              _SectionHeader(title: 'Notifications'),
              _SwitchTile(
                icon: Icons.notifications,
                title: 'Push Notifications',
                value: provider.notificationsEnabled,
                onChanged: (v) => provider.setNotifications(v),
              ),
              _SwitchTile(
                icon: Icons.volume_up,
                title: 'Sound',
                value: provider.soundEnabled,
                onChanged: (v) => provider.setSound(v),
              ),
              _SwitchTile(
                icon: Icons.vibration,
                title: 'Vibration',
                value: provider.vibrationEnabled,
                onChanged: (v) => provider.setVibration(v),
              ),

              // Connection section
              _SectionHeader(title: 'Connection'),
              _SettingsTile(
                icon: Icons.cloud,
                title: 'Server URL',
                subtitle: provider.serverUrl,
                onTap: () => _showServerDialog(context, provider),
              ),
              _SwitchTile(
                icon: Icons.sync,
                title: 'Auto Sync',
                value: provider.autoSync,
                onChanged: (v) => provider.setAutoSync(v),
              ),
              _SettingsTile(
                icon: Icons.timer,
                title: 'Session Timeout',
                subtitle: '${provider.sessionTimeout} hours',
                onTap: () => _showTimeoutDialog(context, provider),
              ),
              _SettingsTile(
                icon: Icons.wifi_find,
                title: 'Test Connection',
                subtitle: 'Check server connectivity',
                onTap: () async {
                  final success = await provider.testConnection();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Connected!' : 'Connection failed'),
                      ),
                    );
                  }
                },
              ),

              // Data section
              _SectionHeader(title: 'Data'),
              _SettingsTile(
                icon: Icons.backup,
                title: 'Backup Data',
                subtitle: 'Export your data',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.delete_forever,
                title: 'Clear Cache',
                subtitle: 'Free up storage',
                onTap: () => _confirmClearCache(context),
              ),
              _SettingsTile(
                icon: Icons.restore,
                title: 'Reset Settings',
                subtitle: 'Restore defaults',
                onTap: () => _confirmReset(context, provider),
              ),

              // About section
              _SectionHeader(title: 'About'),
              _SettingsTile(
                icon: Icons.info,
                title: 'Version',
                subtitle: '1.0.0',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.description,
                title: 'Terms of Service',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                onTap: () {},
              ),

              // Logout
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Logout', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.name ?? 'User'),
            Text(user?.email ?? '', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: provider.themeMode,
              onChanged: (v) {
                provider.setThemeMode(v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: provider.themeMode,
              onChanged: (v) {
                provider.setThemeMode(v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: provider.themeMode,
              onChanged: (v) {
                provider.setThemeMode(v!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: provider.language,
              onChanged: (v) {
                provider.setLanguage(v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Spanish'),
              value: 'es',
              groupValue: provider.language,
              onChanged: (v) {
                provider.setLanguage(v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('French'),
              value: 'fr',
              groupValue: provider.language,
              onChanged: (v) {
                provider.setLanguage(v!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showServerDialog(BuildContext context, SettingsProvider provider) {
    final controller = TextEditingController(text: provider.serverUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'http://localhost:3000',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.setServerUrl(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTimeoutDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Timeout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 6, 12, 24, 48].map((hours) {
            return RadioListTile<int>(
              title: Text('$hours hours'),
              value: hours,
              groupValue: provider.sessionTimeout,
              onChanged: (v) {
                provider.setSessionTimeout(v!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmClearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('This will restore all settings to defaults. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
