import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/agent_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Mock data
  final Analytics _analytics = Analytics(
    totalMessages: 1247,
    totalAgents: 5,
    activeAgents: 3,
    totalRuns: 892,
    avgResponseTime: 1.2,
    tokensUsed: 125000,
    dailyMetrics: List.generate(7, (i) => DailyMetric(
      date: DateTime.now().subtract(Duration(days: 6 - i)),
      messages: 100 + (i * 20),
      runs: 50 + (i * 10),
      tokens: 10000 + (i * 2000),
    )),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🧠', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            const Text('NexusAgent'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.3), AppColors.secondary.withOpacity(0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back! 👋', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  const Text('Your AI Command Center', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildQuickStat('🤖', '${_analytics.activeAgents}', 'Active'),
                      const SizedBox(width: 16),
                      _buildQuickStat('💬', '${_analytics.totalMessages}', 'Messages'),
                      const SizedBox(width: 16),
                      _buildQuickStat('⚡', '${_analytics.avgResponseTime}s', 'Avg Time'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick Actions
            Text('Quick Actions', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildActionCard('➕', 'New Agent', () {}, AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _buildActionCard('💬', 'Connect Channel', () {}, AppColors.secondary)),
                const SizedBox(width: 12),
                Expanded(child: _buildActionCard('🧠', 'Add Memory', () {}, AppColors.accent)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Activity Chart
            Text('This Week', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 200,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(days[value.toInt()], style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _analytics.dailyMetrics[i].runs.toDouble(),
                        color: i == 6 ? AppColors.primary : AppColors.primary.withOpacity(0.6),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  )),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Recent Activity
            Text('Recent Activity', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            _buildActivityItem('🤖', 'Code Expert', 'Completed task', '2 min ago'),
            _buildActivityItem('💬', 'Telegram', 'New message from user', '5 min ago'),
            _buildActivityItem('🧠', 'Memory', 'Saved new context', '10 min ago'),
            _buildActivityItem('⚡', 'AI Assistant', 'Agent run completed', '15 min ago'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String emoji, String value, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String emoji, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String icon, String title, String subtitle, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
