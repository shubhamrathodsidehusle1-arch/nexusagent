/// NexusAgent Audit Logging Service
/// Comprehensive audit logging for security events

import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum AuditEventType {
  // Authentication
  loginSuccess,
  loginFailure,
  logout,
  tokenCreated,
  tokenRevoked,
  
  // Session
  sessionCreated,
  sessionEnded,
  sessionAuth,
  
  // Tools
  toolExecuted,
  toolApproved,
  toolDenied,
  toolBlocked,
  
  // File
  fileRead,
  fileWrite,
  fileDelete,
  
  // Network
  webFetch,
  webRequest,
  
  // Security
  promptInjection,
  rateLimitExceeded,
  invalidInput,
  authFailure,
  
  // Admin
  configChanged,
  policyChanged,
  userCreated,
  userDeleted,
}

class AuditEvent {
  final String id;
  final AuditEventType type;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;
  final String? agentId;
  final String? toolName;
  final Map<String, dynamic>? details;
  final String? ipAddress;
  final bool success;

  AuditEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.userId,
    this.sessionId,
    this.agentId,
    this.toolName,
    this.details,
    this.ipAddress,
    this.success = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'userId': userId,
    'sessionId': sessionId,
    'agentId': agentId,
    'toolName': toolName,
    'details': details,
    'ipAddress': ipAddress,
    'success': success,
  };
}

class AuditConfig {
  final bool logToFile;
  final bool logToConsole;
  final bool logToDatabase;
  final String logFilePath;
  final int maxFileSizeMB;
  final int maxFiles;
  final List<AuditEventType> criticalEvents;
  final List<String> sensitiveFields;

  AuditConfig({
    this.logToFile = true,
    this.logToConsole = false,
    this.logToDatabase = true,
    this.logFilePath = '/var/log/nexusagent/audit.log',
    this.maxFileSizeMB = 100,
    this.maxFiles = 10,
    this.criticalEvents = const [
      AuditEventType.loginSuccess,
      AuditEventType.loginFailure,
      AuditEventType.sessionAuth,
      AuditEventType.toolDenied,
      AuditEventType.toolBlocked,
      AuditEventType.promptInjection,
      AuditEventType.rateLimitExceeded,
      AuditEventType.authFailure,
    ],
    this.sensitiveFields = const [
      'password',
      'token',
      'secret',
      'apiKey',
      'credential',
    ],
  });
}

class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  AuditConfig _config = AuditConfig();
  final List<AuditEvent> _memoryBuffer = [];
  final int _maxMemoryBuffer = 1000;
  IOSink? _logFile;
  String? _currentFile;

  // Stream for real-time events
  final _eventController = StreamController<AuditEvent>.broadcast();
  Stream<AuditEvent> get events => _eventController.stream;

  /// Initialize audit service
  void initialize(AuditConfig config) {
    _config = config;
    
    if (_config.logToFile) {
      _initLogFile();
    }
    
    print('Audit service initialized');
  }

  void _initLogFile() {
    try {
      final dir = Directory(File(_config.logFilePath).parent.path);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      
      _currentFile = _config.logFilePath;
      _logFile = File(_config.logFilePath).openWrite(mode: FileMode.append);
    } catch (e) {
      print('Failed to init audit log file: $e');
    }
  }

  /// Log an event
  void log(AuditEvent event) {
    // Add to memory buffer
    _memoryBuffer.add(event);
    if (_memoryBuffer.length > _maxMemoryBuffer) {
      _memoryBuffer.removeAt(0);
    }

    // Log to console
    if (_config.logToConsole) {
      _logToConsole(event);
    }

    // Log to file
    if (_config.logToFile && _logFile != null) {
      _logToFile(event);
    }

    // Emit to stream
    _eventController.add(event);

    // Check if critical
    if (_config.criticalEvents.contains(event.type)) {
      _handleCriticalEvent(event);
    }
  }

  /// Log helper methods
  void logLogin(String userId, bool success, {String? ipAddress}) {
    log(AuditEvent(
      id: _generateId(),
      type: success ? AuditEventType.loginSuccess : AuditEventType.loginFailure,
      timestamp: DateTime.now(),
      userId: userId,
      ipAddress: ipAddress,
      success: success,
    ));
  }

  void logToolExecution(String toolName, String? userId, String? sessionId, 
      bool success, {Map<String, dynamic>? details, String? ipAddress}) {
    log(AuditEvent(
      id: _generateId(),
      type: AuditEventType.toolExecuted,
      timestamp: DateTime.now(),
      userId: userId,
      sessionId: sessionId,
      toolName: toolName,
      details: _sanitizeDetails(details),
      ipAddress: ipAddress,
      success: success,
    ));
  }

  void logToolDenied(String toolName, String? userId, String reason, {String? ipAddress}) {
    log(AuditEvent(
      id: _generateId(),
      type: AuditEventType.toolDenied,
      timestamp: DateTime.now(),
      userId: userId,
      toolName: toolName,
      details: {'reason': reason},
      ipAddress: ipAddress,
      success: false,
    ));
  }

  void logPromptInjection(String? userId, String? sessionId, String content, {String? ipAddress}) {
    log(AuditEvent(
      id: _generateId(),
      type: AuditEventType.promptInjection,
      timestamp: DateTime.now(),
      userId: userId,
      sessionId: sessionId,
      details: {'content_preview': content.substring(0, content.length > 200 ? 200 : content.length)},
      ipAddress: ipAddress,
      success: false,
    ));
  }

  void logRateLimit(String identifier, {String? ipAddress}) {
    log(AuditEvent(
      id: _generateId(),
      type: AuditEventType.rateLimitExceeded,
      timestamp: DateTime.now(),
      details: {'identifier': identifier},
      ipAddress: ipAddress,
      success: false,
    ));
  }

  void logAuthFailure(String? userId, String reason, {String? ipAddress}) {
    log(AuditEvent(
      id: _generateId(),
      type: AuditEventType.authFailure,
      timestamp: DateTime.now(),
      userId: userId,
      details: {'reason': reason},
      ipAddress: ipAddress,
      success: false,
    ));
  }

  void _logToConsole(AuditEvent event) {
    final prefix = event.success ? '✓' : '✗';
    print('$prefix [AUDIT] ${event.type.name} - user: ${event.userId ?? 'unknown'}');
  }

  void _logToFile(AuditEvent event) {
    try {
      _logFile?.writeln(jsonEncode(event.toJson()));
    } catch (e) {
      print('Audit log write error: $e');
    }
  }

  Map<String, dynamic>? _sanitizeDetails(Map<String, dynamic>? details) {
    if (details == null) return null;
    
    final sanitized = Map<String, dynamic>.from(details);
    for (final field in _config.sensitiveFields) {
      for (final key in sanitized.keys) {
        if (key.toLowerCase().contains(field)) {
          sanitized[key] = '[REDACTED]';
        }
      }
    }
    return sanitized;
  }

  void _handleCriticalEvent(AuditEvent event) {
    // In production, could send alerts, emails, etc.
    print('⚠️ CRITICAL AUDIT EVENT: ${event.type.name}');
  }

  /// Query events
  List<AuditEvent> query({
    DateTime? startTime,
    DateTime? endTime,
    AuditEventType? type,
    String? userId,
    String? sessionId,
    bool? success,
    int? limit,
  }) {
    var results = _memoryBuffer.toList();

    if (startTime != null) {
      results = results.where((e) => e.timestamp.isAfter(startTime)).toList();
    }
    if (endTime != null) {
      results = results.where((e) => e.timestamp.isBefore(endTime)).toList();
    }
    if (type != null) {
      results = results.where((e) => e.type == type).toList();
    }
    if (userId != null) {
      results = results.where((e) => e.userId == userId).toList();
    }
    if (sessionId != null) {
      results = results.where((e) => e.sessionId == sessionId).toList();
    }
    if (success != null) {
      results = results.where((e) => e.success == success).toList();
    }

    // Sort by timestamp descending
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && results.length > limit) {
      results = results.take(limit).toList();
    }

    return results;
  }

  /// Get recent events
  List<AuditEvent> getRecent({int limit = 100}) {
    return query(limit: limit);
  }

  /// Get critical events
  List<AuditEvent> getCriticalEvents({int limit = 100}) {
    return query(
      type: _config.criticalEvents.first,
      limit: limit,
    );
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Flush and close
  void shutdown() {
    _logFile?.flush();
    _logFile?.close();
    _eventController.close();
  }
}
