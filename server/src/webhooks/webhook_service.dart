/// NexusAgent Webhook Service
/// Event webhooks with signature verification

import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class WebhookEvent {
  final String id;
  final String type;
  final String timestamp;
  final Map<String, dynamic> data;

  WebhookEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
  });
}

class WebhookConfig {
  final String url;
  final String? secret;
  final String? path;
  final List<String> events;
  final bool enabled;

  WebhookConfig({
    required this.url,
    this.secret,
    this.path,
    this.events = const [],
    this.enabled = true,
  });
}

class WebhookDelivery {
  final String webhookId;
  final String eventId;
  final String url;
  final int attempts;
  final int? statusCode;
  final String? error;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  WebhookDelivery({
    required this.webhookId,
    required this.eventId,
    required this.url,
    this.attempts = 0,
    this.statusCode,
    this.error,
    required this.createdAt,
    this.deliveredAt,
  });
}

class WebhookService {
  static final WebhookService _instance = WebhookService._internal();
  factory WebhookService() => _instance;
  WebhookService._internal();

  final Map<String, WebhookConfig> _webhooks = {};
  final List<WebhookDelivery> _deliveries = [];
  final http.Client _client = http.Client();

  // Supported events
  static const List<String> supportedEvents = [
    'session.start',
    'session.end',
    'session.message',
    'agent.run.start',
    'agent.run.complete',
    'agent.run.error',
    'tool.execute',
    'tool.error',
    'channel.connected',
    'channel.disconnected',
    'user.invited',
    'user.removed',
    'workflow.triggered',
    'workflow.completed',
    'workflow.error',
  ];

  /// Register webhook
  void registerWebhook(String id, WebhookConfig config) {
    _webhooks[id] = config;
    print('Webhook registered: $id -> ${config.url}');
  }

  /// Remove webhook
  void removeWebhook(String id) {
    _webhooks.remove(id);
  }

  /// Get webhook
  WebhookConfig? getWebhook(String id) => _webhooks[id];

  /// List webhooks
  List<Map<String, dynamic>> listWebhooks() {
    return _webhooks.entries.map((e) => {
      'id': e.key,
      'url': e.value.url,
      'events': e.value.events,
      'enabled': e.value.enabled,
    }).toList();
  }

  /// Trigger event
  Future<void> triggerEvent(String eventType, Map<String, dynamic> data) async {
    // Find matching webhooks
    for (final entry in _webhooks.entries) {
      final webhook = entry.value;
      
      // Check if enabled
      if (!webhook.enabled) continue;
      
      // Check if subscribed to event
      if (webhook.events.isNotEmpty && !webhook.events.contains(eventType)) {
        continue;
      }

      // Queue delivery
      _queueDelivery(entry.key, eventType, data);
    }
  }

  /// Queue webhook delivery
  void _queueDelivery(String webhookId, String eventType, Map<String, dynamic> data) async {
    final webhook = _webhooks[webhookId];
    if (webhook == null) return;

    final event = WebhookEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: eventType,
      timestamp: DateTime.now().toIso8601String(),
      data: data,
    );

    // Create delivery record
    final delivery = WebhookDelivery(
      webhookId: webhookId,
      eventId: event.id,
      url: webhook.url,
      createdAt: DateTime.now(),
    );
    _deliveries.add(delivery);

    // Send webhook
    await _sendWebhook(webhook, event, delivery);
  }

  /// Send webhook
  Future<void> _sendWebhook(WebhookConfig webhook, WebhookEvent event, WebhookDelivery delivery) async {
    final body = jsonEncode(event.toJson());

    // Sign payload if secret provided
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Webhook-Event': event.type,
      'X-Webhook-Id': event.id,
    };

    if (webhook.secret != null) {
      final signature = _sign(body, webhook.secret!);
      headers['X-Webhook-Signature'] = signature;
    }

    try {
      final response = await _client.post(
        Uri.parse(webhook.url),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      // Update delivery status
      delivery.statusCode = response.statusCode;
      delivery.deliveredAt = DateTime.now();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Webhook delivered: ${event.type} -> ${webhook.url}');
      } else {
        print('Webhook failed: ${response.statusCode}');
      }
    } catch (e) {
      delivery.error = e.toString();
      print('Webhook error: $e');
    }
  }

  /// Sign payload
  String _sign(String payload, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// Verify signature
  bool verifySignature(String payload, String signature, String secret) {
    final expected = _sign(payload, secret);
    return expected == signature;
  }

  /// Get delivery history
  List<WebhookDelivery> getDeliveries({String? webhookId, int limit = 50}) {
    var deliveries = _deliveries;
    
    if (webhookId != null) {
      deliveries = deliveries.where((d) => d.webhookId == webhookId).toList();
    }

    deliveries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return deliveries.take(limit).toList();
  }

  /// Test webhook
  Future<bool> testWebhook(String id) async {
    final webhook = _webhooks[id];
    if (webhook == null) return false;

    final event = WebhookEvent(
      id: 'test-${DateTime.now().millisecondsSinceEpoch}',
      type: 'test',
      timestamp: DateTime.now().toIso8601String(),
      data: {'message': 'Test webhook'},
    );

    try {
      final response = await _client.post(
        Uri.parse(webhook.url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(event.toJson()),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

extension WebhookEventExtension on WebhookEvent {
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'timestamp': timestamp,
    'data': data,
  };
}
