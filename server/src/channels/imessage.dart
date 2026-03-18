/// NexusAgent iMessage Integration (macOS)
/// Uses native macOS imsg CLI

import 'dart:async';
import 'dart:io';

class IMessageConfig {
  final bool enabled;
  final List<String> allowedContacts;

  IMessageConfig({
    this.enabled = true,
    this.allowedContacts = const [],
  });
}

class IMessageMessage {
  final String id;
  final String sender;
  final String recipient;
  final String text;
  final DateTime timestamp;
  final bool isIncoming;

  IMessageMessage({
    required this.id,
    required this.sender,
    required this.recipient,
    required this.text,
    required this.timestamp,
    required this.isIncoming,
  });
}

class IMessageClient {
  final IMessageConfig config;
  Process? _listener;
  StreamController<IMessageMessage>? _messageController;

  IMessageClient(this.config);

  /// Start listening for messages
  Stream<IMessageMessage> startListening() {
    _messageController = StreamController<IMessageMessage>.broadcast();
    _startListener();
    return _messageController!.stream;
  }

  void _startListener() async {
    // In production, would use imsg CLI or native bridge
    // For now, mock
    print('iMessage: Listener would start on macOS');
  }

  /// Send message
  Future<bool> sendMessage(String recipient, String text) async {
    // Check allowlist
    if (config.allowedContacts.isNotEmpty && 
        !config.allowedContacts.contains(recipient)) {
      return false;
    }

    try {
      // Use imsg CLI
      final result = await Process.run('imsg', [
        recipient,
        text,
      ]);

      return result.exitCode == 0;
    } catch (e) {
      print('iMessage send error: $e');
      return false;
    }
  }

  /// Send attachment
  Future<bool> sendAttachment(String recipient, String filePath) async {
    if (config.allowedContacts.isNotEmpty && 
        !config.allowedContacts.contains(recipient)) {
      return false;
    }

    try {
      final result = await Process.run('imsg', [
        recipient,
        '-a',
        filePath,
      ]);

      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Get chat history
  Future<List<IMessageMessage>> getHistory(String contact, {int limit = 50}) async {
    try {
      final result = await Process.run('imsg', [
        'history',
        contact,
        '-n', limit.toString(),
      ]);

      if (result.exitCode == 0) {
        // Parse output
        return [];
      }
    } catch (e) {
      // Ignore
    }
    return [];
  }

  /// Stop listening
  void stopListening() {
    _listener?.kill();
    _messageController?.close();
  }
}
