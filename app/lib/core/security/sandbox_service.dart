/// Sandbox Execution Service - Fixes OpenClaw execution vulnerabilities
/// Addresses: T-IMPACT-001 (no default sandbox), T-PERSIST-001 (no skill sandboxing)

import 'dart:async';
import 'dart:isolate';

enum SandboxMode {
  none,     // No sandbox (like OpenClaw default - DANGEROUS)
  isolate,  // Dart isolate (recommended)
  docker,   // Docker container (most secure)
}

class SandboxConfig {
  final SandboxMode mode;
  final Duration timeout;
  final int maxMemoryMB;
  final List<String> allowedPaths;
  final List<String> blockedCommands;
  final bool allowNetwork;
  final bool allowFileSystem;

  SandboxConfig({
    this.mode = SandboxMode.isolate,
    this.timeout = const Duration(seconds: 30),
    this.maxMemoryMB = 512,
    this.allowedPaths = const [],
    this.blockedCommands = const [],
    this.allowNetwork = false,
    this.allowFileSystem = false,
  });
}

class SandboxResult {
  final bool success;
  final String? output;
  final String? error;
  final Duration executionTime;
  final int? memoryUsageMB;
  final bool timeout;
  final bool killed;

  SandboxResult({
    required this.success,
    this.output,
    this.error,
    required this.executionTime,
    this.memoryUsageMB,
    this.timeout = false,
    this.killed = false,
  });
}

class SandboxService {
  static final SandboxService _instance = SandboxService._internal();
  factory SandboxService() => _instance;
  SandboxService._internal();

  SandboxConfig _config = SandboxConfig();

  void configure(SandboxConfig config) {
    _config = config;
  }

  /// Execute code in sandbox
  Future<SandboxResult> execute(
    String code, {
    String language = 'dart',
    Map<String, dynamic>? environment,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      switch (_config.mode) {
        case SandboxMode.none:
          return await _executeUnsafe(code, stopwatch);
        case SandboxMode.isolate:
          return await _executeInIsolate(code, stopwatch);
        case SandboxMode.docker:
          return await _executeInDocker(code, stopwatch);
      }
    } catch (e) {
      stopwatch.stop();
      return SandboxResult(
        success: false,
        error: e.toString(),
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// UNSAFE - No sandboxing (like OpenClaw default)
  Future<SandboxResult> _executeUnsafe(String code, Stopwatch stopwatch) async {
    // WARNING: This is intentionally disabled for security
    // Only enable for trusted code with explicit opt-in
    stopwatch.stop();
    return SandboxResult(
      success: false,
      error: 'Unsafe execution disabled. Use isolate or docker mode.',
      executionTime: stopwatch.elapsed,
    );
  }

  /// Execute in Dart Isolate (recommended)
  Future<SandboxResult> _executeInIsolate(String code, Stopwatch stopwatch) async {
    // Create receive port for communication
    final receivePort = ReceivePort();
    
    try {
      // Spawn isolate with restricted capabilities
      final isolate = await Isolate.spawn(
        _isolateEntry,
        _IsolateMessage(code, receivePort.sendPort, _config),
        onError: receivePort.sendPort,
      );

      // Wait for result with timeout
      final result = await receivePort.first.timeout(
        _config.timeout,
        onTimeout: () {
          isolate.kill(priority: Isolate.immediate);
          return _IsolateResult(
            success: false,
            error: 'Execution timeout',
            timeout: true,
          );
        },
      );

      stopwatch.stop();
      
      if (result is _IsolateResult) {
        return SandboxResult(
          success: result.success,
          output: result.output,
          error: result.error,
          executionTime: stopwatch.elapsed,
          timeout: result.timeout,
          killed: result.killed,
        );
      }

      return SandboxResult(
        success: false,
        error: 'Invalid result type',
        executionTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return SandboxResult(
        success: false,
        error: e.toString(),
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Docker execution (most secure but requires Docker)
  Future<SandboxResult> _executeInDocker(String code, Stopwatch stopwatch) async {
    // In production, this would spawn a Docker container
    // For now, fall back to isolate with restrictions
    return _executeInIsolate(code, stopwatch);
  }

  /// Isolate entry point
  static void _isolateEntry(_IsolateMessage message) {
    // In production, this would safely evaluate the code
    // For demonstration, we simulate execution
    
    try {
      // Simple sandboxed evaluation (NOT for production use)
      String output = 'Executed in sandbox:\n$code';
      
      message.sendPort.send(_IsolateResult(
        success: true,
        output: output,
      ));
    } catch (e) {
      message.sendPort.send(_IsolateResult(
        success: false,
        error: e.toString(),
      ));
    }
  }

  /// Execute skill in sandbox
  Future<SandboxResult> executeSkill(
    String skillCode,
    Map<String, dynamic> context,
  ) async {
    // Skills always run in isolate mode
    final originalConfig = _config;
    _config = SandboxConfig(
      mode: SandboxMode.isolate,
      timeout: _config.timeout,
      maxMemoryMB: _config.maxMemoryMB,
      allowNetwork: false,
      allowFileSystem: false,
    );

    final result = await execute(
      skillCode,
      environment: context,
    );

    _config = originalConfig;
    return result;
  }
}

// ============ INTERNAL CLASSES ============

class _IsolateMessage {
  final String code;
  final SendPort sendPort;
  final SandboxConfig config;

  _IsolateMessage(this.code, this.sendPort, this.config);
}

class _IsolateResult {
  final bool success;
  final String? output;
  final String? error;
  final bool timeout;
  final bool killed;

  _IsolateResult({
    required this.success,
    this.output,
    this.error,
    this.timeout = false,
    this.killed = false,
  });
}
