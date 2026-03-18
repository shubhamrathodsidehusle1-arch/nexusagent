/// NexusAgent WebSocket Server
/// Real-time messaging support

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketServer {
  static final WebSocketServer _instance = WebSocketServer._internal();
  factory WebSocketServer() => _instance;
  WebSocketServer._internal();

  final Map<String, WebSocketChannel> _clients = {};
  final Map<String, Set<String>> _clientRooms = {}; // room -> clientIds
  StreamController<WebSocketMessage>? _messageController;

  /// Start WebSocket server
  Future<void> start(int port) async {
    _messageController = StreamController<WebSocketMessage>.broadcast();
    print('WebSocket server would start on port $port');
    // In production, use shelf_web_socket or http.server with upgrade
  }

  /// Handle new connection
  void _handleConnection(WebSocketChannel channel, String clientId) {
    _clients[clientId] = channel;
    _clientRooms[clientId] = {};

    // Listen for messages
    channel.stream.listen(
      (data) => _handleMessage(clientId, data.toString()),
      onDone: () => _handleDisconnect(clientId),
      onError: (e) => _handleError(clientId, e),
    );

    print('Client connected: $clientId');
  }

  /// Handle incoming message
  void _handleMessage(String clientId, String data) {
    try {
      final message = jsonDecode(data) as Map<String, dynamic>;
      final type = message['type'] as String?;

      switch (type) {
        case 'join_room':
          _joinRoom(clientId, message['room'] as String);
          break;
        case 'leave_room':
          _leaveRoom(clientId, message['room'] as String);
          break;
        case 'broadcast':
          _broadcast(clientId, message['data'], message['room']);
          break;
        case 'ping':
          _send(clientId, {'type': 'pong'});
          break;
        default:
          _messageController?.add(WebSocketMessage(
            clientId: clientId,
            type: type ?? 'message',
            data: message,
          ));
      }
    } catch (e) {
      print('WebSocket message error: $e');
    }
  }

  /// Join room
  void _joinRoom(String clientId, String room) {
    _clientRooms[clientId] ??= {};
    _clientRooms[clientId]!.add(room);
    
    // Notify client
    _send(clientId, {
      'type': 'joined_room',
      'room': room,
    });
    
    print('$clientId joined room: $room');
  }

  /// Leave room
  void _leaveRoom(String clientId, String room) {
    _clientRooms[clientId]?.remove(room);
    
    _send(clientId, {
      'type': 'left_room',
      'room': room,
    });
  }

  /// Broadcast to room or all
  void _broadcast(String fromClientId, Map<String, dynamic> data, String? room) {
    final message = jsonEncode({
      'type': 'broadcast',
      'from': fromClientId,
      'data': data,
    });

    if (room == null) {
      // Broadcast to all
      for (final clientId in _clients.keys) {
        if (clientId != fromClientId) {
          _clients[clientId]?.sink.add(message);
        }
      }
    } else {
      // Broadcast to room
      for (final entry in _clientRooms.entries) {
        if (entry.key != fromClientId && entry.value.contains(room)) {
          _clients[entry.key]?.sink.add(message);
        }
      }
    }
  }

  /// Send to specific client
  void _send(String clientId, Map<String, dynamic> data) {
    _clients[clientId]?.sink.add(jsonEncode(data));
  }

  /// Handle disconnect
  void _handleDisconnect(String clientId) {
    _clients.remove(clientId);
    _clientRooms.remove(clientId);
    print('Client disconnected: $clientId');
  }

  /// Handle error
  void _handleError(String clientId, dynamic error) {
    print('Client error: $clientId - $error');
  }

  /// Send to client (public)
  void send(String clientId, Map<String, dynamic> data) {
    _send(clientId, data);
  }

  /// Broadcast (public)
  void broadcast(String fromClientId, Map<String, dynamic> data, {String? room}) {
    _broadcast(fromClientId, data, room);
  }

  /// Get connected clients
  List<String> get clients => _clients.keys.toList();

  /// Get client count
  int get clientCount => _clients.length;

  /// Stream of messages
  Stream<WebSocketMessage> get messages => _messageController!.stream;

  /// Stop server
  void stop() {
    for (final channel in _clients.values) {
      channel.sink.close();
    }
    _clients.clear();
    _clientRooms.clear();
    _messageController?.close();
    print('WebSocket server stopped');
  }
}

class WebSocketMessage {
  final String clientId;
  final String type;
  final Map<String, dynamic> data;

  WebSocketMessage({
    required this.clientId,
    required this.type,
    required this.data,
  });
}
