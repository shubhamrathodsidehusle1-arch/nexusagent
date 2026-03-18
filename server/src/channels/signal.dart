/// NexusAgent Signal Integration
/// Connects to Signal Private Messenger via CLI (signal-cli)

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SignalConfig {
  final String phoneNumber;
  final String? signalCliPath;
  final List<String> allowedNumbers;

  SignalConfig({
    required this.phoneNumber,
    this.signalCliPath = 'signal-cli',
    this.allowedNumbers = const [],
  });
}

class SignalMessage {
  final String id;
  final String sender;
  final String recipient;
  final String body;
  final DateTime timestamp;

  SignalMessage({
    required this.id,
    required this.sender,
    required this.recipient,
    required this.body,
    required this.timestamp,
  });
}

class SignalClient {
  final SignalConfig config;

  StreamController<SignalMessage>? _messageController;
  Process? _daemonProcess;

  SignalClient(this.config);

  /// Start receiving messages (daemon mode)
  Stream<SignalMessage> start() {
    _messageController = StreamController<SignalMessage>.broadcast();
    _startDaemon();
    return _messageController!.stream;
  }

  /// Start signal-cli daemon
  void _startDaemon() async {
    try {
      // Start signal-cli in receive mode
      _daemonProcess = await Process.start(
        config.signalCliPath,
        ['-u', config.phoneNumber, 'receive', '--json'],
      );

      _daemonProcess!.stdout.transform(utf8.decoder).listen((data) {
        _handleOutput(data);
      });

      _daemonProcess!.stderr.transform(utf8.decoder).listen((data) {
        print('Signal CLI error: $data');
      });
    } catch (e) {
      print('Failed to start Signal daemon: $e');
    }
  }

  /// Handle incoming messages
  void _handleOutput(String data) {
    // Parse JSON messages from signal-cli
    for (final line in data.split('\n')) {
      if (line.trim().isEmpty) continue;
      
      try {
        final json = jsonDecode(line);
        
        // Check if it's an envelope (incoming message)
        if (json['envelope'] != null) {
          final envelope = json['envelope'];
          final source = envelope['source'] as String?;
          
          // Check allowlist
          if (config.allowedNumbers.isNotEmpty && 
              !config.allowedNumbers.contains(source)) {
            continue;
          }

          final message = SignalMessage(
            id: envelope['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            sender: source ?? '',
            recipient: config.phoneNumber,
            body: envelope['message'] ?? '',
            timestamp: DateTime.now(),
          );

          _messageController?.add(message);
        }
      } catch (e) {
        // Not JSON, ignore
      }
    }
  }

  /// Send message
  Future<bool> send(String recipient, String message) async {
    // Check allowlist
    if (config.allowedNumbers.isNotEmpty && 
        !config.allowedNumbers.contains(recipient)) {
      return false;
    }

    try {
      final result = await Process.run(
        config.signalCliPath,
        [
          '-u', config.phoneNumber,
          'send',
          '-m', message,
          recipient,
        ],
      );

      return result.exitCode == 0;
    } catch (e) {
      print('Signal send error: $e');
      return false;
    }
  }

  /// Send attachment
  Future<bool> sendAttachment(String recipient, String filePath) async {
    if (config.allowedNumbers.isNotEmpty && 
        !config.allowedNumbers.contains(recipient)) {
      return false;
    }

    try {
      final result = await Process.run(
        config.signalCliPath,
        [
          '-u', config.phoneNumber,
          'send',
          '--attachment', filePath,
          recipient,
        ],
      );

      return result.exitCode == 0;
    } catch (e) {
      print('Signal attachment error: $e');
      return false;
    }
  }

  /// Get account info
  Future<Map<String, dynamic>?> getAccountInfo() async {
    try {
      final result = await Process.run(
        config.signalCliPath,
        ['-u', config.phoneNumber, 'account'],
      );

      if (result.exitCode == 0) {
        // Parse output
        return {'output': result.stdout};
      }
    } catch (e) {
      print('Signal account error: $e');
    }
    return null;
  }

  /// Join group
  Future<bool> joinGroup(String groupId) async {
    try {
      final result = await Process.run(
        config.signalCliPath,
        [
          '-u', config.phoneNumber,
          'update-group',
          '-g', groupId,
        ],
      );

      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Leave group
  Future<bool> leaveGroup(String groupId) async {
    try {
      final result = await Process.run(
        config.signalCliPath,
        [
          '-u', config.phoneNumber,
          'quit-group',
          '-g', groupId,
        ],
      );

      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Stop daemon
  void stop() {
    _daemonProcess?.kill();
    _messageController?.close();
  }
}
