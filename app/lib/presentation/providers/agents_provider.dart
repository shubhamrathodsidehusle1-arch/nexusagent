/// NexusAgent Agents Provider - Connected
/// Real agent management

import 'package:flutter/material.dart';
import '../../data/services/database_service.dart';
import '../../data/services/api_service.dart';
import '../../data/services/sync_service.dart';

class AgentsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final ApiService _api = ApiService();
  final SyncService _sync = SyncService();

  List<Agent> _agents = [];
  Agent? _selectedAgent;
  bool _isLoading = false;
  String? _error;

  List<Agent> get agents => _agents;
  Agent? get selectedAgent => _selectedAgent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load agents if authenticated
  Future<void> loadIfAuthenticated(bool isAuthenticated) async {
    if (isAuthenticated) {
      await loadAgents();
    }
  }

  /// Load all agents
  Future<void> loadAgents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try local database first
      final dbAgents = await _db.getAgents();
      
      if (dbAgents.isNotEmpty) {
        _agents = dbAgents.map((a) => Agent.fromMap(a)).toList();
      } else {
        // Load demo agents
        _agents = _getDemoAgents();
        
        // Save to database
        for (final agent in _agents) {
          await _db.insertAgent(agent.toMap());
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

  /// Get demo agents
  List<Agent> _getDemoAgents() {
    return [
      Agent(
        id: 'agent_1',
        name: 'IVA',
        description: 'Intelligent Venture Architect - Strategic AI',
        model: 'claude-3-opus',
        status: 'active',
        tools: ['web_search', 'web_fetch', 'memory', 'exec'],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Agent(
        id: 'agent_2',
        name: 'Sales Agent',
        description: 'Outbound sales and lead generation',
        model: 'gpt-4',
        status: 'active',
        tools: ['message', 'web_search', 'exec'],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Agent(
        id: 'agent_3',
        name: 'Support Agent',
        description: 'Customer support automation',
        model: 'claude-3-sonnet',
        status: 'paused',
        tools: ['message', 'memory'],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  /// Create agent
  Future<void> createAgent(Agent agent) async {
    _agents.insert(0, agent);
    notifyListeners();

    // Save to local database
    await _db.insertAgent(agent.toMap());

    // Queue for sync
    await _sync.queueSync(
      table: 'agents',
      id: agent.id,
      data: agent.toMap(),
      operation: 'insert',
    );
  }

  /// Update agent
  Future<void> updateAgent(Agent agent) async {
    final index = _agents.indexWhere((a) => a.id == agent.id);
    if (index != -1) {
      _agents[index] = agent;
      notifyListeners();

      // Update in database
      await _db.updateAgent(agent.id, agent.toMap());

      // Queue for sync
      await _sync.queueSync(
        table: 'agents',
        id: agent.id,
        data: agent.toMap(),
        operation: 'update',
      );
    }
  }

  /// Delete agent
  Future<void> deleteAgent(String id) async {
    _agents.removeWhere((a) => a.id == id);
    notifyListeners();

    // Delete from database
    await _db.deleteAgent(id);

    // Queue for sync
    await _sync.queueSync(
      table: 'agents',
      id: id,
      data: {},
      operation: 'delete',
    );
  }

  /// Select agent
  void selectAgent(Agent? agent) {
    _selectedAgent = agent;
    notifyListeners();
  }

  /// Run agent
  Future<String?> runAgent(String agentId, String prompt) async {
    try {
      final response = await _api.runAgent(agentId, prompt);
      return response['output'];
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class Agent {
  final String id;
  final String name;
  final String? description;
  final String? model;
  final List<String> tools;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Agent({
    required this.id,
    required this.name,
    this.description,
    this.model,
    this.tools = const [],
    this.status = 'active',
    required this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';

  factory Agent.fromMap(Map<String, dynamic> map) {
    return Agent(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      model: map['model'],
      tools: map['tools'] != null 
          ? List<String>.from(map['tools']) 
          : [],
      status: map['status'] ?? 'active',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at']) 
          : null,
    );
  }

  factory Agent.fromApi(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      model: json['model'],
      tools: json['tools'] != null 
          ? List<String>.from(json['tools']) 
          : [],
      status: json['status'] ?? 'active',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'model': model,
      'tools': tools,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
