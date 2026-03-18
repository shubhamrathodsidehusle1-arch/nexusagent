/// NexusAgent Workflows Screen - Connected
/// Real workflow management with providers

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workflows_provider.dart';

class WorkflowsScreen extends StatelessWidget {
  const WorkflowsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflows'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<WorkflowsProvider>().loadWorkflows(),
          ),
        ],
      ),
      body: Consumer<WorkflowsProvider>(
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
                    onPressed: () => provider.loadWorkflows(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.workflows.isEmpty) {
            return _EmptyState(
              onAdd: () => _showAddWorkflowDialog(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadWorkflows(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.workflows.length,
              itemBuilder: (context, index) {
                final workflow = provider.workflows[index];
                return _WorkflowCard(
                  workflow: workflow,
                  onToggle: () => provider.toggleWorkflow(workflow.id),
                  onDelete: () => _confirmDelete(context, workflow),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWorkflowDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddWorkflowDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddWorkflowDialog(),
    );
  }

  void _confirmDelete(BuildContext context, Workflow workflow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workflow'),
        content: Text('Are you sure you want to delete "${workflow.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<WorkflowsProvider>().deleteWorkflow(workflow.id);
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
          Icon(Icons.account_tree_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No workflows yet'),
          const SizedBox(height: 8),
          const Text('Automate your tasks with workflows'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Workflow'),
          ),
        ],
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  final Workflow workflow;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _WorkflowCard({
    required this.workflow,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Show workflow details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: workflow.enabled
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.account_tree,
                      color: workflow.enabled ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workflow.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${workflow.nodes.length} nodes',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: workflow.enabled,
                    onChanged: (_) => onToggle(),
                  ),
                ],
              ),

              // Description
              if (workflow.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  workflow.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],

              // Nodes preview
              const SizedBox(height: 12),
              Row(
                children: [
                  ...workflow.nodes.take(3).map((node) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(node.type, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                    ),
                  )),
                  if (workflow.nodes.length > 3)
                    Text(
                      '+${workflow.nodes.length - 3}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                ],
              ),

              // Actions
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      // Edit workflow
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddWorkflowDialog extends StatefulWidget {
  const _AddWorkflowDialog();

  @override
  State<_AddWorkflowDialog> createState() => _AddWorkflowDialogState();
}

class _AddWorkflowDialogState extends State<_AddWorkflowDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Workflow'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
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
    if (_nameController.text.trim().isEmpty) return;

    final workflow = Workflow(
      id: 'wf_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      nodes: [],
      enabled: false,
      createdAt: DateTime.now(),
    );

    context.read<WorkflowsProvider>().createWorkflow(workflow);
    Navigator.pop(context);
  }
}
