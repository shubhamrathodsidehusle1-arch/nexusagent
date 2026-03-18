/// NexusAgent Mattermost Integration
/// Enterprise messaging platform

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MattermostConfig {
  final String serverUrl;
  final String botToken;
  final String? teamId;
  final List<String> channels;

  MattermostConfig({
    required this.serverUrl,
    required this.botToken,
    this.teamId,
    this.channels = const [],
  });
}

class MattermostMessage {
  final String id;
  final String channelId;
  final String userId;
  final String message;
  final String? threadId;
  final DateTime timestamp;

  MattermostMessage({
    required this.id,
    required this.channelId,
    required this.userId,
    required this.message,
    this.threadId,
    required this.timestamp,
  });
}

class MattermostClient {
  final MattermostConfig config;
  final http.Client _client = http.Client();
  StreamController<MattermostMessage>? _messageController;

  MattermostClient(this.config);

  /// Start receiving messages
  Stream<MattermostMessage> start() {
    _messageController = StreamController<MattermostMessage>.broadcast();
    _connectWebSocket();
    return _messageController!.stream;
  }

  void _connectWebSocket() async {
    // In production, connect to Mattermost WebSocket
    print('Mattermost: WebSocket connection would be established');
  }

  /// Send message to channel
  Future<bool> sendMessage(String channelId, String message, {String? threadId}) async {
    final uri = Uri.parse('${config.serverUrl}/api/v4/posts');

    final body = {
      'channel_id': channelId,
      'message': message,
      if (threadId != null) 'root_id': threadId,
    };

    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${config.botToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 201;
  }

  /// Send ephemeral message (visible to one user)
  Future<bool> sendEphemeral(String channelId, String userId, String message) async {
    final uri = Uri.parse('${config.serverUrl}/api/v4/posts/ephemeral');

    final body = {
      'user_id': userId,
      'post': {
        'channel_id': channelId,
        'message': message,
      },
    };

    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${config.botToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  /// Upload file
  Future<String?> uploadFile(String channelId, String filePath, {String? filename}) async {
    // In production, would use multipart upload
    return null;
  }

  /// Create reaction
  Future<bool> addReaction(String postId, String emojiName) async {
    final uri = Uri.parse('${config.serverUrl}/api/v4/reactions');

    final body = {
      'post_id': postId,
      'emoji_name': emojiName,
      'user_id': 'me',
    };

    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${config.botToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 201;
  }

  /// Get user info
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final uri = Uri.parse('${config.serverUrl}/api/v4/users/$userId');

    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer ${config.botToken}'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  /// Get channel
  Future<Map<String, dynamic>?> getChannel(String channelId) async {
    final uri = Uri.parse('${config.serverUrl}/api/v4/channels/$channelId');

    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer ${config.botToken}'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  /// List channels
  Future<List<Map<String, dynamic>>> listChannels() async {
    final uri = Uri.parse('${config.serverUrl}/api/v4/channels');

    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer ${config.botToken}'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  /// Search messages
  Future<List<MattermostMessage>> searchMessages(String query) async {
    final uri = Uri.parse('${config.serverUrl}/api/v4/posts/search');

    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${config.botToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'terms': query}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final posts = data['posts'] as Map<String, dynamic>?;
      if (posts == null) return [];

      return posts.values.map((p) => MattermostMessage(
        id: p['id'] ?? '',
        channelId: p['channel_id'] ?? '',
        userId: p['user_id'] ?? '',
        message: p['message'] ?? '',
        threadId: p['root_id'],
        timestamp: DateTime.tryParse(p['create_at']?.toString() ?? '') ?? DateTime.now(),
      )).toList();
    }
    return [];
  }

  void dispose() {
    _messageController?.close();
    _client.close();
  }
}
