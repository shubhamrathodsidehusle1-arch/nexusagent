/// NexusAgent IRC Integration
/// Classic IRC protocol

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class IRCConfig {
  final String server;
  final int port;
  final String nick;
  final String? username;
  final String? realname;
  final String? password;
  final List<String> channels;
  final bool useTLS;

  IRCConfig({
    required this.server,
    this.port = 6667,
    required this.nick,
    this.username,
    this.realname,
    this.password,
    this.channels = const [],
    this.useTLS = false,
  });
}

class IRCMessage {
  final String prefix;
  final String command;
  final List<String> params;
  final String? sender;
  final String? message;

  IRCMessage({
    required this.prefix,
    required this.command,
    required this.params,
    this.sender,
    this.message,
  });
}

class IRCClient {
  final IRCConfig config;
  Socket? _socket;
  StreamController<IRCMessage>? _messageController;

  IRCClient(this.config);

  /// Connect to IRC server
  Stream<IRCMessage> connect() {
    _messageController = StreamController<IRCMessage>.broadcast();
    _connect();
    return _messageController!.stream;
  }

  Future<void> _connect() async {
    try {
      _socket = await Socket.connect(
        config.server,
        config.port,
        timeout: const Duration(seconds: 10),
      );

      // Send NICK and USER
      _send('NICK ${config.nick}');
      _send('USER ${config.username ?? config.nick} 0 * :${config.realname ?? config.nick}');

      if (config.password != null) {
        _send('PASS ${config.password}');
      }

      // Handle incoming data
      _socket!.listen(
        (data) => _handleData(utf8.decode(data)),
        onDone: () => _messageController?.close(),
        onError: (e) => _messageController?.addError(e),
      );

      // Join channels
      for (final channel in config.channels) {
        joinChannel(channel);
      }
    } catch (e) {
      _messageController?.addError(e);
    }
  }

  void _send(String message) {
    _socket?.write('$message\r\n');
  }

  void _handleData(String data) {
    for (final line in data.split('\r\n')) {
      if (line.isEmpty) continue;

      // Handle PING
      if (line.startsWith('PING')) {
        _send('PONG ${line.substring(5)}');
        continue;
      }

      // Parse IRC message
      final msg = _parseMessage(line);
      if (msg != null) {
        _messageController?.add(msg);
      }
    }
  }

  IRCMessage? _parseMessage(String line) {
    String prefix = '';
    String command;
    List<String> params = [];

    if (line.startsWith(':')) {
      final idx = line.indexOf(' ');
      prefix = line.substring(1, idx);
      line = line.substring(idx + 1);
    }

    final parts = line.split(' ');
    command = parts[0];

    if (parts.length > 1) {
      // Find trailing parameter (starts with :)
      int trailingIdx = -1;
      for (int i = 1; i < parts.length; i++) {
        if (parts[i].startsWith(':')) {
          trailingIdx = i;
          break;
        }
      }

      if (trailingIdx == -1) {
        params = parts.sublist(1);
      } else {
        params = parts.sublist(1, trailingIdx);
        params.add(parts.sublist(trailingIdx).join(' ').substring(1));
      }
    }

    return IRCMessage(
      prefix: prefix,
      command: command,
      params: params,
      sender: prefix.contains('!') ? prefix.split('!')[0] : prefix,
      message: params.isNotEmpty ? params.last : null,
    );
  }

  /// Send message to channel
  void sendMessage(String target, String message) {
    _send('PRIVMSG $target :$message');
  }

  /// Join channel
  void joinChannel(String channel) {
    _send('JOIN $channel');
  }

  /// Part channel
  void partChannel(String channel, {String? reason}) {
    _send('PART $channel${reason != null ? ' :$reason' : ''}');
  }

  /// Set topic
  void setTopic(String channel, String topic) {
    _send('TOPIC $channel :$topic');
  }

  /// Quit
  void quit({String? reason}) {
    _send('QUIT${reason != null ? ' :$reason' : ''}');
    _socket?.destroy();
  }

  void dispose() {
    quit();
    _messageController?.close();
  }
}
