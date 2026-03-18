/// NexusAgent Discord Integration
/// Connects to Discord Bot API (Gateway + REST)

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DiscordConfig {
  final String botToken;
  final List<int> guildIds;
  final List<String> channelIds;

  DiscordConfig({
    required this.botToken,
    this.guildIds = const [],
    this.channelIds = const [],
  });
}

class DiscordMessage {
  final String id;
  final String channelId;
  final String content;
  final String? authorId;
  final String? authorName;
  final String? guildId;
  final bool isBot;

  DiscordMessage({
    required this.id,
    required this.channelId,
    required this.content,
    this.authorId,
    this.authorName,
    this.guildId,
    this.isBot = false,
  });

  factory DiscordMessage.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return DiscordMessage(
        id: '',
        channelId: '',
        content: '',
      );
    }
    
    final author = json['author'] as Map<String, dynamic>?;

    return DiscordMessage(
      id: json['id'] as String? ?? '',
      channelId: json['channel_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      authorId: author?['id'] as String?,
      authorName: author?['username'] as String?,
      guildId: json['guild_id'] as String?,
      isBot: author?['bot'] as bool? ?? false,
    );
  }
}

class DiscordBot {
  final DiscordConfig config;
  final String _apiUrl = 'https://discord.com/api/v10';

  WebSocket? _gateway;
  StreamController<DiscordMessage>? _messageController;
  Timer? _heartbeatTimer;
  int _sequenceNum;
  String? _sessionId;
  String? _gatewayUrl;

  DiscordBot(this.config) : _sequenceNum = 0;

  /// Start bot (connect to gateway)
  Stream<DiscordMessage> start() {
    _messageController = StreamController<DiscordMessage>.broadcast();
    _connectGateway();
    return _messageController!.stream;
  }

  /// Connect to Discord Gateway
  Future<void> _connectGateway() async {
    // Get gateway URL
    final response = await http.get(
      Uri.parse('$_apiUrl/gateway/bot'),
      headers: {'Authorization': 'Bot ${config.botToken}'},
    );

    if (response.statusCode != 200) {
      print('Failed to get gateway: ${response.statusCode}');
      return;
    }

    final data = jsonDecode(response.body);
    _gatewayUrl = data['url'] as String;

    // Connect via WebSocket (simplified - would use web_socket_channel in production)
    print('Discord: Would connect to $_gatewayUrl');
    
    // Start heartbeat simulation
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendHeartbeat();
    });
  }

  /// Identify with Discord
  Future<void> _identify() async {
    // Would send Identify payload
    print('Discord: Identifying bot...');
  }

  /// Send heartbeat
  void _sendHeartbeat() {
    // Would send heartbeat opcode
    // print('Discord: Heartbeat sent');
  }

  /// Handle message create
  void _handleMessageCreate(Map<String, dynamic> data) {
    final message = DiscordMessage.fromJson(data);
    
    // Ignore bot messages
    if (message.isBot) return;
    
    // Check channel whitelist
    if (config.channelIds.isNotEmpty && !config.channelIds.contains(message.channelId)) {
      return;
    }

    _messageController?.add(message);
  }

  /// Send message to channel
  Future<bool> sendMessage(String channelId, String content, {Embed? embed}) async {
    final uri = Uri.parse('$_apiUrl/channels/$channelId/messages');

    final body = <String, dynamic>{
      'content': content,
    };

    if (embed != null) {
      body['embeds'] = [embed.toJson()];
    }

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bot ${config.botToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  /// Send embed
  Future<bool> sendEmbed(String channelId, Embed embed) async {
    return sendMessage(channelId, '', embed: embed);
  }

  /// Create DM
  Future<String?> createDm(String userId) async {
    final uri = Uri.parse('$_apiUrl/users/@me/channels');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bot ${config.botToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'recipient_id': userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'] as String;
    }
    return null;
  }

  /// Add reaction
  Future<bool> addReaction(String channelId, String messageId, String emoji) async {
    final encodedEmoji = Uri.encodeComponent(emoji);
    final uri = Uri.parse('$_apiUrl/channels/$channelId/messages/$messageId/reactions/$encodedEmoji/@me');

    final response = await http.put(
      uri,
      headers: {'Authorization': 'Bot ${config.botToken}'},
    );

    return response.statusCode == 200;
  }

  /// Stop bot
  void stop() {
    _heartbeatTimer?.cancel();
    _messageController?.close();
    _gateway?.close();
  }
}

class Embed {
  final String? title;
  final String? description;
  final int? color;
  final String? footer;
  final String? imageUrl;

  Embed({
    this.title,
    this.description,
    this.color,
    this.footer,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    
    if (title != null) json['title'] = title;
    if (description != null) json['description'] = description;
    if (color != null) json['color'] = color;
    if (footer != null) json['footer'] = {'text': footer};
    if (imageUrl != null) json['image'] = {'url': imageUrl};
    
    return json;
  }
}
