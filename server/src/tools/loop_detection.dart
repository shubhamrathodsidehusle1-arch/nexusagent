/// NexusAgent Loop Detection Service
/// Detects and prevents tool-call loops

class LoopDetectionConfig {
  final bool enabled;
  final int warningThreshold;
  final int criticalThreshold;
  final int globalCircuitBreakerThreshold;
  final int historySize;
  final bool detectGenericRepeat;
  final bool detectPollNoProgress;
  final bool detectPingPong;

  LoopDetectionConfig({
    this.enabled = true,
    this.warningThreshold = 10,
    this.criticalThreshold = 20,
    this.globalCircuitBreakerThreshold = 30,
    this.historySize = 30,
    this.detectGenericRepeat = true,
    this.detectPollNoProgress = true,
    this.detectPingPong = true,
  });
}

enum LoopType {
  none,
  genericRepeat,
  pollNoProgress,
  pingPong,
}

class LoopDetectionResult {
  final LoopType type;
  final int count;
  final String action; // warn, block, circuit_break

  LoopDetectionResult({
    required this.type,
    required this.count,
    required this.action,
  });
}

class ToolCall {
  final String toolName;
  final Map<String, dynamic> params;
  final String? result;
  final DateTime timestamp;

  ToolCall({
    required this.toolName,
    required this.params,
    this.result,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get signature => '$toolName:${_hashParams(params)}';

  String _hashParams(Map<String, dynamic> params) {
    return params.entries.map((e) => '${e.key}=${e.value}').join(',');
  }
}

class LoopDetectionService {
  static final LoopDetectionService _instance = LoopDetectionService._internal();
  factory LoopDetectionService() => _instance;
  LoopDetectionService._internal();

  LoopDetectionConfig _config = LoopDetectionConfig();
  final Map<String, List<ToolCall>> _agentHistory = {}; // agentId -> history
  int _globalCount = 0;

  /// Initialize
  void initialize(LoopDetectionConfig config) {
    _config = config;
    print('Loop detection initialized: ${config.enabled}');
  }

  /// Record tool call
  LoopDetectionResult? recordCall(String agentId, String toolName, Map<String, dynamic> params, String? result) {
    if (!_config.enabled) return null;

    // Get or create history
    _agentHistory[agentId] ??= [];
    final history = _agentHistory[agentId]!;

    // Add new call
    final call = ToolCall(
      toolName: toolName,
      params: params,
      result: result,
    );
    history.add(call);

    // Trim history
    while (history.length > _config.historySize) {
      history.removeAt(0);
    }

    // Increment global counter
    _globalCount++;

    // Check for loops
    return _detectLoop(agentId, toolName, params, result);
  }

  LoopDetectionResult? _detectLoop(String agentId, String toolName, Map<String, dynamic> params, String? result) {
    final history = _agentHistory[agentId] ?? [];

    if (history.length < 2) return null;

    // Check generic repeat
    if (_config.detectGenericRepeat) {
      final repeatCount = _checkGenericRepeat(history, toolName, params);
      if (repeatCount >= _config.warningThreshold) {
        return LoopDetectionResult(
          type: LoopType.genericRepeat,
          count: repeatCount,
          action: repeatCount >= _config.criticalThreshold ? 'block' : 'warn',
        );
      }
    }

    // Check poll no progress
    if (_config.detectPollNoProgress) {
      final pollCount = _checkPollNoProgress(history);
      if (pollCount >= _config.warningThreshold) {
        return LoopDetectionResult(
          type: LoopType.pollNoProgress,
          count: pollCount,
          action: pollCount >= _config.criticalThreshold ? 'block' : 'warn',
        );
      }
    }

    // Check ping pong
    if (_config.detectPingPong) {
      final pingPong = _checkPingPong(history);
      if (pingPong >= _config.warningThreshold) {
        return LoopDetectionResult(
          type: LoopType.pingPong,
          count: pingPong,
          action: pingPong >= _config.criticalThreshold ? 'block' : 'warn',
        );
      }
    }

    // Check global circuit breaker
    if (_globalCount >= _config.globalCircuitBreakerThreshold) {
      return LoopDetectionResult(
        type: LoopType.none,
        count: _globalCount,
        action: 'circuit_break',
      );
    }

    return null;
  }

  int _checkGenericRepeat(List<ToolCall> history, String toolName, Map<String, dynamic> params) {
    if (history.isEmpty) return 0;

    final lastCall = history.last;
    if (lastCall.toolName != toolName) return 0;

    int count = 1;
    for (int i = history.length - 2; i >= 0; i--) {
      if (history[i].toolName == toolName && 
          history[i].signature == lastCall.signature) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  int _checkPollNoProgress(List<ToolCall> history) {
    if (history.length < 3) return 0;

    // Look for poll-like tools with same output
    final pollTools = ['process', 'poll', 'sessions_poll'];
    int count = 0;
    String? lastResult;

    for (int i = history.length - 1; i >= 0; i--) {
      final call = history[i];
      if (pollTools.contains(call.toolName)) {
        if (lastResult != null && call.result == lastResult) {
          count++;
        } else if (lastResult == null) {
          count = 1;
        }
        lastResult = call.result;
      }
    }
    return count;
  }

  int _checkPingPong(List<ToolCall> history) {
    if (history.length < 4) return 0;

    // Look for alternating A/B pattern
    int count = 0;
    String? lastTool;

    for (int i = history.length - 1; i >= 0; i--) {
      final tool = history[i].toolName;
      if (lastTool != null && lastTool != tool) {
        count++;
      } else if (lastTool == null) {
        count = 1;
      }
      lastTool = tool;
    }
    return count ~/ 2;
  }

  /// Get history for agent
  List<ToolCall> getHistory(String agentId) {
    return _agentHistory[agentId] ?? [];
  }

  /// Clear history for agent
  void clearHistory(String agentId) {
    _agentHistory.remove(agentId);
  }

  /// Reset global counter
  void resetGlobal() {
    _globalCount = 0;
  }
}
