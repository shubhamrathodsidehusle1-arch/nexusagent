import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';

class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  String _period = 'month';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage & Costs'),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => setState(() => _period = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'year', child: Text('This Year')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cost Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total This Month', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                const Text('\$127.45', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildCostStat('API', '\$89.20', '70%'),
                    const SizedBox(width: 24),
                    _buildCostStat('Storage', '\$18.25', '14%'),
                    const SizedBox(width: 24),
                    _buildCostStat('Channels', '\$20.00', '16%'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Usage Chart
          Text('API Calls', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(30, (i) => FlSpot(i.toDouble(), 500 + (i * 20) + (i % 7 == 0 ? 200 : 0))),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Breakdown by Agent
          Text('Usage by Agent', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildAgentUsage('AI Assistant', 45, 125000, '\$62.50'),
          _buildAgentUsage('Code Expert', 30, 85000, '\$42.50'),
          _buildAgentUsage('Content Writer', 15, 45000, '\$22.50'),
          _buildAgentUsage('Data Analyst', 10, 28000, '\$14.00'),

          const SizedBox(height: 24),

          // Token Usage
          Text('Token Usage', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildTokenRow('Input Tokens', '245K', '\$12.25'),
                const Divider(height: 24),
                _buildTokenRow('Output Tokens', '78K', '\$39.00'),
                const Divider(height: 24),
                _buildTokenRow('Cached Tokens', '42K', '\$2.10', isHighlight: true),
                const Divider(height: 24),
                _buildTokenRow('Total', '365K', '\$53.35', isBold: true),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quota
          Text('Quota Limits', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildQuotaCard('API Calls', 12547, 50000),
          _buildQuotaCard('Storage', 2.4, 10),
          _buildQuotaCard('Agents', 5, 10),
          _buildQuotaCard('Team Members', 4, 5),

          const SizedBox(height: 24),

          // Export
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download),
            label: const Text('Export Usage Report'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostStat(String label, String value, String percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text('$label ($percent)', style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildAgentUsage(String name, int percent, int tokens, String cost) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(cost, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: percent / 100,
                  backgroundColor: AppColors.surfaceLight,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text('$tokens tokens', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenRow(String label, String amount, String cost, {bool isBold = false, bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isHighlight ? AppColors.success : null)),
        Row(
          children: [
            Text(amount, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(width: 16),
            Text(cost, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: isHighlight ? AppColors.success : null)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuotaCard(String label, num current, num max) {
    final percent = (current / max * 100).clamp(0, 100);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percent / 100,
                  backgroundColor: AppColors.surfaceLight,
                  color: percent > 80 ? AppColors.warning : AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$current', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('of $max', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
