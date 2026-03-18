/// NexusAgent Sessions Provider
/// Connected to database

import 'package:flutter/material.dart';
import '../data/services/database_service.dart';
import '../data/services/api_service.dart';
import '../data/services/sync_service.dart';

class SessionsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final ApiService _api = ApiService();
  final SyncService _sync = SyncService();

  List<Session> _sessions = [];
  List<Session> _activeSessions = [];
  bool _isLoading = false;
  String? _error;

  List<Session> get sessions => _sessions;
  List<Session> get activeSessions => _activeSessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load sessions if authenticated
  Future<void> loadIfAuthenticated(bool isAuthenticated) async {
    if (isAuthenticated) {
      await loadSessions();
    }
  }

  /// Load all sessions
  Future<void> loadSessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to load from local database first
      final dbSessions = await _db.getSessions();

      _sessions = dbSessions.map((s) => Session.fromMap(s)).toList();

      // Get active sessions
      final dbActive = await _db.getActiveSessions();
      _activeSessions = dbActive.map((s) => Session.fromMap(s)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start a new session
  Future<void> startSession(String agentId, String channel, String senderId) async {
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      agentId: agentId,
      channel: channel,
      senderId: senderId,
      startedAt: DateTime.now(),
    );

    // Save to local database
    await _db.insertSession(session.toMap());

    // Queue for sync
    await _sync.queueSync(
      table: 'sessions',
      id: session.id,
      data: session.toMap(),
      operation: 'insert',
    );

    // Refresh
    await loadSessions();
  }

  /// End a session
  Future<void> endSession(String sessionId) async {
    // Update local database
    await _db.endSession(sessionId);

    // Queue for sync
    await _sync.queueSync(
      table: 'sessions',
      id: sessionId,
      data: {'ended_at': DateTime.now().toIso8601String()},
      operation: 'update',
    );

    // Refresh
    await loadSessions();
  }

  /// Get session by ID
  Future<Session?> getSession(String sessionId) async {
    // Try API first
    try {
      final data = await _api.getSession(sessionId);
      return Session.fromApi(data);
    } catch (e) {
      // Fallback to local
      final dbSession = await _db.getSessions();
      final sessions = dbSession.map((s) => Session.fromMap(s)).toList();
      return sessions.where((s) => s.id == sessionId).firstOrNull;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class Session {
  final String id;
  final String? agentId;
  final String? channel;
  final String? senderId;
  final DateTime startedAt;
  final DateTime? endedAt;

  Session({
    required this.id,
    this.agentId,
    this.channel,
    this.senderId,
    required this.startedAt,
    this.endedAt,
  });

  bool get isActive => endedAt == null;

  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] ?? '',
      agentId: map['agent_id'],
      channel: map['channel'],
      senderId: map['sender_id'],
      startedAt: DateTime.tryParse(map['started_at'] ?? '') ?? DateTime.now(),
      endedAt: map['ended_at'] != null ? DateTime.tryParse(map['ended_at']) : null,
    );
  }

  factory Session.fromApi(Map<String, dynamic> json) {
    return Session(
      id: json['id'] ?? '',
      agentId: json['agentId'],
      channel: json['channel'],
      senderId: json['senderId'],
      startedAt: DateTime.tryParse(json['startedAt'] ?? '') ?? DateTime.now(),
      endedAt: json['endedAt'] != null ? DateTime.tryParse(json['endedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agent_id': agentId,
      'channel': channel,
      'sender_id': senderId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    };
  }
}
