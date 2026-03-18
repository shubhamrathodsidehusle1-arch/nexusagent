/// NexusAgent Runtime - Core agent execution engine
/// Replaces OpenClaw's agent runtime with security hardening

import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'gateway/gateway.dart';
import 'tools/tool_registry.dart';
import 'security/input_validator.dart';

enum AgentStatus {
  idle,
  running,
  paused,
  error,
}

class AgentConfig {
  final String id;
  final String name;
  final String? description;
  final List<String> allowedTools;
  final Map<String, dynamic> systemPrompt;
  final int maxTokensPerRun;
  final Duration timeout;

  AgentConfig({
    required this.id,
    required this.name,
    this.description,
    this.allowedTools = const [],
    this.systemPrompt = const {},
    this.maxTokensPerRun = 4000,
    this.timeout = const Duration(minutes: 5),
  });
}

class AgentRun {
  final String id;
  final String agentId;
  final String sessionId;
  final String input;
  String? output;
  int tokensUsed;
  AgentStatus status;
  final List<RunStep> steps;
  final DateTime startedAt;
  DateTime? endedAt;
  String? error;

  AgentRun({
    required this.id,
    required this.agentId,
    required this.sessionId,
    required this.input,
    this.output,
    this.tokensUsed = 0,
    this.status = AgentStatus.idle,
    List<RunStep>? steps,
    DateTime? startedAt,
    this.endedAt,
    this.error,
  })  : steps = steps ?? [],
        startedAt = startedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'agentId': agentId,
    'sessionId': sessionId,
    'input': input,
    'output': output,
    'tokensUsed': tokensUsed,
    'status': status.name,
    'steps': steps.map((s) => s.toJson()).toList(),
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'error': error,
  };
}

class RunStep {
  final int order;
  final String action;
  final String? result;
  final bool success;
  final int? durationMs;

  RunStep({
    required this.order,
    required this.action,
    this.result,
    this.success = true,
    this.durationMs,
  });

  Map<String, dynamic> toJson() => {
    'order': order,
    'action': action,
    'result': result,
    'success': success,
    'durationMs': durationMs,
  };
}

class AgentRuntime {
  static final AgentRuntime _instance = AgentRuntime._internal();
  factory AgentRuntime() => _instance;
  AgentRuntime._internal();

  final Map<String, AgentConfig> _agents = {};
  final Map<String, AgentRun> _activeRuns = {};
  final ToolRegistry _tools = ToolRegistry();
  final InputValidator _validator = InputValidator();
  final _uuid = const Uuid();

  // Callbacks
  Function(String runId, RunStep step)? onStepComplete;
  Function(String runId, String output)? onRunComplete;
  Function(String runId, String error)? onRunError;

  /// Initialize runtime
  void initialize() {
    _tools.registerDefaultTools();
    print('NexusAgent Runtime initialized with ${_tools.tools.length} tools');
  }

  /// Register agent
  void registerAgent(AgentConfig config) {
    _agents[config.id] = config;
    print('Agent registered: ${config.name} (${config.id})');
  }

  /// Get agent
  AgentConfig? getAgent(String agentId) {
    return _agents[agentId];
  }

  /// List agents
  List<AgentConfig> listAgents() {
    return _agents.values.toList();
  }

  /// Run agent
  Future<AgentRun> run(String agentId, String sessionId, String input, {Map<String, dynamic>? context}) async {
    final agent = _agents[agentId];
    if (agent == null) {
      throw Exception('Agent not found: $agentId');
    }

    final runId = _uuid.v4();
    final run = AgentRun(
      id: runId,
      agentId: agentId,
      sessionId: sessionId,
      input: input,
      status: AgentStatus.running,
    );

    _activeRuns[runId] = run;

    try {
      // Step 1: Validate input (security)
      final validationResult = _validator.validate(input);
      if (!validationResult.isValid) {
        throw Exception('Input validation failed: ${validationResult.errors.join(", ")}');
      }
      
      run.steps.add(RunStep(
        order: 1,
        action: 'validate_input',
        result: 'Input validation passed',
        success: true,
        durationMs: 1,
      ));

      // Step 2: Build context
      String prompt = _buildPrompt(agent, input, context ?? {});
      
      run.steps.add(RunStep(
        order: 2,
        action: 'build_context',
        result: 'Context built (${prompt.length} chars)',
        success: true,
        durationMs: 2,
      ));

      // Step 3: Decide on tool usage (simplified - in production would call LLM)
      // For now, we'll simulate tool selection
      List<String> toolsToUse = _decideTools(agent, input);
      
      StringBuffer outputBuffer = StringBuffer();

      // Step 4: Execute tools
      int stepNum = 3;
      for (final toolName in toolsToUse) {
        if (!agent.allowedTools.contains(toolName) && agent.allowedTools.isNotEmpty) {
          continue; // Skip disallowed tools
        }

        final stopwatch = Stopwatch()..start();
        final result = await _tools.execute(toolName, {
          'input': input,
          'context': context,
        });
        stopwatch.stop();

        final step = RunStep(
          order: stepNum++,
          action: 'execute_tool:$toolName',
          result: result.success ? result.output ?? 'Success' : result.error ?? 'Error',
          success: result.success,
          durationMs: stopwatch.elapsedMilliseconds,
        );
        
        run.steps.add(step);
        onStepComplete?.call(runId, step);

        if (result.success && result.output != null) {
          outputBuffer.writeln(result.output);
        }
      }

      // Step 5: Generate final output
      if (outputBuffer.isEmpty) {
        outputBuffer.write('Processed: $input');
      }
      
      run.output = outputBuffer.toString();
      run.tokensUsed = (run.input.length + (run.output?.length ?? 0)) ~/ 4; // Rough estimate
      run.status = AgentStatus.idle;
      run.endedAt = DateTime.now();

      run.steps.add(RunStep(
        order: stepNum,
        action: 'generate_output',
        result: 'Output generated (${run.tokensUsed} tokens)',
        success: true,
        durationMs: 10,
      ));

      onRunComplete?.call(runId, run.output!);

    } catch (e) {
      run.status = AgentStatus.error;
      run.error = e.toString();
      run.endedAt = DateTime.now();
      onRunError?.call(runId, e.toString());
    }

    _activeRuns.remove(runId);
    return run;
  }

  /// Get active run
  AgentRun? getRun(String runId) {
    return _activeRuns[runId];
  }

  /// Build prompt
  String _buildPrompt(AgentConfig agent, String input, Map<String, dynamic> context) {
    final systemPrompt = agent.systemPrompt['content'] ?? 'You are a helpful AI assistant.';
    return '''
System: $systemPrompt

Context: ${jsonEncode(context)}

User: $input

Remember: Follow security guidelines and validate all inputs.
''';
  }

  /// Decide which tools to use (simplified)
  List<String> _decideTools(AgentConfig agent, String input) {
    List<String> tools = [];
    final lower = input.toLowerCase();

    if (lower.contains('search') || lower.contains('find')) {
      tools.add('web_search');
    }
    if (lower.contains('fetch') || lower.contains('get') || lower.contains('http')) {
      tools.add('web_fetch');
    }
    if (lower.contains('file') || lower.contains('read') || lower.contains('write')) {
      tools.add('file');
    }
    if (lower.contains('run') || lower.contains('exec') || lower.contains('command')) {
      tools.add('exec');
    }

    return tools;
  }

  /// Pause agent run
  void pauseRun(String runId) {
    _activeRuns[runId]?.status = AgentStatus.paused;
  }

  /// Resume agent run
  void resumeRun(String runId) {
    _activeRuns[runId]?.status = AgentStatus.running;
  }

  /// Cancel agent run
  void cancelRun(String runId) {
    final run = _activeRuns[runId];
    if (run != null) {
      run.status = AgentStatus.idle;
      run.error = 'Cancelled by user';
      run.endedAt = DateTime.now();
      _activeRuns.remove(runId);
    }
  }

  /// Shutdown
  void shutdown() {
    for (final run in _activeRuns.values) {
      run.status = AgentStatus.idle;
      run.error = 'Runtime shutdown';
      run.endedAt = DateTime.now();
    }
    _activeRuns.clear();
    _agents.clear();
  }
}
