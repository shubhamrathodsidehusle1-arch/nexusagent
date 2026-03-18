import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  final List<Map<String, dynamic>> _members = [
    {'id': '1', 'name': 'John Doe', 'email': 'john@example.com', 'role': 'owner', 'avatar': 'J'},
    {'id': '2', 'name': 'Jane Smith', 'email': 'jane@example.com', 'role': 'admin', 'avatar': 'J'},
    {'id': '3', 'name': 'Bob Wilson', 'email': 'bob@example.com', 'role': 'member', 'avatar': 'B'},
    {'id': '4', 'name': 'Alice Brown', 'email': 'alice@example.com', 'role': 'member', 'avatar': 'A'},
  ];

  final List<Map<String, dynamic>> _invites = [
    {'email': 'newuser@example.com', 'status': 'pending', 'role': 'member'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Plan Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.group, color: Colors.white, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Team Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('4 of 5 members used', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                Text('\$99/mo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Members Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Members', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => _showInviteDialog(context),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Invite'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._members.map((member) => _buildMemberCard(context, member)),

          const SizedBox(height: 24),

          // Pending Invites
          if (_invites.isNotEmpty) ...[
            Text('Pending Invites', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._invites.map((invite) => _buildInviteCard(context, invite)),
          ],

          const SizedBox(height: 24),

          // Roles Info
          Text('Roles', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildRoleInfo('Owner', 'Full access, billing, can delete workspace', AppColors.warning),
                const Divider(height: 24),
                _buildRoleInfo('Admin', 'Manage agents, channels, and team members', AppColors.primary),
                const Divider(height: 24),
                _buildRoleInfo('Member', 'Use agents and channels', AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, Map<String, dynamic> member) {
    Color roleColor;
    switch (member['role']) {
      case 'owner':
        roleColor = AppColors.warning;
        break;
      case 'admin':
        roleColor = AppColors.primary;
        break;
      default:
        roleColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(member['avatar'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (member['role'] == 'owner') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: roleColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text(member['role'], style: TextStyle(fontSize: 10, color: roleColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                Text(member['email'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'change_role', child: Text('Change Role')),
              const PopupMenuItem(value: 'remove', child: Text('Remove', style: TextStyle(color: AppColors.error))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(BuildContext context, Map<String, dynamic> invite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.surfaceLight, shape: BoxShape.circle),
            child: const Center(child: Icon(Icons.mail, color: AppColors.textMuted)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invite['email'], style: const TextStyle(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                      child: const Text('Pending', style: TextStyle(fontSize: 10, color: AppColors.warning)),
                    ),
                    const SizedBox(width: 8),
                    Text(invite['role'], style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {},
            tooltip: 'Resend',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.error),
            onPressed: () {},
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }

  Widget _buildRoleInfo(String role, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8, height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
              Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Team Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Email', hintText: 'colleague@company.com'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: 'member',
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'member', child: Text('Member')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Send Invite')),
        ],
      ),
    );
  }
}
