/// NexusAgent Workflows Provider - Connected
/// Real workflow management

import 'package:flutter/material.dart';
import '../../data/services/database_service.dart';
import '../../data/services/api_service.dart';
import '../../data/services/sync_service.dart';

class WorkflowsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final ApiService _api = ApiService();
  final SyncService _sync = SyncService();

  List<Workflow> _workflows = [];
  bool _isLoading = false;
  String? _error;

  List<Workflow> get workflows => _workflows;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Workflow> get enabledWorkflows =>
      _workflows.where((w) => w.enabled).toList();

  /// Load workflows if authenticated
  Future<void> loadIfAuthenticated(bool isAuthenticated) async {
    if (isAuthenticated) {
      await loadWorkflows();
    }
  }

  /// Load all workflows
  Future<void> loadWorkflows() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try local database first
      final dbWorkflows = await _db.getWorkflows();
      
      if (dbWorkflows.isNotEmpty) {
        _workflows = dbWorkflows.map((w) => Workflow.fromMap(w)).toList();
      } else {
        // Load demo workflows
        _workflows = _getDemoWorkflows();
        
        // Save to database
        for (final workflow in _workflows) {
          await _db.insertWorkflow(workflow.toMap());
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get demo workflows
  List<Workflow> _getDemoWorkflows() {
    return [
      Workflow(
        id: 'wf_1',
        name: 'Daily Report',
        description: 'Send daily analytics report',
        nodes: [
          WorkflowNode(id: 'n1', type: 'trigger', config: {'cron': '0 9 * * *'}),
          WorkflowNode(id: 'n2', type: 'analytics', config: {}),
          WorkflowNode(id: 'n3', type: 'notify', config: {'channel': 'telegram'}),
        ],
        enabled: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Workflow(
        id: 'wf_2',
        name: 'Lead Nurture',
        description: 'Nurture new leads',
        nodes: [
          WorkflowNode(id: 'n1', type: 'trigger', config: {'event': 'new_lead'}),
          WorkflowNode(id: 'n2', type: 'wait', config: {'duration': 1, 'unit': 'day'}),
          WorkflowNode(id: 'n3', type: 'message', config: {'template': 'welcome'}),
        ],
        enabled: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Workflow(
        id: 'wf_3',
        name: 'Alert Monitor',
        description: 'Monitor system alerts',
        nodes: [
          WorkflowNode(id: 'n1', type: 'trigger', config: {'event': 'alert'}),
          WorkflowNode(id: 'n2', type: 'filter', config: {'severity': 'high'}),
          WorkflowNode(id: 'n3', type: 'notify', config: {'channel': 'slack'}),
        ],
        enabled: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  /// Create workflow
  Future<void> createWorkflow(Workflow workflow) async {
    _workflows.insert(0, workflow);
    notifyListeners();

    await _db.insertWorkflow(workflow.toMap());

    await _sync.queueSync(
      table: 'workflows',
      id: workflow.id,
      data: workflow.toMap(),
      operation: 'insert',
    );
  }

  /// Update workflow
  Future<void> updateWorkflow(Workflow workflow) async {
    final index = _workflows.indexWhere((w) => w.id == workflow.id);
    if (index != -1) {
      _workflows[index] = workflow;
      notifyListeners();

      await _db.updateWorkflow(workflow.id, workflow.toMap());

      await _sync.queueSync(
        table: 'workflows',
        id: workflow.id,
        data: workflow.toMap(),
        operation: 'update',
      );
    }
  }

  /// Delete workflow
  Future<void> deleteWorkflow(String id) async {
    _workflows.removeWhere((w) => w.id == id);
    notifyListeners();

    await _db.deleteWorkflow(id);

    await _sync.queueSync(
      table: 'workflows',
      id: id,
      data: {},
      operation: 'delete',
    );
  }

  /// Toggle workflow
  Future<void> toggleWorkflow(String id) async {
    final index = _workflows.indexWhere((w) => w.id == id);
    if (index != -1) {
      final workflow = _workflows[index];
      _workflows[index] = Workflow(
        id: workflow.id,
        name: workflow.name,
        description: workflow.description,
        nodes: workflow.nodes,
        enabled: !workflow.enabled,
        createdAt: workflow.createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();

      await _db.updateWorkflow(id, _workflows[index].toMap());
    }
  }

  /// Get workflow by ID
  Workflow? getWorkflow(String id) {
    return _workflows.where((w) => w.id == id).firstOrNull;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class Workflow {
  final String id;
  final String name;
  final String? description;
  final List<WorkflowNode> nodes;
  final bool enabled;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Workflow({
    required this.id,
    required this.name,
    this.description,
    required this.nodes,
    required this.enabled,
    required this.createdAt,
    this.updatedAt,
  });

  factory Workflow.fromMap(Map<String, dynamic> map) {
    return Workflow(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      nodes: [], // Would parse from JSON
      enabled: map['enabled'] == 1 || map['enabled'] == true,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'nodes': nodes.map((n) => n.toMap()).toList().toString(),
      'enabled': enabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class WorkflowNode {
  final String id;
  final String type;
  final Map<String, dynamic> config;

  WorkflowNode({
    required this.id,
    required this.type,
    required this.config,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'config': config,
    };
  }
}
