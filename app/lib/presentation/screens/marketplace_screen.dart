import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  final List<Map<String, dynamic>> _featuredAgents = [
    {'name': 'Data Analyst Pro', 'description': 'Advanced data analysis and visualization', 'icon': '📊', 'rating': 4.8, 'downloads': '2.3K'},
    {'name': 'Content Writer', 'description': 'SEO-optimized content creation', 'icon': '✍️', 'rating': 4.7, 'downloads': '1.8K'},
    {'name': 'Code Reviewer', 'description': 'Automated code quality checks', 'icon': '💻', 'rating': 4.9, 'downloads': '3.1K'},
    {'name': 'Customer Support', 'description': 'AI-powered support assistant', 'icon': '🎧', 'rating': 4.6, 'downloads': '1.2K'},
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Development', 'icon': '💻', 'count': 45},
    {'name': 'Content', 'icon': '📝', 'count': 32},
    {'name': 'Analytics', 'icon': '📊', 'count': 28},
    {'name': 'Marketing', 'icon': '📢', 'count': 24},
    {'name': 'Productivity', 'icon': '⚡', 'count': 52},
    {'name': 'Automation', 'icon': '🤖', 'count': 38},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search
          TextField(
            decoration: InputDecoration(
              hintText: 'Search agents...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.tune), onPressed: () {}),
            ),
          ),
          const SizedBox(height: 24),

          // Categories
          Text('Categories', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat['icon'], style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 8),
                      Text(cat['name'], style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
                      Text('${cat['count']}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Featured
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Featured', style: Theme.of(context).textTheme.titleMedium),
              TextButton(onPressed: () {}, child: const Text('See All')),
            ],
          ),
          const SizedBox(height: 12),
          ..._featuredAgents.map((agent) => _buildAgentCard(agent)),

          const SizedBox(height: 24),

          // Trending
          Text('Trending This Week', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...List.generate(3, (i) => _buildTrendingCard(i)),
        ],
      ),
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> agent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(agent['icon'], style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agent['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(agent['description'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(agent['rating'], style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.download, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(agent['downloads'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
            child: const Text('Use'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(int index) {
    final agents = ['Research Assistant', 'SEO Expert', 'Legal Advisor'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.2), AppColors.secondary.withOpacity(0.2)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(agents[index], style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const Icon(Icons.trending_up, color: AppColors.success),
        ],
      ),
    );
  }
}
