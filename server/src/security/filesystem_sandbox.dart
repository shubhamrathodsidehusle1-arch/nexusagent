/// NexusAgent Filesystem Sandbox
/// Fixes: FS workspaceOnly enforcement, permission issues
/// Implements: Strict filesystem boundaries

import 'dart:io';
import 'dart:path/path.dart' as p;

enum FSMode {
  disabled,      // No file access
  workspaceOnly, // Only workspace directory
  restricted,    // Allowed paths only
  open,          // Full access (dangerous)
}

class FilesystemSandboxConfig {
  final FSMode mode;
  final String workspacePath;
  final List<String> allowedPaths;
  final List<String> blockedPaths;
  final int maxFileSizeMB;
  final List<String> allowedExtensions;

  FilesystemSandboxConfig({
    this.mode = FSMode.workspaceOnly,
    this.workspacePath = '/tmp/nexusagent',
    this.allowedPaths = const [],
    this.blockedPaths = const [],
    this.maxFileSizeMB = 10,
    this.allowedExtensions = const ['.txt', '.json', '.md', '.yaml', '.yml', '.xml', '.csv', '.log'],
  });
}

class FilesystemSandbox {
  static final FilesystemSandbox _instance = FilesystemSandbox._internal();
  factory FilesystemSandbox() => _instance;
  FilesystemSandbox._internal();

  FilesystemSandboxConfig _config = FilesystemSandboxConfig();

  /// Initialize sandbox
  void initialize(FilesystemSandboxConfig config) {
    _config = config;
    
    // Ensure workspace exists
    if (_config.mode != FSMode.disabled) {
      final dir = Directory(_config.workspacePath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    }
    
    print('Filesystem sandbox initialized: ${_config.mode.name}');
  }

  /// Check if path is allowed
  SandboxResult checkPath(String path, {bool isWrite = false}) {
    if (_config.mode == FSMode.disabled) {
      return SandboxResult(
        allowed: false,
        reason: 'File system access is disabled',
      );
    }

    // Normalize path
    String normalizedPath;
    try {
      normalizedPath = p.normalize(p.absolute(path));
    } catch (e) {
      return SandboxResult(allowed: false, reason: 'Invalid path');
    }

    // Check blocked paths
    for (final blocked in _config.blockedPaths) {
      if (normalizedPath.startsWith(blocked)) {
        return SandboxResult(
          allowed: false,
          reason: 'Path matches blocked pattern: $blocked',
        );
      }
    }

    // Mode-specific checks
    switch (_config.mode) {
      case FSMode.disabled:
        return SandboxResult(allowed: false, reason: 'File system disabled');

      case FSMode.workspaceOnly:
        final workspace = p.absolute(_config.workspacePath);
        if (!normalizedPath.startsWith(workspace)) {
          return SandboxResult(
            allowed: false,
            reason: 'Path outside workspace: $workspace',
          );
        }
        break;

      case FSMode.restricted:
        if (_config.allowedPaths.isEmpty) {
          return SandboxResult(allowed: false, reason: 'No allowed paths configured');
        }
        
        bool allowed = false;
        for (final allowedPath in _config.allowedPaths) {
          if (normalizedPath.startsWith(p.absolute(allowedPath))) {
            allowed = true;
            break;
          }
        }
        
        if (!allowed) {
          return SandboxResult(
            allowed: false,
            reason: 'Path not in allowed directories',
          );
        }
        break;

      case FSMode.open:
        // No restrictions - WARNING: dangerous!
        break;
    }

    // Check file extension (for writes)
    if (isWrite) {
      final ext = p.extension(path).toLowerCase();
      if (_config.allowedExtensions.isNotEmpty && 
          !_config.allowedExtensions.contains(ext)) {
        return SandboxResult(
          allowed: false,
          reason: 'File extension not allowed: $ext',
        );
      }
    }

    // Check file size (for writes)
    if (isWrite && _config.maxFileSizeMB > 0) {
      // Size check will be done at write time
    }

    return SandboxResult(allowed: true, resolvedPath: normalizedPath);
  }

  /// Read file
  Future<SandboxResult> readFile(String path) async {
    final check = checkPath(path, isWrite: false);
    if (!check.allowed) return check;

    try {
      final file = File(check.resolvedPath!);
      if (!await file.exists()) {
        return SandboxResult(allowed: false, reason: 'File not found');
      }

      // Check size
      final stat = await file.stat();
      final sizeMB = stat.size / (1024 * 1024);
      if (sizeMB > _config.maxFileSizeMB) {
        return SandboxResult(
          allowed: false,
          reason: 'File too large: ${sizeMB.toStringAsFixed(2)}MB (max: ${_config.maxFileSizeMB}MB)',
        );
      }

      final content = await file.readAsString();
      return SandboxResult(
        allowed: true,
        resolvedPath: check.resolvedPath,
        output: content,
        metadata: {'size': stat.size},
      );
    } catch (e) {
      return SandboxResult(allowed: false, reason: 'Read error: $e');
    }
  }

  /// Write file
  Future<SandboxResult> writeFile(String path, String content) async {
    final check = checkPath(path, isWrite: true);
    if (!check.allowed) return check;

    try {
      // Check content size
      final sizeMB = content.length / (1024 * 1024);
      if (sizeMB > _config.maxFileSizeMB) {
        return SandboxResult(
          allowed: false,
          reason: 'Content too large: ${sizeMB.toStringAsFixed(2)}MB (max: ${_config.maxFileSizeMB}MB)',
        );
      }

      final file = File(check.resolvedPath!);
      await file.writeAsString(content);
      
      return SandboxResult(
        allowed: true,
        resolvedPath: check.resolvedPath,
        output: 'Written ${content.length} bytes',
        metadata: {'size': content.length},
      );
    } catch (e) {
      return SandboxResult(allowed: false, reason: 'Write error: $e');
    }
  }

  /// List directory
  Future<SandboxResult> listDirectory(String path) async {
    final check = checkPath(path, isWrite: false);
    if (!check.allowed) return check;

    try {
      final dir = Directory(check.resolvedPath!);
      if (!await dir.exists()) {
        return SandboxResult(allowed: false, reason: 'Directory not found');
      }

      final entries = <String>[];
      await for (final entity in dir.list(maxDepth: 1)) {
        final name = p.basename(entity.path);
        if (!name.startsWith('.')) { // Skip hidden files
          entries.add(name);
        }
      }

      return SandboxResult(
        allowed: true,
        resolvedPath: check.resolvedPath,
        output: entries.join('\n'),
        metadata: {'count': entries.length},
      );
    } catch (e) {
      return SandboxResult(allowed: false, reason: 'List error: $e');
    }
  }

  /// Delete file/directory
  Future<SandboxResult> delete(String path) async {
    final check = checkPath(path, isWrite: true);
    if (!check.allowed) return check;

    try {
      final type = await FileSystemEntity.type(check.resolvedPath!);
      
      if (type == FileSystemEntityType.file) {
        await File(check.resolvedPath!).delete();
      } else if (type == FileSystemEntityType.directory) {
        await Directory(check.resolvedPath!).delete(recursive: true);
      } else {
        return SandboxResult(allowed: false, reason: 'Not found');
      }

      return SandboxResult(
        allowed: true,
        resolvedPath: check.resolvedPath,
        output: 'Deleted',
      );
    } catch (e) {
      return SandboxResult(allowed: false, reason: 'Delete error: $e');
    }
  }

  /// Check if path exists
  Future<bool> exists(String path) async {
    final check = checkPath(path, isWrite: false);
    if (!check.allowed) return false;
    
    return await File(check.resolvedPath!).exists() || 
           await Directory(check.resolvedPath!).exists();
  }

  /// Get workspace path
  String get workspacePath => _config.workspacePath;

  /// Get current mode
  FSMode get mode => _config.mode;
}

class SandboxResult {
  final bool allowed;
  final String? reason;
  final String? resolvedPath;
  final String? output;
  final Map<String, dynamic>? metadata;

  SandboxResult({
    required this.allowed,
    this.reason,
    this.resolvedPath,
    this.output,
    this.metadata,
  });
}
