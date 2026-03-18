/// Visual Workflow Builder Screen
/// Drag-and-drop workflow automation

import 'dart:async';

enum WorkflowNodeType {
  trigger,
  agent,
  condition,
  action,
  delay,
  filter,
  transform,
  http,
  webhook,
}

class WorkflowNode {
  final String id;
  final String name;
  final WorkflowNodeType type;
  double x;
  double y;
  Map<String, dynamic> config;
  List<String> outputIds;
  List<String> inputIds;

  WorkflowNode({
    required this.id,
    required this.name,
    required this.type,
    this.x = 0,
    this.y = 0,
    this.config = const {},
    this.outputIds = const [],
    this.inputIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'x': x,
    'y': y,
    'config': config,
    'outputIds': outputIds,
    'inputIds': inputIds,
  };

  factory WorkflowNode.fromJson(Map<String, dynamic> json) {
    return WorkflowNode(
      id: json['id'],
      name: json['name'],
      type: WorkflowNodeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => WorkflowNodeType.action,
      ),
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      config: Map<String, dynamic>.from(json['config'] ?? {}),
      outputIds: List<String>.from(json['outputIds'] ?? []),
      inputIds: List<String>.from(json['inputIds'] ?? []),
    );
  }
}

class Workflow {
  final String id;
  final String name;
  final String? description;
  final bool enabled;
  final List<WorkflowNode> nodes;
  final DateTime createdAt;
  final DateTime? lastRunAt;
  final int runCount;

  Workflow({
    required this.id,
    required this.name,
    this.description,
    this.enabled = false,
    this.nodes = const [],
    DateTime? createdAt,
    this.lastRunAt,
    this.runCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'enabled': enabled,
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'lastRunAt': lastRunAt?.toIso8601String(),
    'runCount': runCount,
  };

  factory Workflow.fromJson(Map<String, dynamic> json) {
    return Workflow(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      enabled: json['enabled'] ?? false,
      nodes: (json['nodes'] as List?)
          ?.map((n) => WorkflowNode.fromJson(n))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      lastRunAt: json['lastRunAt'] != null 
          ? DateTime.parse(json['lastRunAt']) 
          : null,
      runCount: json['runCount'] ?? 0,
    );
  }
}

class WorkflowService {
  static final WorkflowService _instance = WorkflowService._internal();
  factory WorkflowService() => _instance;
  WorkflowService._internal();

  final List<Workflow> _workflows = [];
  final _workflowController = StreamController<List<Workflow>>.broadcast();

  Stream<List<Workflow>> get workflowsStream => _workflowController.stream;

  /// Create workflow
  Workflow createWorkflow(String name, {String? description}) {
    final workflow = Workflow(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
    );
    _workflows.add(workflow);
    _notifyListeners();
    return workflow;
  }

  /// Update workflow
  void updateWorkflow(Workflow workflow) {
    final index = _workflows.indexWhere((w) => w.id == workflow.id);
    if (index >= 0) {
      _workflows[index] = workflow;
      _notifyListeners();
    }
  }

  /// Delete workflow
  void deleteWorkflow(String workflowId) {
    _workflows.removeWhere((w) => w.id == workflowId);
    _notifyListeners();
  }

  /// Get workflow
  Workflow? getWorkflow(String workflowId) {
    return _workflows.where((w) => w.id == workflowId).firstOrNull;
  }

  /// List workflows
  List<Workflow> listWorkflows() => List.from(_workflows);

  /// Enable/disable workflow
  void setEnabled(String workflowId, bool enabled) {
    final workflow = getWorkflow(workflowId);
    if (workflow != null) {
      updateWorkflow(Workflow(
        id: workflow.id,
        name: workflow.name,
        description: workflow.description,
        enabled: enabled,
        nodes: workflow.nodes,
        createdAt: workflow.createdAt,
        lastRunAt: workflow.lastRunAt,
        runCount: workflow.runCount,
      ));
    }
  }

  /// Run workflow
  Future<void> runWorkflow(String workflowId) async {
    final workflow = getWorkflow(workflowId);
    if (workflow == null || !workflow.enabled) return;

    // Execute workflow nodes in order
    for (final node in workflow.nodes) {
      await _executeNode(node);
    }

    // Update last run
    final index = _workflows.indexWhere((w) => w.id == workflowId);
    if (index >= 0) {
      final w = _workflows[index];
      _workflows[index] = Workflow(
        id: w.id,
        name: w.name,
        description: w.description,
        enabled: w.enabled,
        nodes: w.nodes,
        createdAt: w.createdAt,
        lastRunAt: DateTime.now(),
        runCount: w.runCount + 1,
      );
      _notifyListeners();
    }
  }

  Future<void> _executeNode(WorkflowNode node) async {
    // Execute based on node type
    switch (node.type) {
      case WorkflowNodeType.trigger:
        // Handle trigger
        break;
      case WorkflowNodeType.agent:
        // Run agent
        break;
      case WorkflowNodeType.condition:
        // Check condition
        break;
      case WorkflowNodeType.action:
        // Execute action
        break;
      case WorkflowNodeType.delay:
        final delay = node.config['delay'] ?? 1000;
        await Future.delayed(Duration(milliseconds: delay));
        break;
      case WorkflowNodeType.filter:
        // Filter data
        break;
      case WorkflowNodeType.transform:
        // Transform data
        break;
      case WorkflowNodeType.http:
        // HTTP request
        break;
      case WorkflowNodeType.webhook:
        // Send webhook
        break;
    }
  }

  /// Validate workflow
  List<String> validateWorkflow(Workflow workflow) {
    final errors = <String>[];

    if (workflow.nodes.isEmpty) {
      errors.add('Workflow must have at least one node');
    }

    // Check for triggers
    final hasTrigger = workflow.nodes.any((n) => n.type == WorkflowNodeType.trigger);
    if (!hasTrigger) {
      errors.add('Workflow must have at least one trigger');
    }

    // Check for orphaned nodes
    for (final node in workflow.nodes) {
      if (node.inputIds.isEmpty && node.type != WorkflowNodeType.trigger) {
        errors.add('Node "${node.name}" has no inputs');
      }
      if (node.outputIds.isEmpty && node.type != WorkflowNodeType.action) {
        errors.add('Node "${node.name}" has no outputs');
      }
    }

    return errors;
  }

  void _notifyListeners() {
    _workflowController.add(_workflows);
  }

  void dispose() {
    _workflowController.close();
  }
}

// Node templates for quick creation
class NodeTemplates {
  static List<WorkflowNode> getTriggers() => [
    WorkflowNode(id: '1', name: 'Message Received', type: WorkflowNodeType.trigger, config: {'channel': 'telegram'}),
    WorkflowNode(id: '2', name: 'Scheduled', type: WorkflowNodeType.trigger, config: {'cron': '0 * * * *'}),
    WorkflowNode(id: '3', name: 'Webhook', type: WorkflowNodeType.trigger, config: {'url': '/webhook'}),
    WorkflowNode(id: '4', name: 'Keyword', type: WorkflowNodeType.trigger, config: {'keyword': ''}),
  ];

  static List<WorkflowNode> getActions() => [
    WorkflowNode(id: 'a1', name: 'Send Message', type: WorkflowNodeType.action, config: {'action': 'send'}),
    WorkflowNode(id: 'a2', name: 'Run Agent', type: WorkflowNodeType.action, config: {'agentId': ''}),
    WorkflowNode(id: 'a3', name: 'HTTP Request', type: WorkflowNodeType.http, config: {'method': 'GET', 'url': ''}),
    WorkflowNode(id: 'a4', name: 'Delay', type: WorkflowNodeType.delay, config: {'delay': 1000}),
  ];

  static List<WorkflowNode> getLogic() => [
    WorkflowNode(id: 'l1', name: 'If/Else', type: WorkflowNodeType.condition, config: {'condition': ''}),
    WorkflowNode(id: 'l2', name: 'Filter', type: WorkflowNodeType.filter, config: {'filter': ''}),
    WorkflowNode(id: 'l3', name: 'Transform', type: WorkflowNodeType.transform, config: {'transform': ''}),
  ];
}
