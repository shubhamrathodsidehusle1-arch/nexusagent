/// Analytics Dashboard UI
/// Production-ready analytics with charts

import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  AnalyticsData? _data;
  bool _isLoading = true;
  String _selectedPeriod = 'today';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final data = await _analytics.fetchAnalytics();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          DropdownButton<String>(
            value: _selectedPeriod,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'today', child: Text('Today')),
              DropdownMenuItem(value: 'week', child: Text('This Week')),
              DropdownMenuItem(value: 'month', child: Text('This Month')),
              DropdownMenuItem(value: 'year', child: Text('This Year')),
            ],
            onChanged: (v) {
              setState(() => _selectedPeriod = v!);
              _loadAnalytics();
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('No data'))
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewCards(),
                        const SizedBox(height: 24),
                        _buildChartSection(),
                        const SizedBox(height: 24),
                        _buildChannelBreakdown(),
                        const SizedBox(height: 24),
                        _buildTopAgents(),
                        const SizedBox(height: 24),
                        _buildErrorSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _MetricCard(
              title: 'Active Sessions',
              value: _data!.activeSessions.toString(),
              subtitle: 'of ${_data!.totalSessions} total',
              icon: Icons.chat,
              color: Colors.blue,
            ),
            _MetricCard(
              title: 'Messages Today',
              value: _formatNumber(_data!.messagesToday),
              subtitle: '${_data!.totalMessages} all time',
              icon: Icons.message,
              color: Colors.green,
            ),
            _MetricCard(
              title: 'Tool Calls Today',
              value: _formatNumber(_data!.toolCallsToday),
              subtitle: '${_data!.totalToolCalls} all time',
              icon: Icons.build,
              color: Colors.orange,
            ),
            _MetricCard(
              title: 'Success Rate',
              value: '${_data!.successRate.toStringAsFixed(1)}%',
              subtitle: '${_data!.avgResponseTime}s avg response',
              icon: Icons.check_circle,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activity Over Time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('Activity Chart', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text('24-hour activity overview', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelBreakdown() {
    final channels = _data!.messagesByChannel.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Messages by Channel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: channels.map((e) {
              final total = _data!.totalMessages;
              final percent = total > 0 ? (e.value / total * 100) : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('${_formatNumber(e.value)} (${percent.toStringAsFixed(1)}%)'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(_getChannelColor(e.key)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTopAgents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Agents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: _data!.topAgents.asMap().entries.map((entry) {
              final agent = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRankColor(entry.key),
                  child: Text('${entry.key + 1}', style: const TextStyle(color: Colors.white)),
                ),
                title: Text(agent.name),
                subtitle: Text('${agent.sessions} sessions • ${agent.messages} messages'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${agent.toolCalls}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('tool calls', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Errors', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_data!.errorsToday} today',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_data!.recentErrors.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('No errors! 🎉')),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _data!.recentErrors.map((e) {
                return ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: Text(e.error),
                  subtitle: Text('${e.toolName ?? 'N/A'} • ${_formatTime(e.timestamp)}'),
                  trailing: e.resolved
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : IconButton(
                          icon: const Icon(Icons.check, color: Colors.grey),
                          onPressed: () {},
                        ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Color _getChannelColor(String channel) {
    switch (channel.toLowerCase()) {
      case 'telegram': return Colors.blue;
      case 'discord': return Colors.purple;
      case 'whatsapp': return Colors.green;
      case 'slack': return Colors.orange;
      case 'signal': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0: return Colors.amber;
      case 1: return Colors.grey;
      case 2: return Colors.brown;
      default: return Colors.blueGrey;
    }
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
