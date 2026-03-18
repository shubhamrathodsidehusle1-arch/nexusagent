/// NexusAgent Channels Screen - Connected
/// Real channel management with providers

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/channels_provider.dart';

class ChannelsScreen extends StatelessWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Channels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ChannelsProvider>().loadChannels(),
          ),
        ],
      ),
      body: Consumer<ChannelsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadChannels(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadChannels(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats
                _ChannelStats(channels: provider.channels),
                const SizedBox(height: 24),

                // Enabled channels
                if (provider.enabledChannels.isNotEmpty) ...[
                  const Text(
                    'Active Channels',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ...provider.enabledChannels.map((channel) => _ChannelTile(
                    channel: channel,
                    onToggle: () => provider.disableChannel(channel.id),
                  )),
                  const SizedBox(height: 24),
                ],

                // Disabled channels
                if (provider.channels.where((c) => !c.enabled).isNotEmpty) ...[
                  const Text(
                    'Available Channels',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ...provider.channels.where((c) => !c.enabled).map((channel) => _ChannelTile(
                    channel: channel,
                    onToggle: () => provider.enableChannel(channel.id),
                  )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChannelStats extends StatelessWidget {
  final List<Channel> channels;

  const _ChannelStats({required this.channels});

  @override
  Widget build(BuildContext context) {
    final enabled = channels.where((c) => c.enabled).length;
    final total = channels.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$enabled',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Active',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Total',
                    style: TextStyle(color: Colors.grey[600]),
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

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onToggle;

  const _ChannelTile({
    required this.channel,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: channel.color.withValues(alpha: 0.1),
          child: Icon(channel.icon, color: channel.color),
        ),
        title: Text(channel.name),
        subtitle: Text(channel.enabled ? 'Connected' : 'Disabled'),
        trailing: Switch(
          value: channel.enabled,
          onChanged: (_) => onToggle(),
        ),
        onTap: () {
          // Show channel details
        },
      ),
    );
  }
}
