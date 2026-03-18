/// NexusAgent Provider-Specific Tool Policy
/// Restrict tools per model provider

class ProviderToolPolicy {
  final String provider; // e.g., "openai", "google-antigravity"
  final String? model;   // e.g., "gpt-5.2", optional
  final List<String> allow;
  final List<String> deny;
  final String? profile; // minimal, messaging, coding, full

  ProviderToolPolicy({
    required this.provider,
    this.model,
    this.allow = const [],
    this.deny = const [],
    this.profile,
  });

  bool matches(String provider, String? model) {
    if (this.model != null && model != this.model) return false;
    return this.provider == provider || this.provider == '*';
  }
}

class ProviderPolicyService {
  static final ProviderPolicyService _instance = ProviderPolicyService._internal();
  factory ProviderPolicyService() => _instance;
  ProviderPolicyService._internal();

  final List<ProviderToolPolicy> _policies = [];

  /// Add provider policy
  void addPolicy(ProviderToolPolicy policy) {
    _policies.add(policy);
  }

  /// Get effective tool list for provider
  List<String> getEffectiveTools(
    String provider, 
    String? model,
    List<String> baseTools,
  ) {
    // Find matching policies (most specific first)
    final matches = _policies.where((p) => p.matches(provider, model)).toList();
    
    if (matches.isEmpty) return baseTools;

    // Sort by specificity (model-specific first)
    matches.sort((a, b) {
      if (a.model != null && b.model == null) return -1;
      if (a.model == null && b.model != null) return 1;
      return 0;
    });

    // Apply most specific policy
    final policy = matches.first;
    List<String> result = List.from(baseTools);

    // Apply profile
    if (policy.profile != null) {
      result = _getProfileTools(policy.profile!);
    }

    // Apply allow
    if (policy.allow.isNotEmpty) {
      result = result.where((t) => policy.allow.contains(t) || policy.allow.contains('*')).toList();
    }

    // Apply deny
    for (final deny in policy.deny) {
      if (deny.startsWith('group:')) {
        result.removeWhere((t) => _getToolGroup(t) == deny.substring(6));
      } else {
        result.remove(deny);
      }
    }

    return result;
  }

  List<String> _getProfileTools(String profile) {
    switch (profile) {
      case 'minimal':
        return ['session_status'];
      case 'messaging':
        return ['message', 'react', 'sessions_list', 'sessions_history', 'sessions_send', 'session_status'];
      case 'coding':
        return ['group:fs', 'group:runtime', 'group:sessions', 'group:memory', 'image'];
      case 'full':
        return [];
      default:
        return [];
    }
  }

  String _getToolGroup(String toolName) {
    switch (toolName) {
      case 'message':
      case 'react':
      case 'send':
        return 'messaging';
      case 'web_search':
      case 'web_fetch':
      case 'memory':
      case 'memory_search':
      case 'memory_get':
        return 'web';
      case 'file':
      case 'read':
      case 'write':
      case 'edit':
        return 'fs';
      case 'exec':
      case 'run':
        return 'runtime';
      case 'sessions_list':
      case 'sessions_history':
      case 'sessions_send':
      case 'sessions_spawn':
      case 'session_status':
        return 'sessions';
      case 'browser':
      case 'canvas':
        return 'ui';
      case 'cron':
      case 'schedule':
        return 'automation';
      case 'nodes':
      case 'node_invoke':
        return 'nodes';
      default:
        return 'unknown';
    }
  }

  /// List policies
  List<ProviderToolPolicy> get policies => _policies;

  /// Remove policy
  void removePolicy(String provider, {String? model}) {
    _policies.removeWhere((p) => p.provider == provider && p.model == model);
  }
}
