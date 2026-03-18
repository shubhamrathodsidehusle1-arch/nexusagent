/// NexusAgent Matrix Integration
/// Matrix protocol - decentralized communication

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MatrixConfig {
  final String homeserver;
  final String accessToken;
  final String userId;
  final String? deviceId;
  final List<String> rooms;

  MatrixConfig({
    required this.homeserver,
    required this.accessToken,
    required this.userId,
    this.deviceId,
    this.rooms = const [],
  });
}

class MatrixClient {
  final MatrixConfig config;
  final http.Client _client = http.Client();
  String? _syncToken;
  Timer? _syncTimer;
  StreamController<Map<String, dynamic>>? _eventController;

  MatrixClient(this.config);

  /// Start syncing
  Stream<Map<String, dynamic>> startSync() {
    _eventController = StreamController<Map<String, dynamic>>.broadcast();
    _startSyncLoop();
    return _eventController!.stream;
  }

  void _startSyncLoop() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => _sync());
    _sync(); // Initial sync
  }

  Future<void> _sync() async {
    try {
      var url = '${config.homeserver}/_matrix/client/r0/sync?timeout=30000';
      if (_syncToken != null) url += '&since=$_syncToken';

      final response = await _client.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${config.accessToken}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _syncToken = data['next_batch'];
        
        // Process rooms
        final rooms = data['rooms'] as Map<String, dynamic>?;
        if (rooms != null) {
          final join = rooms['join'] as Map<String, dynamic>?;
          if (join != null) {
            for (final entry in join.entries) {
              final roomEvents = entry.value['timeline']?['events'] as List?;
              if (roomEvents != null) {
                for (final event in roomEvents) {
                  if (event['type'] == 'm.room.message') {
                    _eventController?.add({
                      'room_id': entry.key,
                      'sender': event['sender'],
                      'content': event['content'],
                      'type': event['type'],
                    });
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      _eventController?.addError(e);
    }
  }

  /// Send message to room
  Future<bool> sendMessage(String roomId, String message, {String? txId}) async {
    final txnId = txId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final response = await _client.put(
      Uri.parse(
        '${config.homeserver}/_matrix/client/r0/rooms/$roomId/send/m.room.message/$txnId',
      ),
      headers: {
        'Authorization': 'Bearer ${config.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'msgtype': 'm.text',
        'body': message,
      }),
    );

    return response.statusCode == 200;
  }

  /// Join room
  Future<bool> joinRoom(String roomIdOrAlias) async {
    final response = await _client.post(
      Uri.parse(
        '${config.homeserver}/_matrix/client/r0/join/$roomIdOrAlias',
      ),
      headers: {
        'Authorization': 'Bearer ${config.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    return response.statusCode == 200;
  }

  /// Leave room
  Future<bool> leaveRoom(String roomId) async {
    final response = await _client.post(
      Uri.parse(
        '${config.homeserver}/_matrix/client/r0/rooms/$roomId/leave',
      ),
      headers: {
        'Authorization': 'Bearer ${config.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    return response.statusCode == 200;
  }

  /// Get room members
  Future<List<String>> getRoomMembers(String roomId) async {
    final response = await _client.get(
      Uri.parse(
        '${config.homeserver}/_matrix/client/r0/rooms/$roomId/members',
      ),
      headers: {'Authorization': 'Bearer ${config.accessToken}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final members = data['chunk'] as List?;
      return members?.map((m) => m['state_key'] as String).toList() ?? [];
    }
    return [];
  }

  void stop() {
    _syncTimer?.cancel();
    _eventController?.close();
  }

  void dispose() {
    stop();
    _client.close();
  }
}
