/// NexusAgent Gateway - Core message routing and authentication
/// Replaces OpenClaw's gateway with security hardening

import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

enum ChannelType {
  telegram,
  discord,
  whatsapp,
  slack,
  signal,
  webchat,
}

class GatewayConfig {
  final String host;
  final int port;
  final bool enableTailscale;
  final List<String> allowFrom;
  final Duration pairingGracePeriod;
  final Duration sessionTimeout;

  GatewayConfig({
    this.host = '0.0.0.0',
    this.port = 3000,
    this.enableTailscale = false,
    this.allowFrom = const [],
    this.pairingGracePeriod = const Duration(seconds: 10), // Much shorter than OpenClaw's 30s
    this.sessionTimeout = const Duration(hours: 24),
  });
}

class ChannelCredentials {
  final ChannelType type;
  final Map<String, String> config;
  final String? encryptedToken;

  ChannelCredentials({
    required this.type,
    required this.config,
    this.encryptedToken,
  });
}

class InboundMessage {
  final String id;
  final ChannelType channel;
  final String senderId;
  final String senderName;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  InboundMessage({
    required this.id,
    required this.channel,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class Session {
  final String id;
  final String agentId;
  final ChannelType channel;
  final String senderId;
  final DateTime createdAt;
  DateTime lastActivity;
  Map<String, dynamic> context;

  Session({
    required this.id,
    required this.agentId,
    required this.channel,
    required this.senderId,
    DateTime? createdAt,
    this.context = const {},
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActivity = DateTime.now();
}

class Gateway {
  static final Gateway _instance = Gateway._internal();
  factory Gateway() => _instance;
  Gateway._internal();

  GatewayConfig _config = GatewayConfig();
  final Map<String, ChannelCredentials> _channels = {};
  final Map<String, Session> _sessions = {};
  final Map<String, String> _pairingCodes = {}; // code -> session info
  Timer? _pairingCleanupTimer;

  // Callbacks
  Function(InboundMessage)? onMessage;
  Function(String sessionId)? onSessionStart;
  Function(String sessionId)? onSessionEnd;

  /// Initialize gateway
  void initialize(GatewayConfig config) {
    _config = config;
    _startPairingCleanup();
    print('NexusAgent Gateway initialized on ${config.host}:${config.port}');
  }

  /// Register a channel
  void registerChannel(String channelId, ChannelCredentials credentials) {
    _channels[channelId] = credentials;
    print('Channel registered: $channelId (${credentials.type})');
  }

  /// Generate pairing code (shorter grace period than OpenClaw)
  String generatePairingCode(String channelId, String agentId) {
    final code = _generateSecureCode(6); // 6 chars, more secure
    _pairingCodes[code] = jsonEncode({
      'channelId': channelId,
      'agentId': agentId,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Schedule cleanup
    Timer(_config.pairingGracePeriod, () {
      _pairingCodes.remove(code);
    });

    return code;
  }

  /// Validate pairing code
  Map<String, String>? validatePairingCode(String code) {
    final data = _pairingCodes[code];
    if (data == null) return null;

    final parsed = jsonDecode(data) as Map<String, dynamic>;
    final createdAt = DateTime.parse(parsed['createdAt']);
    
    if (DateTime.now().difference(createdAt) > _config.pairingGracePeriod) {
      _pairingCodes.remove(code);
      return null;
    }

    return {
      'channelId': parsed['channelId'] as String,
      'agentId': parsed['agentId'] as String,
    };
  }

  /// Handle incoming message
  Future<void> handleInboundMessage(InboundMessage message) async {
    // Validate sender (AllowFrom check)
    if (_config.allowFrom.isNotEmpty && !_config.allowFrom.contains(message.senderId)) {
      print('Message blocked: sender ${message.senderId} not in allowlist');
      return;
    }

    // Get or create session
    final sessionId = _getOrCreateSession(message);
    
    // Update session activity
    final session = _sessions[sessionId];
    if (session != null) {
      session.lastActivity = DateTime.now();
    }

    // Route to agent
    onMessage?.call(message);
  }

  /// Get or create session
  String _getOrCreateSession(InboundMessage message) {
    final key = '${message.channel.name}:${message.senderId}';
    
    // Find existing session
    for (final entry in _sessions.entries) {
      if (entry.value.senderId == message.senderId && 
          entry.value.channel == message.channel) {
        return entry.key;
      }
    }

    // Create new session
    final sessionId = _generateSecureId();
    _sessions[sessionId] = Session(
      id: sessionId,
      agentId: 'default', // Would be configured per channel
      channel: message.channel,
      senderId: message.senderId,
    );

    onSessionStart?.call(sessionId);
    return sessionId;
  }

  /// Get session
  Session? getSession(String sessionId) {
    return _sessions[sessionId];
  }

  /// End session
  void endSession(String sessionId) {
    _sessions.remove(sessionId);
    onSessionEnd?.call(sessionId);
  }

  /// Cleanup expired sessions
  void cleanupExpiredSessions() {
    final now = DateTime.now();
    final expired = _sessions.entries
        .where((e) => now.difference(e.value.lastActivity) > _config.sessionTimeout)
        .map((e) => e.key)
        .toList();

    for (final sessionId in expired) {
      endSession(sessionId);
    }
  }

  /// Start pairing code cleanup timer
  void _startPairingCleanup() {
    _pairingCleanupTimer?.cancel();
    _pairingCleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _pairingCodes.removeWhere((code, data) {
        final parsed = jsonDecode(data) as Map<String, dynamic>;
        final createdAt = DateTime.parse(parsed['createdAt']);
        return DateTime.now().difference(createdAt) > _config.pairingGracePeriod;
      });
    });
  }

  /// Generate secure code
  String _generateSecureCode(int length) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final hash = sha256.convert(utf8.encode('$random${DateTime.now()}'));
    return hash.toString().substring(0, length).toUpperCase();
  }

  /// Generate secure ID
  String _generateSecureId() {
    final random = DateTime.now().microsecondsSinceEpoch;
    return sha256.convert(utf8.encode('$random')).toString().substring(0, 16);
  }

  /// Shutdown
  void shutdown() {
    _pairingCleanupTimer?.cancel();
    _sessions.clear();
    _pairingCodes.clear();
  }
}
