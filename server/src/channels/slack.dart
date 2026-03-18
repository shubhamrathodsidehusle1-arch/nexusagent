/// NexusAgent Slack Integration
/// Connects to Slack Web API and Events

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SlackConfig {
  final String botToken;
  final String signingSecret;
  final String? appToken; // For Socket Mode

  SlackConfig({
    required this.botToken,
    required this.signingSecret,
    this.appToken,
  });
}

class SlackMessage {
  final String ts;
  final String channel;
  final String text;
  final String? user;
  final String? botId;
  final Map<String, dynamic>? raw;

  SlackMessage({
    required this.ts,
    required this.channel,
    required this.text,
    this.user,
    this.botId,
    this.raw,
  });

  factory SlackMessage.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return SlackMessage(
        ts: '',
        channel: '',
        text: '',
      );
    }
    
    return SlackMessage(
      ts: json['ts'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      text: json['text'] as String? ?? '',
      user: json['user'] as String?,
      botId: json['bot_id'] as String?,
      raw: json,
    );
  }
}

class SlackClient {
  final SlackConfig config;
  final String _apiUrl = 'https://slack.com/api';

  StreamController<SlackMessage>? _messageController;

  SlackClient(this.config);

  /// Verify request signature
  bool verifySignature(String timestamp, String body, String signature) {
    // In production, implement proper HMAC-SHA256 verification
    // Using signing_secret to verify requests came from Slack
    return true; // Simplified
  }

  /// Handle event callback
  Stream<SlackMessage> handleEvent(Map<String, dynamic> body) {
    _messageController ??= StreamController<SlackMessage>.broadcast();

    final event = body['event'] as Map<String, dynamic>?;
    if (event != null && event['type'] == 'message') {
      final msg = SlackMessage.fromJson(event);
      
      // Ignore bot messages and threaded replies
      if (msg.botId == null && !msg.text.startsWith('thread_')) {
        _messageController?.add(msg);
      }
    }

    return _messageController!.stream;
  }

  /// Send message to channel
  Future<bool> postMessage(String channel, String text, {String? threadTs}) async {
    final uri = Uri.parse('$_apiUrl/chat.postMessage');

    final body = <String, dynamic>{
      'channel': channel,
      'text': text,
    };

    if (threadTs != null) {
      body['thread_ts'] = threadTs;
    }

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${config.botToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['ok'] == true;
    }
    return false;
  }

  /// Post ephemeral message (only visible to one user)
  Future<bool> postEphemeral(String channel, String userId, String text) async {
    final uri = Uri.parse('$_apiUrl/chat.postEphemeral');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${config.botToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'channel': channel,
        'user': userId,
        'text': text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['ok'] == true;
    }
    return false;
  }

  /// Update message
  Future<bool> updateMessage(String channel, String ts, String text) async {
    final uri = Uri.parse('$_apiUrl/chat.update');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${config.botToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'channel': channel,
        'ts': ts,
        'text': text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['ok'] == true;
    }
    return false;
  }

  /// Add reaction
  Future<bool> addReaction(String channel, String ts, String emoji) async {
    final uri = Uri.parse('$_apiUrl/reactions.add');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${config.botToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'channel': channel,
        'timestamp': ts,
        'name': emoji,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['ok'] == true;
    }
    return false;
  }

  /// Get user info
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final uri = Uri.parse('$_apiUrl/users.info?user=$userId');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${config.botToken}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['ok'] == true) return data['user'];
    }
    return null;
  }

  /// Get channel info
  Future<Map<String, dynamic>?> getChannel(String channelId) async {
    final uri = Uri.parse('$_apiUrl/conversations.info?channel=$channelId');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${config.botToken}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['ok'] == true) return data['channel'];
    }
    return null;
  }

  /// Open a direct message
  Future<String?> openDm(String userId) async {
    final uri = Uri.parse('$_apiUrl/conversations.open');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${config.botToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'users': userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['ok'] == true) {
        return data['channel']?['id'] as String?;
      }
    }
    return null;
  }

  void dispose() {
    _messageController?.close();
  }
}
