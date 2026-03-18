/// NexusAgent Telegram Integration
/// Connects to Telegram Bot API

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TelegramConfig {
  final String botToken;
  final String? webhookUrl;
  final int? allowedUpdateId;

  TelegramConfig({
    required this.botToken,
    this.webhookUrl,
    this.allowedUpdateId,
  });
}

class TelegramUpdate {
  final int updateId;
  final int? messageId;
  final String? text;
  final String chatId;
  final String? firstName;
  final String? username;

  TelegramUpdate({
    required this.updateId,
    this.messageId,
    this.text,
    required this.chatId,
    this.firstName,
    this.username,
  });

  factory TelegramUpdate.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return TelegramUpdate(
        updateId: 0,
        chatId: '',
      );
    }
    
    final message = json['message'] as Map<String, dynamic>?;
    final chat = message?['chat'] as Map<String, dynamic>?;

    return TelegramUpdate(
      updateId: json['update_id'] as int? ?? 0,
      messageId: message?['message_id'] as int?,
      text: message?['text'] as String?,
      chatId: chat?['id']?.toString() ?? '',
      firstName: message?['from']?['first_name'] as String?,
      username: message?['from']?['username'] as String?,
    );
  }
}

class TelegramBot {
  final TelegramConfig config;
  final String _baseUrl = 'https://api.telegram.org';

  StreamController<TelegramUpdate>? _updatesController;
  Timer? _pollingTimer;
  int? _lastUpdateId;

  TelegramBot(this.config);

  /// Start polling for updates
  Stream<TelegramUpdate> startPolling() {
    _updatesController = StreamController<TelegramUpdate>.broadcast();
    _poll();
    return _updatesController!.stream;
  }

  /// Set webhook
  Future<bool> setWebhook(String url) async {
    final uri = Uri.parse('$_baseUrl/bot${config.botToken}/setWebhook');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': url}),
    );
    return response.statusCode == 200;
  }

  /// Delete webhook
  Future<bool> deleteWebhook() async {
    final uri = Uri.parse('$_baseUrl/bot${config.botToken}/deleteWebhook');
    final response = await http.get(uri);
    return response.statusCode == 200;
  }

  /// Poll for updates
  void _poll() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        await _fetchUpdates();
      } catch (e) {
        print('Telegram polling error: $e');
      }
    });
  }

  Future<void> _fetchUpdates() async {
    final uri = Uri.parse(
      '$_baseUrl/bot${config.botToken}/getUpdates?timeout=30'
      '${_lastUpdateId != null ? '&offset=${_lastUpdateId! + 1}' : ''}',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return;

    final data = jsonDecode(response.body);
    if (data['ok'] != true) return;

    final updates = (data['result'] as List)
        .map((u) => TelegramUpdate.fromJson(u))
        .toList();

    for (final update in updates) {
      _lastUpdateId = update.updateId;
      _updatesController?.add(update);
    }
  }

  /// Send message
  Future<bool> sendMessage(String chatId, String text, {Map<String, dynamic>? replyMarkup}) async {
    final uri = Uri.parse('$_baseUrl/bot${config.botToken}/sendMessage');

    final body = {
      'chat_id': chatId,
      'text': text,
      'parse_mode': 'Markdown',
    };

    if (replyMarkup != null) {
      body['reply_markup'] = replyMarkup;
    }

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  /// Send inline keyboard
  Future<bool> sendWithKeyboard(String chatId, String text, List<List<String>> buttons) async {
    final keyboard = buttons.map((row) =>
      row.map((label) => {'text': label}).toList()
    ).toList();

    return sendMessage(chatId, text, replyMarkup: {
      'inline_keyboard': keyboard,
    });
  }

  /// Getme
  Future<Map<String, dynamic>?> getMe() async {
    final uri = Uri.parse('$_baseUrl/bot${config.botToken}/getMe');
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['ok'] == true) return data['result'];
    }
    return null;
  }

  /// Stop polling
  void stop() {
    _pollingTimer?.cancel();
    _updatesController?.close();
  }
}
