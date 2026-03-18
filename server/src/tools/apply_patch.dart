/// NexusAgent Apply Patch Tool
/// Structured file patching

import 'dart:io';
import 'package:path/path.dart' as p;

class PatchTool {
  /// Apply structured patches to files
  static Future<PatchResult> applyPatches(List<Patch> patches, {String? workspacePath}) async {
    final results = <PatchResult>[];
    
    for (final patch in patches) {
      final result = await _applyPatch(patch, workspacePath: workspacePath);
      results.add(result);
      
      if (!result.success && patch.strict) {
        // Stop on first failure in strict mode
        break;
      }
    }

    final allSuccess = results.every((r) => r.success);
    return PatchResult(
      success: allSuccess,
      message: allSuccess 
        ? 'Applied ${results.length} patches successfully'
        : 'Some patches failed',
      results: results,
    );
  }

  static Future<PatchResult> _applyPatch(Patch patch, {String? workspacePath}) async {
    try {
      var filePath = patch.filePath;
      
      // Resolve workspace-relative paths
      if (workspacePath != null && !p.isAbsolute(filePath)) {
        filePath = p.join(workspacePath, filePath);
      }

      final file = File(filePath);
      
      // Read original content
      String content = '';
      if (await file.exists()) {
        content = await file.readAsString();
      } else if (patch.operation == PatchOperation.create) {
        // New file
        content = '';
      } else {
        return PatchResult(
          success: false,
          message: 'File not found: ${patch.filePath}',
        );
      }

      String newContent = content;

      switch (patch.operation) {
        case PatchOperation.create:
          newContent = patch.content ?? '';
          break;
          
        case PatchOperation.replace:
          if (patch.oldContent != null) {
            newContent = content.replaceFirst(patch.oldContent!, patch.content ?? '');
          } else {
            return PatchResult(
              success: false,
              message: 'oldContent required for replace operation',
            );
          }
          break;
          
        case PatchOperation.replaceAll:
          if (patch.oldContent != null) {
            newContent = content.replaceAll(patch.oldContent!, patch.content ?? '');
          } else {
            return PatchResult(
              success: false,
              message: 'oldContent required for replaceAll operation',
            );
          }
          break;
          
        case PatchOperation.delete:
          if (patch.oldContent != null) {
            newContent = content.replaceFirst(patch.oldContent!, '');
          } else {
            return PatchResult(
              success: false,
              message: 'oldContent required for delete operation',
            );
          }
          break;
          
        case PatchOperation.prepend:
          newContent = (patch.content ?? '') + content;
          break;
          
        case PatchOperation.append:
          newContent = content + (patch.content ?? '');
          break;
      }

      // Write new content
      await file.writeAsString(newContent);

      return PatchResult(
        success: true,
        message: 'Patched ${patch.filePath}',
        newContent: newContent,
      );
    } catch (e) {
      return PatchResult(
        success: false,
        message: 'Error patching ${patch.filePath}: $e',
      );
    }
  }

  /// Parse unified diff format
  static List<Patch> parseUnifiedDiff(String diff) {
    final patches = <Patch>[];
    final lines = diff.split('\n');
    
    String? currentFile;
    String? oldContent;
    String? newContent;
    List<String> contentLines = [];
    PatchOperation? operation;

    for (final line in lines) {
      // File header
      if (line.startsWith('--- ')) {
        currentFile = line.substring(4).replaceFirst('\t', '').split(' ').first;
        oldContent = null;
        contentLines = [];
      } else if (line.startsWith('+++ ')) {
        currentFile ??= line.substring(4).replaceFirst('\t', '').split(' ').first;
      } else if (line.startsWith('@@')) {
        // Save previous patch if any
        if (currentFile != null && contentLines.isNotEmpty) {
          patches.add(Patch(
            filePath: currentFile,
            operation: PatchOperation.replace,
            oldContent: _extractHunkOld(contentLines),
            content: _extractHunkNew(contentLines),
          ));
        }
        contentLines = [];
      } else if (line.startsWith('+') && !line.startsWith('+++')) {
        contentLines.add(line.substring(1));
      } else if (line.startsWith('-') && !line.startsWith('---')) {
        contentLines.add(line);
      } else if (!line.startsWith('@@') && !line.startsWith('diff')) {
        contentLines.add(line);
      }
    }

    // Add last patch
    if (currentFile != null && contentLines.isNotEmpty) {
      patches.add(Patch(
        filePath: currentFile,
        operation: PatchOperation.replace,
        oldContent: _extractHunkOld(contentLines),
        content: _extractHunkNew(contentLines),
      ));
    }

    return patches;
  }

  static String? _extractHunkOld(List<String> lines) {
    final old = lines.where((l) => !l.startsWith('+')).join('\n');
    return old.isEmpty ? null : old;
  }

  static String? _extractHunkNew(List<String> lines) {
    final ne = lines.where((l) => !l.startsWith('-')).join('\n');
    return ne.isEmpty ? null : ne;
  }
}

enum PatchOperation {
  create,
  replace,
  replaceAll,
  delete,
  prepend,
  append,
}

class Patch {
  final String filePath;
  final PatchOperation operation;
  final String? oldContent;
  final String? content;
  final bool strict;

  Patch({
    required this.filePath,
    required this.operation,
    this.oldContent,
    this.content,
    this.strict = true,
  });
}

class PatchResult {
  final bool success;
  final String message;
  final String? newContent;
  final List<PatchResult>? results;

  PatchResult({
    required this.success,
    required this.message,
    this.newContent,
    this.results,
  });
}
