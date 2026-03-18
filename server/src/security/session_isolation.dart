/// NexusAgent Session Isolation Service
/// Fixes: Session is routing selector, not auth boundary
/// Implements per-user session isolation

import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SessionIsolationConfig {
  final bool enforcePerUserIsolation;
  final bool requireExplicitAuth;
  final Duration sessionMaxAge;
  final int maxSessionsPerUser;

  SessionIsolationConfig({
    this.enforcePerUserIsolation = true,
    this.requireExplicitAuth = true,
    this.sessionMaxAge = const Duration(hours: 24),
    this.maxSessionsPerUser = 10,
  });
}

class UserSession {
  final String sessionId;
  final String userId;
  final String channel;
  final String peerId;
  final DateTime createdAt;
  DateTime lastActivity;
  final Map<String, dynamic> metadata;
  bool isAuthenticated;

  UserSession({
    required this.sessionId,
    required this.userId,
    required this.channel,
    required this.peerId,
    required this.createdAt,
    required this.lastActivity,
    this.metadata = const {},
    this.isAuthenticated = false,
  });
}

class SessionIsolationService {
  static final SessionIsolationService _instance = SessionIsolationService._internal();
  factory SessionIsolationService() => _instance;
  SessionIsolationService._internal();

  SessionIsolationConfig _config = SessionIsolationConfig();
  final Map<String, UserSession> _sessions = {}; // sessionId -> session
  final Map<String, Set<String>> _userSessions = {}; // userId -> sessionIds
  final Map<String, String> _channelPeerToSession = {}; // "channel:peer" -> sessionId
  
  Timer? _cleanupTimer;

  /// Initialize service
  void initialize(SessionIsolationConfig config) {
    _config = config;
    _startCleanup();
    print('Session isolation service initialized');
  }

  /// Create new session with isolation
  UserSession createSession({
    required String userId,
    required String channel,
    required String peerId,
    Map<String, dynamic> metadata = const {},
  }) {
    // Check max sessions per user
    if (_config.enforcePerUserIsolation) {
      final userSessionIds = _userSessions[userId] ?? {};
      if (userSessionIds.length >= _config.maxSessionsPerUser) {
        // Remove oldest session
        final oldest = _sessions.entries
            .where((e) => e.value.userId == userId)
            .toList()
          ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));
        
        if (oldest.isNotEmpty) {
          _removeSession(oldest.first.key);
        }
      }
    }

    // Check for existing session (per-channel-peer)
    final key = '$channel:$peerId';
    if (_channelPeerToSession.containsKey(key)) {
      // Return existing session
      return _sessions[_channelPeerToSession[key]]!;
    }

    // Generate secure session ID
    final sessionId = _generateSecureId(userId, channel, peerId);

    final session = UserSession(
      sessionId: sessionId,
      userId: userId,
      channel: channel,
      peerId: peerId,
      createdAt: DateTime.now(),
      lastActivity: DateTime.now(),
      metadata: metadata,
      isAuthenticated: !_config.requireExplicitAuth, // Default to not authenticated
    );

    // Store session
    _sessions[sessionId] = session;
    _userSessions[userId] ??= {};
    _userSessions[userId]!.add(sessionId);
    _channelPeerToSession[key] = sessionId;

    return session;
  }

  /// Get session by ID
  UserSession? getSession(String sessionId) {
    final session = _sessions[sessionId];
    if (session == null) return null;
    
    // Check if expired
    if (DateTime.now().difference(session.lastActivity) > _config.sessionMaxAge) {
      _removeSession(sessionId);
      return null;
    }
    
    return session;
  }

  /// Get session by channel:peer
  UserSession? getSessionByChannelPeer(String channel, String peerId) {
    final key = '$channel:$peerId';
    final sessionId = _channelPeerToSession[key];
    if (sessionId == null) return null;
    return getSession(sessionId);
  }

  /// Authenticate session (require explicit auth)
  bool authenticateSession(String sessionId, String userId) {
    final session = _sessions[sessionId];
    if (session == null) return false;
    
    // Verify user owns this session
    if (session.userId != userId) return false;
    
    session.isAuthenticated = true;
    return true;
  }

  /// Check if session is authenticated (for tool access)
  bool isAuthenticated(String sessionId) {
    final session = _sessions[sessionId];
    if (session == null) return false;
    
    if (_config.requireExplicitAuth) {
      return session.isAuthenticated;
    }
    
    return true; // If not requiring explicit auth, all sessions are "authenticated"
  }

  /// Check if user can access session
  bool canAccessSession(String sessionId, String userId) {
    final session = _sessions[sessionId];
    if (session == null) return false;
    
    // In per-user isolation mode, users can only access their own sessions
    if (_config.enforcePerUserIsolation) {
      return session.userId == userId;
    }
    
    return true;
  }

  /// Update session activity
  void updateActivity(String sessionId) {
    final session = _sessions[sessionId];
    if (session != null) {
      session.lastActivity = DateTime.now();
    }
  }

  /// List sessions for user
  List<UserSession> listUserSessions(String userId) {
    final sessionIds = _userSessions[userId] ?? {};
    return sessionIds
        .map((id) => _sessions[id])
        .where((s) => s != null)
        .cast<UserSession>()
        .toList();
  }

  /// List all sessions
  List<UserSession> listAllSessions() {
    return _sessions.values.toList();
  }

  /// End session
  void endSession(String sessionId) {
    _removeSession(sessionId);
  }

  /// End all user sessions
  void endAllUserSessions(String userId) {
    final sessionIds = _userSessions[userId]?.toList() ?? [];
    for (final id in sessionIds) {
      _removeSession(id);
    }
  }

  void _removeSession(String sessionId) {
    final session = _sessions[sessionId];
    if (session == null) return;

    // Remove from all indexes
    _sessions.remove(sessionId);
    _userSessions[session.userId]?.remove(sessionId);
    if (_userSessions[session.userId]?.isEmpty ?? false) {
      _userSessions.remove(session.userId);
    }
    
    final key = '${session.channel}:${session.peerId}';
    _channelPeerToSession.remove(key);
  }

  String _generateSecureId(String userId, String channel, String peerId) {
    final data = '$userId:$channel:$peerId:${DateTime.now().microsecondsSinceEpoch}';
    final hash = sha256.convert(utf8.encode(data));
    return hash.toString().substring(0, 24);
  }

  void _startCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpired();
    });
  }

  void _cleanupExpired() {
    final expired = _sessions.entries
        .where((e) => DateTime.now().difference(e.value.lastActivity) > _config.sessionMaxAge)
        .map((e) => e.key)
        .toList();

    for (final id in expired) {
      _removeSession(id);
    }
  }

  /// Get stats
  Map<String, dynamic> getStats() {
    return {
      'totalSessions': _sessions.length,
      'totalUsers': _userSessions.length,
      'sessionsByChannel': _sessions.values.groupBy((s) => s.channel),
    };
  }

  void shutdown() {
    _cleanupTimer?.cancel();
    _sessions.clear();
    _userSessions.clear();
    _channelPeerToSession.clear();
  }
}

extension GroupByExtension<T> on Iterable<T> {
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    final map = <K, List<T>>{};
    for (final element in this) {
      final key = keyFunction(element);
      map[key] ??= [];
      map[key]!.add(element);
    }
    return map;
  }
}
