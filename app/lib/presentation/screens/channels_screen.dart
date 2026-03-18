import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class ChannelsScreen extends StatelessWidget {
  const ChannelsScreen({super.key});

  final List<Map<String, dynamic>> _channels = [
    {'id': '1', 'type': 'telegram', 'name': 'Main Bot', 'enabled': true, 'messages': 523},
    {'id': '2', 'type': 'discord', 'name': 'Discord Server', 'enabled': true, 'messages': 234},
    {'id': '3', 'type': 'slack', 'name': 'Workspace', 'enabled': false, 'messages': 89},
    {'id': '4', 'type': 'whatsapp', 'name': 'WhatsApp Bot', 'enabled': true, 'messages': 156},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Channels')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connected Channels
          Text('Connected Channels', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ..._channels.map((channel) => _buildChannelCard(context, channel)),
          
          const SizedBox(height: 24),
          
          // Add Channel
          Text('Connect New Channel', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...ChannelTypes.channels.map((channel) => _buildAddChannelOption(context, channel)),
        ],
      ),
    );
  }

  Widget _buildChannelCard(BuildContext context, Map<String, dynamic> channel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: channel['enabled'] ? null : Border.all(color: AppColors.textMuted.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(_getChannelEmoji(channel['type']), style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(channel['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: channel['enabled'] ? AppColors.success.withOpacity(0.2) : AppColors.textMuted.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        channel['enabled'] ? 'Active' : 'Disabled',
                        style: TextStyle(fontSize: 10, color: channel['enabled'] ? AppColors.success : AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                Text('${channel['messages']} messages', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: channel['enabled'],
            onChanged: (value) {},
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAddChannelOption(BuildContext context, Map<String, dynamic> channel) {
    final isConnected = _channels.any((c) => c['type'] == channel['id']);
    
    return GestureDetector(
      onTap: isConnected ? null : () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isConnected ? AppColors.surfaceLight : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isConnected ? AppColors.success : Colors.transparent),
        ),
        child: Row(
          children: [
            Text(channel['icon'], style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                channel['name'],
                style: TextStyle(fontWeight: FontWeight.w600, color: isConnected ? AppColors.textMuted : null),
              ),
            ),
            if (isConnected)
              const Icon(Icons.check_circle, color: AppColors.success)
            else
              Text('Connect', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String _getChannelEmoji(String type) {
    switch (type) {
      case 'telegram': return '✈️';
      case 'discord': return '🎮';
      case 'slack': return '💬';
      case 'whatsapp': return '📱';
      default: return '💭';
    }
  }
}
