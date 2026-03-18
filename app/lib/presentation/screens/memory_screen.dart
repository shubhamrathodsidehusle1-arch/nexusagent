import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/agent_model.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  final _searchController = TextEditingController();
  
  // Mock memory entries
  final List<MemoryEntry> _memories = [
    MemoryEntry(
      id: '1', orgId: 'org1',
      content: 'User prefers concise responses. Always use bullet points when available.',
      tags: ['preference', 'style'],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      accessCount: 15,
    ),
    MemoryEntry(
      id: '2', orgId: 'org1',
      content: 'Current project: Building a mobile app for AI agent orchestration',
      tags: ['project', 'context'],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      accessCount: 8,
    ),
    MemoryEntry(
      id: '3', orgId: 'org1',
      content: 'Favorite programming languages: Python, TypeScript, Go',
      tags: ['preference', 'tech'],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      accessCount: 23,
    ),
    MemoryEntry(
      id: '4', orgId: 'org1',
      content: 'Working hours: 9 AM - 6 PM UTC. Best time for meetings: 10 AM - 4 PM UTC.',
      tags: ['schedule', 'availability'],
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      accessCount: 5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search memory...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          
          // Quick Tags
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildTagChip('All', true),
                _buildTagChip('Preference', false),
                _buildTagChip('Project', false),
                _buildTagChip('Context', false),
                _buildTagChip('Schedule', false),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Memory List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _memories.length,
              itemBuilder: (context, index) {
                return _buildMemoryCard(_memories[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemorySheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Memory'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildTagChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {},
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 12),
      ),
    );
  }

  Widget _buildMemoryCard(MemoryEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.content,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'copy', child: Text('Copy')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...entry.tags.map((tag) => Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(6)),
                child: Text(tag, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              )),
              const Spacer(),
              Text('Used ${entry.accessCount}x', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMemorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text('Add to Memory', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            const Text('Content', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Enter information you want the AI to remember...'),
            ),
            const SizedBox(height: 16),
            const Text('Tags (optional)', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(label: const Text('preference'), onPressed: () {}),
                ActionChip(label: const Text('project'), onPressed: () {}),
                ActionChip(label: const Text('context'), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Save Memory'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
