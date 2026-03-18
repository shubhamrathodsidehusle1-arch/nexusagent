/// NexusAgent Tool Policy Service
/// Fixes: Tool profiles can be overridden per-agent
/// Implements: Enforced tool policies that cannot be bypassed

import 'dart:convert';

enum ToolGroup {
  messaging,    // message, react
  data,         // web_search, web_fetch, memory
  filesystem,   // file read/write
  execution,    // exec, run commands
  runtime,      // sessions_spawn, subagents
  automation,   // cron, schedule
  admin,        // config, gateway
}

class ToolPolicy {
  final String name;
  final String description;
  final Map<ToolGroup, ToolGroupPolicy> groupPolicies;
  final Map<String, bool> toolOverrides; // Specific tool overrides
  final bool enforceOnAllAgents; // Cannot be overridden by agents

  ToolPolicy({
    required this.name,
    required this.description,
    required this.groupPolicies,
    this.toolOverrides = const {},
    this.enforceOnAllAgents = true,
  });
}

class ToolGroupPolicy {
  final bool allowed;
  final bool requiresApproval;
  final List<String> allowedPatterns;
  final List<String> blockedPatterns;

  ToolGroupPolicy({
    required this.allowed,
    this.requiresApproval = false,
    this.allowedPatterns = const [],
    this.blockedPatterns = const [],
  });
}

class ToolPermission {
  final String toolName;
  final bool allowed;
  final bool requiresApproval;
  final String? reason;

  ToolPermission({
    required this.toolName,
    required this.allowed,
    this.requiresApproval = false,
    this.reason,
  });
}

class ToolPolicyService {
  static final ToolPolicyService _instance = ToolPolicyService._internal();
  factory ToolPolicyService() => _instance;
  ToolPolicyService._internal();

  ToolPolicy? _globalPolicy;
  final Map<String, ToolPolicy> _agentPolicies = {}; // agentId -> policy

  /// Initialize with default policies
  void initialize() {
    // Set up restrictive global policy
    _globalPolicy = ToolPolicy(
      name: 'restricted',
      description: 'Restrictive policy - blocks dangerous tools',
      groupPolicies: {
        ToolGroup.messaging: ToolGroupPolicy(allowed: true, requiresApproval: true),
        ToolGroup.data: ToolGroupPolicy(allowed: true),
        ToolGroup.filesystem: ToolGroupPolicy(allowed: true, requiresApproval: true),
        ToolGroup.execution: ToolGroupPolicy(allowed: false),
        ToolGroup.runtime: ToolGroupPolicy(allowed: false),
        ToolGroup.automation: ToolGroupPolicy(allowed: false),
        ToolGroup.admin: ToolGroupPolicy(allowed: false),
      },
      enforceOnAllAgents: true,
    );
    
    print('Tool policy service initialized with restricted policy');
  }

  /// Set global policy (cannot be overridden)
  void setGlobalPolicy(ToolPolicy policy) {
    _globalPolicy = policy;
  }

  /// Set agent-specific policy
  void setAgentPolicy(String agentId, ToolPolicy policy) {
    _agentPolicies[agentId] = policy;
  }

  /// Check if tool is allowed for agent
  ToolPermission checkTool(String agentId, String toolName, {Map<String, dynamic>? params}) {
    // Start with global policy
    ToolPolicy policy = _globalPolicy ?? _getDefaultPolicy();
    
    // Agent policy can only be MORE restrictive, not less
    final agentPolicy = _agentPolicies[agentId];
    if (agentPolicy != null && !policy.enforceOnAllAgents) {
      policy = agentPolicy;
    }

    // Check tool-specific override first
    if (policy.toolOverrides.containsKey(toolName)) {
      final allowed = policy.toolOverrides[toolName]!;
      return ToolPermission(
        toolName: toolName,
        allowed: allowed,
        reason: allowed ? 'Allowed by policy' : 'Blocked by tool override',
      );
    }

    // Get tool's group
    final group = _getToolGroup(toolName);
    final groupPolicy = policy.groupPolicies[group];

    if (groupPolicy == null) {
      return ToolPermission(
        toolName: toolName,
        allowed: false,
        reason: 'Unknown tool group',
      );
    }

    // Check if group allows this tool
    if (!groupPolicy.allowed) {
      return ToolPermission(
        toolName: toolName,
        allowed: false,
        reason: 'Tool group ${group.name} is not allowed',
      );
    }

    // Check patterns
    final toolArgs = params?.toString() ?? '';
    
    // Check blocked patterns
    for (final pattern in groupPolicy.blockedPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(toolArgs)) {
        return ToolPermission(
          toolName: toolName,
          allowed: false,
          reason: 'Tool argument matches blocked pattern: $pattern',
        );
      }
    }

    // Check allowed patterns (if specified)
    if (groupPolicy.allowedPatterns.isNotEmpty) {
      bool matches = false;
      for (final pattern in groupPolicy.allowedPatterns) {
        if (RegExp(pattern, caseSensitive: false).hasMatch(toolArgs)) {
          matches = true;
          break;
        }
      }
      
      if (!matches && toolArgs.isNotEmpty) {
        return ToolPermission(
          toolName: toolName,
          allowed: false,
          reason: 'Tool arguments do not match allowed patterns',
        );
      }
    }

    return ToolPermission(
      toolName: toolName,
      allowed: true,
      requiresApproval: groupPolicy.requiresApproval,
    );
  }

  /// Check if tool requires approval
  bool requiresApproval(String agentId, String toolName) {
    final permission = checkTool(agentId, toolName);
    return permission.requiresApproval;
  }

  /// Get policy for agent
  ToolPolicy? getAgentPolicy(String agentId) {
    return _agentPolicies[agentId];
  }

  /// Get global policy
  ToolPolicy? getGlobalPolicy() {
    return _globalPolicy;
  }

  ToolGroup _getToolGroup(String toolName) {
    switch (toolName) {
      case 'message':
      case 'react':
      case 'send':
        return ToolGroup.messaging;
      case 'web_search':
      case 'web_fetch':
      case 'memory':
        return ToolGroup.data;
      case 'file':
      case 'read':
      case 'write':
        return ToolGroup.filesystem;
      case 'exec':
      case 'run':
        return ToolGroup.execution;
      case 'sessions_spawn':
      case 'subagents':
        return ToolGroup.runtime;
      case 'cron':
      case 'schedule':
        return ToolGroup.automation;
      case 'gateway':
      case 'config':
        return ToolGroup.admin;
      default:
        return ToolGroup.data;
    }
  }

  ToolPolicy _getDefaultPolicy() {
    return ToolPolicy(
      name: 'default',
      description: 'Default restrictive policy',
      groupPolicies: {
        ToolGroup.messaging: ToolGroupPolicy(allowed: true),
        ToolGroup.data: ToolGroupPolicy(allowed: true),
        ToolGroup.filesystem: ToolGroupPolicy(allowed: false),
        ToolGroup.execution: ToolGroupPolicy(allowed: false),
        ToolGroup.runtime: ToolGroupPolicy(allowed: false),
        ToolGroup.automation: ToolGroupPolicy(allowed: false),
        ToolGroup.admin: ToolGroupPolicy(allowed: false),
      },
      enforceOnAllAgents: false,
    );
  }

  /// List available policies
  List<String> listPolicies() {
    final policies = <String>['global'];
    policies.addAll(_agentPolicies.keys);
    return policies;
  }
}
