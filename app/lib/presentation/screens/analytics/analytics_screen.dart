/// NexusAgent Analytics Screen - Connected
/// Real analytics with providers

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AnalyticsProvider>().refresh(),
          ),
        ],
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Overview cards
                _OverviewCards(analytics: provider),
                const SizedBox(height: 24),

                // Chart
                const Text(
                  'Activity (Last 7 Days)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _ActivityChart(metrics: provider.dailyMetrics),
                const SizedBox(height: 24),

                // Top Agents
                const Text(
                  'Top Agents',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...provider.topAgents.map((agent) => _TopAgentTile(agent: agent)),
                const SizedBox(height: 24),

                // Top Channels
                const Text(
                  'Top Channels',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...provider.topChannels.map((channel) => _TopChannelTile(channel: channel)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewCards extends StatelessWidget {
  final AnalyticsProvider analytics;

  const _OverviewCards({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Agents',
                value: '${analytics.activeAgents}/${analytics.totalAgents}',
                icon: Icons.smart_toy,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Channels',
                value: '${analytics.activeChannels}/${analytics.totalChannels}',
                icon: Icons.chat,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Sessions',
                value: '${analytics.activeSessions}/${analytics.totalSessions}',
                icon: Icons.session_presentation,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Messages',
                value: '${analytics.totalMessages}',
                icon: Icons.message,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  final List<DailyMetric> metrics;

  const _ActivityChart({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      final index = value.toInt();
                      if (index >= 0 && index < metrics.length) {
                        return Text(
                          days[metrics[index].date.weekday - 1],
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Sessions line
                LineChartBarData(
                  spots: metrics.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.sessions.toDouble());
                  }).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                ),
                // Messages line
                LineChartBarData(
                  spots: metrics.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.messages / 50);
                  }).toList(),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopAgentTile extends StatelessWidget {
  final TopAgent agent;

  const _TopAgentTile({required this.agent});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: const Icon(Icons.smart_toy, color: Colors.blue),
        ),
        title: Text(agent.name),
        subtitle: Text('${agent.sessions} sessions • ${agent.messages} messages'),
      ),
    );
  }
}

class _TopChannelTile extends StatelessWidget {
  final TopChannel channel;

  const _TopChannelTile({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: const Icon(Icons.chat, color: Colors.green),
        ),
        title: Text(channel.name),
        subtitle: Text('${channel.sessions} sessions • ${channel.messages} messages'),
      ),
    );
  }
}
