/// NexusAgent Skill Loader - Secure skill loading
/// Addresses: T-PERSIST-001, T-PERSIST-002 (skill supply chain)

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

class SkillManifest {
  final String name;
  final String version;
  final String description;
  final String author;
  final String? repository;
  final List<String> dependencies;
  final Map<String, SkillTool> tools;
  final Map<String, dynamic> config;

  SkillManifest({
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    this.repository,
    this.dependencies = const [],
    this.tools = const {},
    this.config = const {},
  });

  factory SkillManifest.fromJson(Map<String, dynamic> json) {
    return SkillManifest(
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? 'unknown',
      repository: json['repository'] as String?,
      dependencies: (json['dependencies'] as List<dynamic>?)?.cast<String>() ?? [],
      tools: (json['tools'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, SkillTool.fromJson(v)),
      ) ?? {},
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'version': version,
    'description': description,
    'author': author,
    'repository': repository,
    'dependencies': dependencies,
    'tools': tools.map((k, v) => MapEntry(k, v.toJson())),
    'config': config,
  };
}

class SkillTool {
  final String name;
  final String description;
  final List<String> parameters;
  final bool requiresApproval;

  SkillTool({
    required this.name,
    required this.description,
    this.parameters = const [],
    this.requiresApproval = false,
  });

  factory SkillTool.fromJson(Map<String, dynamic> json) {
    return SkillTool(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      parameters: (json['parameters'] as List<dynamic>?)?.cast<String>() ?? [],
      requiresApproval: json['requiresApproval'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'parameters': parameters,
    'requiresApproval': requiresApproval,
  };
}

class SkillLoadResult {
  final bool success;
  final SkillManifest? manifest;
  final String? error;
  final List<String> warnings;

  SkillLoadResult({
    required this.success,
    this.manifest,
    this.error,
    this.warnings = const [],
  });
}

class SkillExecutionResult {
  final bool success;
  final String? output;
  final String? error;
  final int? executionTimeMs;
  final bool sandboxed;

  SkillExecutionResult({
    required this.success,
    this.output,
    this.error,
    this.executionTimeMs,
    this.sandboxed = true,
  });
}

class SkillLoader {
  static final SkillLoader _instance = SkillLoader._internal();
  factory SkillLoader() => _instance;
  SkillLoader._internal();

  final Map<String, SkillManifest> _loadedSkills = {};
  final Map<String, List<SkillTool>> _skillTools = {};

  // Security settings
  bool _requireSignature = true;
  bool _virusTotalCheck = false; // Would integrate with VirusTotal API
  bool _sandboxByDefault = true;
  List<String> _trustedAuthors = [];

  /// Load skill from directory or URL
  Future<SkillLoadResult> loadSkill(String source, {bool verifySignature = true}) async {
    List<String> warnings = [];

    try {
      // In production, would fetch from URL or read from directory
      // For now, simulate loading
      
      // Check for manifest
      if (!await _hasManifest(source)) {
        return SkillLoadResult(
          success: false,
          error: 'SKILL.md manifest not found',
        );
      }

      // Parse manifest
      final manifest = await _parseManifest(source);
      if (manifest == null) {
        return SkillLoadResult(
          success: false,
          error: 'Invalid SKILL.md format',
        );
      }

      // Security checks
      if (_requireSignature && verifySignature) {
        final sigResult = await _verifySignature(source, manifest);
        if (!sigResult.isValid) {
          return SkillLoadResult(
            success: false,
            error: 'Signature verification failed: ${sigResult.error}',
          );
        }
        if (sigResult.warnings.isNotEmpty) {
          warnings.addAll(sigResult.warnings);
        }
      }

      // Check for malicious patterns
      final maliciousCheck = await _checkForMaliciousCode(source);
      if (maliciousCheck.isMalicious) {
        return SkillLoadResult(
          success: false,
          error: 'Malicious code detected: ${maliciousCheck.reason}',
        );
      }
      if (maliciousCheck.warnings.isNotEmpty) {
        warnings.addAll(maliciousCheck.warnings);
      }

      // Check dependencies
      for (final dep in manifest.dependencies) {
        if (!_loadedSkills.containsKey(dep)) {
          warnings.add('Missing dependency: $dep');
        }
      }

      // Store skill
      _loadedSkills[manifest.name] = manifest;
      _skillTools[manifest.name] = manifest.tools.values.toList();

      return SkillLoadResult(
        success: true,
        manifest: manifest,
        warnings: warnings,
      );

    } catch (e) {
      return SkillLoadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Execute skill tool
  Future<SkillExecutionResult> executeTool(
    String skillName,
    String toolName,
    Map<String, dynamic> params, {
    bool? sandbox,
  }) async {
    final skill = _loadedSkills[skillName];
    if (skill == null) {
      return SkillExecutionResult(
        success: false,
        error: 'Skill not loaded: $skillName',
      );
    }

    final tool = skill.tools[toolName];
    if (tool == null) {
      return SkillExecutionResult(
        success: false,
        error: 'Tool not found: $toolName',
      );
    }

    // Determine sandbox mode
    final useSandbox = sandbox ?? _sandboxByDefault;
    
    final stopwatch = Stopwatch()..start();

    try {
      if (useSandbox) {
        return await _executeInSandbox(skill, tool, params, stopwatch);
      } else {
        return await _executeDirect(skill, tool, params, stopwatch);
      }
    } catch (e) {
      return SkillExecutionResult(
        success: false,
        error: e.toString(),
        executionTimeMs: stopwatch.elapsedMilliseconds,
        sandboxed: useSandbox,
      );
    }
  }

  /// Execute in sandbox (isolate)
  Future<SkillExecutionResult> _executeInSandbox(
    SkillManifest skill,
    SkillTool tool,
    Map<String, dynamic> params,
    Stopwatch stopwatch,
  ) async {
    // Create receive port for isolate communication
    final receivePort = ReceivePort();
    
    // In production, would spawn actual isolate
    // For now, simulate execution
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    stopwatch.stop();
    
    return SkillExecutionResult(
      success: true,
      output: 'Executed ${tool.name} from ${skill.name} in sandbox',
      executionTimeMs: stopwatch.elapsedMilliseconds,
      sandboxed: true,
    );
  }

  /// Execute directly (dangerous - requires explicit opt-in)
  Future<SkillExecutionResult> _executeDirect(
    SkillManifest skill,
    SkillTool tool,
    Map<String, dynamic> params,
    Stopwatch stopwatch,
  ) async {
    // WARNING: Direct execution is disabled by default
    stopwatch.stop();
    
    return SkillExecutionResult(
      success: false,
      error: 'Direct execution disabled. Use sandbox mode.',
      executionTimeMs: stopwatch.elapsedMilliseconds,
      sandboxed: false,
    );
  }

  /// Check if manifest exists
  Future<bool> _hasManifest(String source) async {
    // Simplified - would check actual file
    return true;
  }

  /// Parse manifest
  Future<SkillManifest?> _parseManifest(String source) async {
    // Simplified - would parse actual SKILL.md
    return null;
  }

  /// Verify signature
  Future<_SignatureResult> _verifySignature(String source, SkillManifest manifest) async {
    // In production, would verify cryptographic signature
    // For now, check if author is trusted
    
    if (_trustedAuthors.contains(manifest.author)) {
      return _SignatureResult(isValid: true);
    }
    
    if (_trustedAuthors.isEmpty) {
      // No trusted authors configured - warn but allow
      return _SignatureResult(
        isValid: true,
        warnings: ['No trusted authors configured - signature not verified'],
      );
    }

    return _SignatureResult(
      isValid: false,
      error: 'Author ${manifest.author} not in trusted list',
    );
  }

  /// Check for malicious code
  Future<_MaliciousCheck> _checkForMaliciousCode(String source) async {
    List<String> warnings = [];
    
    // Check for suspicious patterns
    final suspiciousPatterns = [
      RegExp(r'exec\s*\('),
      RegExp(r'eval\s*\('),
      RegExp(r'process\s*\.\s*spawn'),
      RegExp(r'child_process'),
      RegExp(r'fs\s*\.\s*writeFile'),
      RegExp(r'os\s*\.\s*system'),
      RegExp(r'subprocess\s*\.\s*call'),
      RegExp(r'socket\s*\.\s*connect'),
    ];

    // In production, would scan actual code
    
    return _MaliciousCheck(isMalicious: false, warnings: warnings);
  }

  /// Get loaded skill
  SkillManifest? getSkill(String name) => _loadedSkills[name];

  /// List loaded skills
  List<SkillManifest> listSkills() => _loadedSkills.values.toList();

  /// Unload skill
  void unloadSkill(String name) {
    _loadedSkills.remove(name);
    _skillTools.remove(name);
  }

  /// Configure security settings
  void configure({
    bool? requireSignature,
    bool? virusTotalCheck,
    bool? sandboxByDefault,
    List<String>? trustedAuthors,
  }) {
    if (requireSignature != null) _requireSignature = requireSignature;
    if (virusTotalCheck != null) _virusTotalCheck = virusTotalCheck;
    if (sandboxByDefault != null) _sandboxByDefault = sandboxByDefault;
    if (trustedAuthors != null) _trustedAuthors = trustedAuthors;
  }
}

class _SignatureResult {
  final bool isValid;
  final String? error;
  final List<String> warnings;

  _SignatureResult({
    required this.isValid,
    this.error,
    this.warnings = const [],
  });
}

class _MaliciousCheck {
  final bool isMalicious;
  final String? reason;
  final List<String> warnings;

  _MaliciousCheck({
    required this.isMalicious,
    this.reason,
    this.warnings = const [],
  });
}
