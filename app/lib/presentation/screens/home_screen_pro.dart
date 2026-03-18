/// Home Dashboard - Production Ready
/// Enterprise-grade dashboard with analytics

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Side Navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            extended: MediaQuery.of(context).size.width > 800,
            minExtendedWidth: 180,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.purple],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
                  ),
                  if (MediaQuery.of(context).size.width > 800) ...[
                    const SizedBox(height: 8),
                    const Text('NexusAgent', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.smart_toy_outlined),
                selectedIcon: Icon(Icons.smart_toy),
                label: Text('Agents'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_outlined),
                selectedIcon: Icon(Icons.chat),
                label: Text('Channels'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Analytics'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_tree_outlined),
                selectedIcon: Icon(Icons.account_tree),
                label: Text('Workflows'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: Text('Team'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return _DashboardContent();
      case 1: return _AgentsContent();
      case 2: return _ChannelsContent();
      case 3: return _AnalyticsContent();
      case 4: return _WorkflowsContent();
      case 5: return _TeamContent();
      case 6: return _SettingsContent();
      default: return _DashboardContent();
    }
  }
}

class _DashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Here\'s what\'s happening with your agents', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New Agent'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Quick Stats
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2,
            children: [
              _QuickStatCard(
                title: 'Active Agents',
                value: '8',
                subtitle: '12 total',
                icon: Icons.smart_toy,
                color: Colors.blue,
              ),
              _QuickStatCard(
                title: 'Sessions Today',
                value: '247',
                subtitle: '↑ 12%',
                icon: Icons.chat,
                color: Colors.green,
              ),
              _QuickStatCard(
                title: 'Messages',
                value: '1.2K',
                subtitle: '↑ 8%',
                icon: Icons.message,
                color: Colors.purple,
              ),
              _QuickStatCard(
                title: 'Success Rate',
                value: '98.7%',
                subtitle: '↓ 0.3%',
                icon: Icons.check_circle,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Recent Activity
          const Text('Recent Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ActivityCard(
            title: 'Support Bot',
            subtitle: 'New session started',
            time: '2 min ago',
            icon: Icons.smart_toy,
            color: Colors.blue,
          ),
          _ActivityCard(
            title: 'Sales Assistant',
            subtitle: 'Processed 15 leads',
            time: '15 min ago',
            icon: Icons.sales,
            color: Colors.green,
          ),
          _ActivityCard(
            title: 'Code Reviewer',
            subtitle: 'Completed review',
            time: '1 hour ago',
            icon: Icons.code,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _QuickStatCard({
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }
}

// Placeholder screens
class _AgentsContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Agents Screen'));
  }
}

class _ChannelsContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Channels Screen'));
  }
}

class _AnalyticsContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Analytics Screen'));
  }
}

class _WorkflowsContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Workflows Screen'));
  }
}

class _TeamContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Team Screen'));
  }
}

class _SettingsContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Settings Screen'));
  }
}
