/// NexusAgent Google Chat Integration
/// Google Chat API via HTTP webhook

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleChatConfig {
  final String botUrl; // Webhook URL
  final String spaceName;

  GoogleChatConfig({
    required this.botUrl,
    this.spaceName = '',
  });
}

class GoogleChatMessage {
  final String sender;
  final String message;
  final String? threadKey;

  GoogleChatMessage({
    required this.sender,
    required this.message,
    this.threadKey,
  });
}

class GoogleChatClient {
  final GoogleChatConfig config;
  final http.Client _client = http.Client();

  GoogleChatClient(this.config);

  /// Send message
  Future<bool> send(String message, {String? threadKey}) async {
    final body = {
      'message': {
        'text': message,
        if (threadKey != null)
          'thread': {'threadKey': threadKey},
      },
    };

    try {
      final response = await _client.post(
        Uri.parse(config.botUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Send card (rich UI)
  Future<bool> sendCard(String title, String description, {List<Map<String, String>>? buttons}) async {
    final card = {
      'cardsV2': [
        {
          'cardId': 'nexusagent',
          'card': {
            'header': {'title': title},
            'sections': [
              {
                'widgets': [
                  {'textParagraph': {'text': description}},
                  if (buttons != null)
                    {
                      'buttonList': {
                        'buttons': buttons.map((b) => {
                          'text': b['text'] ?? '',
                          'onClick': {'openLink': {'url': b['url'] ?? ''}},
                        }).toList(),
                      },
                    },
                ],
              },
            ],
          },
        },
      ],
    };

    try {
      final response = await _client.post(
        Uri.parse(config.botUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(card),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() => _client.close();
}
