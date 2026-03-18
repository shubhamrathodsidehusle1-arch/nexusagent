/// NexusAgent Multi-Agent Router
/// Routes messages to appropriate agents based on rules

import 'dart:async';

enum RoutingStrategy {
  roundRobin,
  leastLoaded,
  skillMatch,
  explicit,
  groupAware,
}

class RoutingRule {
  final String id;
  final String name;
  final RoutingCondition condition;
  final String targetAgentId;
  final int priority;

  RoutingRule({
    required this.id,
    required this.name,
    required this.condition,
    required this.targetAgentId,
    this.priority = 0,
  });
}

class RoutingCondition {
  final String? channel;
  final String? senderContains;
  final String? messageContains;
  final String? messageRegex;
  final bool isGroupChat;
  final Map<String, String>? custom;

  RoutingCondition({
    this.channel,
    this.senderContains,
    this.messageContains,
    this.messageRegex,
    this.isGroupChat = false,
    this.custom,
  });

  bool matches(RoutingContext context) {
    // Check channel
    if (channel != null && context.channel != channel) {
      return false;
    }

    // Check sender
    if (senderContains != null && 
        !context.sender.toLowerCase().contains(senderContains!.toLowerCase())) {
      return false;
    }

    // Check message content
    if (messageContains != null && 
        !context.message.toLowerCase().contains(messageContains!.toLowerCase())) {
      return false;
    }

    // Check regex
    if (messageRegex != null && 
        !RegExp(messageRegex!).hasMatch(context.message)) {
      return false;
    }

    // Check group chat
    if (isGroupChat && !context.isGroupChat) {
      return false;
    }

    return true;
  }
}

class RoutingContext {
  final String channel;
  final String sender;
  final String senderName;
  final String message;
  final bool isGroupChat;
  final String? groupId;
  final Map<String, dynamic>? metadata;

  RoutingContext({
    required this.channel,
    required this.sender,
    required this.senderName,
    required this.message,
    this.isGroupChat = false,
    this.groupId,
    this.metadata,
  });
}

class AgentLoad {
  final String agentId;
  final int activeSessions;
  final DateTime lastUsed;

  AgentLoad({
    required this.agentId,
    required this.activeSessions,
    required this.lastUsed,
  });
}

class Router {
  static final Router _instance = Router._internal();
  factory Router() => _instance;
  Router._internal();

  final List<RoutingRule> _rules = [];
  final Map<String, List<String>> _channelAgents = {}; // channel -> agentIds
  final Map<String, AgentLoad> _agentLoads = {};
  RoutingStrategy _defaultStrategy = RoutingStrategy.leastLoaded;

  /// Set default strategy
  void setDefaultStrategy(RoutingStrategy strategy) {
    _defaultStrategy = strategy;
  }

  /// Add routing rule
  void addRule(RoutingRule rule) {
    _rules.add(rule);
    _sortRules();
  }

  /// Remove rule
  void removeRule(String ruleId) {
    _rules.removeWhere((r) => r.id == ruleId);
  }

  /// Update rules
  void updateRules(List<RoutingRule> rules) {
    _rules.clear();
    _rules.addAll(rules);
    _sortRules();
  }

  void _sortRules() {
    _rules.sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// Register agent for channel
  void registerAgent(String channel, String agentId) {
    _channelAgents[channel] ??= [];
    if (!_channelAgents[channel]!.contains(agentId)) {
      _channelAgents[channel]!.add(agentId);
    }
  }

  /// Unregister agent from channel
  void unregisterAgent(String channel, String agentId) {
    _channelAgents[channel]?.remove(agentId);
  }

  /// Update agent load
  void updateAgentLoad(String agentId, int activeSessions) {
    _agentLoads[agentId] = AgentLoad(
      agentId: agentId,
      activeSessions: activeSessions,
      lastUsed: DateTime.now(),
    );
  }

  /// Route message to agent
  String? route(RoutingContext context) {
    // Check explicit rules first
    for (final rule in _rules) {
      if (rule.condition.matches(context)) {
        return rule.targetAgentId;
      }
    }

    // Use default strategy
    return _routeWithStrategy(context);
  }

  String? _routeWithStrategy(RoutingContext context) {
    final agents = _channelAgents[context.channel];
    if (agents == null || agents.isEmpty) {
      return null;
    }

    switch (_defaultStrategy) {
      case RoutingStrategy.roundRobin:
        return _roundRobin(context.channel, agents);
      case RoutingStrategy.leastLoaded:
        return _leastLoaded(agents);
      case RoutingStrategy.skillMatch:
        return _skillMatch(context.message, agents);
      case RoutingStrategy.explicit:
        return agents.first;
      case RoutingStrategy.groupAware:
        return _groupAware(context, agents);
    }
  }

  String _roundRobin(String channel, List<String> agents) {
    // Simple round-robin based on message count
    return agents[DateTime.now().millisecondsSinceEpoch % agents.length];
  }

  String _leastLoaded(List<String> agents) {
    AgentLoad? minLoad;
    String? minAgent;

    for (final agentId in agents) {
      final load = _agentLoads[agentId];
      if (minLoad == null || (load?.activeSessions ?? 0) < minLoad.activeSessions) {
        minLoad = load;
        minAgent = agentId;
      }
    }

    return minAgent ?? agents.first;
  }

  String _skillMatch(String message, List<String> agents) {
    // In production, would check agent skills against message
    // For now, use least loaded
    return _leastLoaded(agents);
  }

  String? _groupAware(RoutingContext context, List<String> agents) {
    if (context.isGroupChat) {
      // Use dedicated group agent if available
      for (final agent in agents) {
        if (agent.contains('group')) {
          return agent;
        }
      }
    }
    return _leastLoaded(agents);
  }

  /// Get routing info
  Map<String, dynamic> getRoutingInfo() {
    return {
      'rules': _rules.map((r) => {
        'id': r.id,
        'name': r.name,
        'priority': r.priority,
      }).toList(),
      'channels': _channelAgents.map((k, v) => MapEntry(k, v.length)),
      'strategy': _defaultStrategy.name,
    };
  }
}
