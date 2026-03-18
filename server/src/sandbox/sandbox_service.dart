/// NexusAgent Sandbox Configuration
/// Docker-based session isolation

enum SandboxMode {
  off,      // No sandbox
  nonMain,  // Only non-default agents
  all,      // All agents
}

enum SandboxScope {
  session,  // Each session gets own container
  agent,    // Each agent shares container
  shared,   // Shared container
}

class SandboxConfig {
  final SandboxMode mode;
  final SandboxScope scope;
  final String? image;
  final String? networkMode;
  final int maxMemoryMB;
  final int maxCpuPercent;
  final List<String> allowedPaths;
  final List<String> blockedCommands;

  SandboxConfig({
    this.mode = SandboxMode.nonMain,
    this.scope = SandboxScope.session,
    this.image,
    this.networkMode = 'bridge',
    this.maxMemoryMB = 512,
    this.maxCpuPercent = 50,
    this.allowedPaths = const [],
    this.blockedCommands = const [],
  });
}

class SandboxSession {
  final String id;
  final String agentId;
  final String containerId;
  final DateTime startedAt;
  final Map<String, dynamic> resources;

  SandboxSession({
    required this.id,
    required this.agentId,
    required this.containerId,
    required this.startedAt,
    this.resources = const {},
  });
}

class SandboxService {
  static final SandboxService _instance = SandboxService._internal();
  factory SandboxService() => _instance;
  SandboxService._internal();

  SandboxConfig _config = SandboxConfig();
  final Map<String, SandboxSession> _activeSessions = {};

  Function(String sessionId)? onSessionStart;
  Function(String sessionId)? onSessionEnd;

  /// Initialize
  void initialize(SandboxConfig config) {
    _config = config;
    print('Sandbox service initialized: ${config.mode.name}');
  }

  /// Should use sandbox
  bool shouldUseSandbox(String agentId, {bool isMainAgent = false}) {
    switch (_config.mode) {
      case SandboxMode.off:
        return false;
      case SandboxMode.nonMain:
        return !isMainAgent;
      case SandboxMode.all:
        return true;
    }
  }

  /// Start sandbox session
  Future<SandboxSession?> startSession(String sessionId, String agentId) async {
    if (!shouldUseSandbox(agentId)) return null;

    // In production, would create Docker container
    final session = SandboxSession(
      id: sessionId,
      agentId: agentId,
      containerId: 'nexusagent-${DateTime.now().millisecondsSinceEpoch}',
      startedAt: DateTime.now(),
    );

    _activeSessions[sessionId] = session;
    onSessionStart?.call(sessionId);

    return session;
  }

  /// End sandbox session
  Future<void> endSession(String sessionId) async {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    // In production, would stop Docker container
    _activeSessions.remove(sessionId);
    onSessionEnd?.call(sessionId);
  }

  /// Get session
  SandboxSession? getSession(String sessionId) => _activeSessions[sessionId];

  /// List active sessions
  List<SandboxSession> getActiveSessions() => _activeSessions.values.toList();

  /// Check if session is sandboxed
  bool isSandboxed(String sessionId) => _activeSessions.containsKey(sessionId);

  /// Get config
  SandboxConfig get config => _config;
}
