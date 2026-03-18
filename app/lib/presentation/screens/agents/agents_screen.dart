/// NexusAgent Agents Screen - Connected
/// Real agent management with providers

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agents_provider.dart';
import '../widgets/agent_card.dart';

class AgentsScreen extends StatelessWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AgentsProvider>().loadAgents(),
          ),
        ],
      ),
      body: Consumer<AgentsProvider>(
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
                    onPressed: () => provider.loadAgents(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.agents.isEmpty) {
            return _EmptyState(
              onAdd: () => _showAddAgentDialog(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAgents(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.agents.length,
              itemBuilder: (context, index) {
                final agent = provider.agents[index];
                return AgentCard(
                  agent: agent,
                  onTap: () => _showAgentDetails(context, agent),
                  onToggle: () => provider.toggleAgent(agent.id),
                  onDelete: () => _confirmDelete(context, agent),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAgentDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAgentDetails(BuildContext context, Agent agent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _AgentDetailsSheet(
          agent: agent,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showAddAgentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddAgentDialog(),
    );
  }

  void _confirmDelete(BuildContext context, Agent agent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Agent'),
        content: Text('Are you sure you want to delete "${agent.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AgentsProvider>().deleteAgent(agent.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No agents yet'),
          const SizedBox(height: 8),
          const Text('Create your first AI agent'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Agent'),
          ),
        ],
      ),
    );
  }
}

class _AgentDetailsSheet extends StatelessWidget {
  final Agent agent;
  final ScrollController scrollController;

  const _AgentDetailsSheet({
    required this.agent,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Icon(
                  Icons.smart_toy,
                  size: 30,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      agent.model ?? 'Default model',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(agent.status),
                backgroundColor: agent.isActive ? Colors.green : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Description
          if (agent.description != null) ...[
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(agent.description!),
            const SizedBox(height: 24),
          ],

          // Tools
          const Text(
            'Tools',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: agent.tools.map((tool) => Chip(label: Text(tool))).toList(),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Run agent
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Edit agent
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddAgentDialog extends StatefulWidget {
  const _AddAgentDialog();

  @override
  State<_AddAgentDialog> createState() => _AddAgentDialogState();
}

class _AddAgentDialogState extends State<_AddAgentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _model = 'claude-3-opus';
  List<String> _selectedTools = [];

  final _availableTools = [
    'web_search',
    'web_fetch',
    'memory',
    'exec',
    'message',
    'browser',
    'cron',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Agent'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _model,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'claude-3-opus', child: Text('Claude 3 Opus')),
                  DropdownMenuItem(value: 'claude-3-sonnet', child: Text('Claude 3 Sonnet')),
                  DropdownMenuItem(value: 'gpt-4', child: Text('GPT-4')),
                  DropdownMenuItem(value: 'gpt-4-mini', child: Text('GPT-4 Mini')),
                ],
                onChanged: (v) => setState(() => _model = v!),
              ),
              const SizedBox(height: 16),
              const Text('Tools', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTools.map((tool) {
                  final selected = _selectedTools.contains(tool);
                  return FilterChip(
                    label: Text(tool),
                    selected: selected,
                    onSelected: (s) {
                      setState(() {
                        if (s) {
                          _selectedTools.add(tool);
                        } else {
                          _selectedTools.remove(tool);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _create,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _create() {
    if (!_formKey.currentState!.validate()) return;

    final agent = Agent(
      id: 'agent_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      model: _model,
      tools: _selectedTools,
      status: 'active',
      createdAt: DateTime.now(),
    );

    context.read<AgentsProvider>().createAgent(agent);
    Navigator.pop(context);
  }
}

// Extension for toggle
extension on AgentsProvider {
  void toggleAgent(String id) {
    // Would toggle agent status
  }
}
