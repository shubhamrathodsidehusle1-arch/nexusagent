/// NexusAgent WhatsApp Integration
/// Connects to WhatsApp Business API or WhatsApp Web

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WhatsAppConfig {
  final String phoneNumberId;
  final String accessToken;
  final String? webhookVerifyToken;

  WhatsAppConfig({
    required this.phoneNumberId,
    required this.accessToken,
    this.webhookVerifyToken,
  });
}

class WhatsAppMessage {
  final String id;
  final String from;
  final String type;
  final String? text;
  final Map<String, dynamic>? interactive;

  WhatsAppMessage({
    required this.id,
    required this.from,
    required this.type,
    this.text,
    this.interactive,
  });

  factory WhatsAppMessage.fromEntry(Map<String, dynamic> entry) {
    if (entry == null) {
      return WhatsAppMessage(
        id: '',
        from: '',
        type: 'text',
      );
    }
    
    final changes = entry['changes'] as List?;
    final value = changes?.first['value'] as Map<String, dynamic>?;
    final messages = value?['messages'] as List?;
    final msg = messages?.first;

    String? text;
    if (msg?['type'] == 'text') {
      text = msg?['text']?['body'];
    }

    return WhatsAppMessage(
      id: msg?['id'] as String? ?? '',
      from: msg?['from'] as String? ?? '',
      type: msg?['type'] as String? ?? 'text',
      text: text,
      interactive: msg?['interactive'] as Map<String, dynamic>?,
    );
  }
}

class WhatsAppClient {
  final WhatsAppConfig config;
  final String _apiUrl = 'https://graph.facebook.com/v18.0';

  StreamController<WhatsAppMessage>? _messageController;

  WhatsAppClient(this.config);

  /// Verify webhook
  String? verifyWebhook(String? mode, String? token, String? challenge) {
    if (mode == 'subscribe' && token == config.webhookVerifyToken) {
      return challenge;
    }
    return null;
  }

  /// Handle incoming webhook
  Stream<WhatsAppMessage> handleWebhook(Map<String, dynamic> body) {
    _messageController ??= StreamController<WhatsAppMessage>.broadcast();

    final entries = body['entry'] as List?;
    if (entries != null) {
      for (final entry in entries) {
        final msg = WhatsAppMessage.fromEntry(entry);
        _messageController?.add(msg);
      }
    }

    return _messageController!.stream;
  }

  /// Send text message
  Future<bool> sendMessage(String to, String text) async {
    final uri = Uri.parse('$_apiUrl/${config.phoneNumberId}/messages');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${config.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'messaging_product': 'whatsapp',
        'to': to,
        'type': 'text',
        'text': {'body': text},
      }),
    );

    return response.statusCode == 200;
  }

  /// Send template message
  Future<bool> sendTemplate(String to, String templateName, {List<String>? params}) async {
    final uri = Uri.parse('$_apiUrl/${config.phoneNumberId}/messages');

    Map<String, dynamic> components = {};
    if (params != null) {
      components = {
        'type': 'body',
        'parameters': params.map((p) => {'type': 'text', 'text': p}).toList(),
      };
    }

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${config.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'messaging_product': 'whatsapp',
        'to': to,
        'type': 'template',
        'template': {
          'name': templateName,
          'language': {'code': 'en_US'},
          if (params != null) 'components': [components],
        },
      }),
    );

    return response.statusCode == 200;
  }

  /// Send interactive buttons
  Future<bool> sendButtons(String to, String text, List<String> buttons) async {
    final uri = Uri.parse('$_apiUrl/${config.phoneNumberId}/messages');

    final buttonOptions = buttons.asMap().entries.map((e) => {
      'type': 'reply',
      'reply': {'id': 'btn_${e.key}', 'title': e.value},
    }).toList();

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${config.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'messaging_product': 'whatsapp',
        'to': to,
        'type': 'interactive',
        'interactive': {
          'type': 'button',
          'body': {'text': text},
          'action': {'buttons': buttonOptions},
        },
      }),
    );

    return response.statusCode == 200;
  }

  void dispose() {
    _messageController?.close();
  }
}
