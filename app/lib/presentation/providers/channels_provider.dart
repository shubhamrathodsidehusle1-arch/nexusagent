/// NexusAgent Channels Provider - Connected
/// Real channel management

import 'package:flutter/material.dart';
import '../../data/services/database_service.dart';
import '../../data/services/api_service.dart';
import '../../data/services/sync_service.dart';

class ChannelsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final ApiService _api = ApiService();
  final SyncService _sync = SyncService();

  List<Channel> _channels = [];
  bool _isLoading = false;
  String? _error;

  List<Channel> get channels => _channels;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Channel> get enabledChannels => 
      _channels.where((c) => c.enabled).toList();

  /// Load channels if authenticated
  Future<void> loadIfAuthenticated(bool isAuthenticated) async {
    if (isAuthenticated) {
      await loadChannels();
    }
  }

  /// Load all channels
  Future<void> loadChannels() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try local database first
      final dbChannels = await _db.getChannels();
      
      if (dbChannels.isNotEmpty) {
        _channels = dbChannels.map((c) => Channel.fromMap(c)).toList();
      } else {
        // Load demo channels
        _channels = _getDemoChannels();
        
        // Save to database
        for (final channel in _channels) {
          await _db.insertChannel(channel.toMap());
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get demo channels
  List<Channel> _getDemoChannels() {
    return [
      Channel(
        id: 'telegram',
        type: 'telegram',
        name: 'Telegram',
        enabled: true,
        config: {'botToken': '***'},
      ),
      Channel(
        id: 'discord',
        type: 'discord',
        name: 'Discord',
        enabled: true,
        config: {'token': '***'},
      ),
      Channel(
        id: 'whatsapp',
        type: 'whatsapp',
        name: 'WhatsApp',
        enabled: false,
        config: {},
      ),
      Channel(
        id: 'slack',
        type: 'slack',
        name: 'Slack',
        enabled: false,
        config: {},
      ),
      Channel(
        id: 'signal',
        type: 'signal',
        name: 'Signal',
        enabled: false,
        config: {},
      ),
      Channel(
        id: 'google_chat',
        type: 'google_chat',
        name: 'Google Chat',
        enabled: false,
        config: {},
      ),
      Channel(
        id: 'irc',
        type: 'irc',
        name: 'IRC',
        enabled: false,
        config: {},
      ),
      Channel(
        id: 'matrix',
        type: 'matrix',
        name: 'Matrix',
        enabled: false,
        config: {},
      ),
      Channel(
        id: 'imessage',
        type: 'imessage',
        name: 'iMessage',
        enabled: false,
        config: {},
      ),
      Channel(
        id: 'mattermost',
        type: 'mattermost',
        name: 'Mattermost',
        enabled: false,
        config: {},
      ),
      Channel(
        id: 'webchat',
        type: 'webchat',
        name: 'Web Chat',
        enabled: true,
        config: {},
      ),
    ];
  }

  /// Enable channel
  Future<void> enableChannel(String id) async {
    final index = _channels.indexWhere((c) => c.id == id);
    if (index != -1) {
      final channel = _channels[index];
      _channels[index] = Channel(
        id: channel.id,
        type: channel.type,
        name: channel.name,
        enabled: true,
        config: channel.config,
        createdAt: channel.createdAt,
      );
      notifyListeners();

      await _db.updateChannel(id, _channels[index].toMap());
    }
  }

  /// Disable channel
  Future<void> disableChannel(String id) async {
    final index = _channels.indexWhere((c) => c.id == id);
    if (index != -1) {
      final channel = _channels[index];
      _channels[index] = Channel(
        id: channel.id,
        type: channel.type,
        name: channel.name,
        enabled: false,
        config: channel.config,
        createdAt: channel.createdAt,
      );
      notifyListeners();

      await _db.updateChannel(id, _channels[index].toMap());
    }
  }

  /// Add channel
  Future<void> addChannel(Channel channel) async {
    _channels.add(channel);
    notifyListeners();

    await _db.insertChannel(channel.toMap());
  }

  /// Update channel config
  Future<void> updateChannelConfig(String id, Map<String, dynamic> config) async {
    final index = _channels.indexWhere((c) => c.id == id);
    if (index != -1) {
      final channel = _channels[index];
      _channels[index] = Channel(
        id: channel.id,
        type: channel.type,
        name: channel.name,
        enabled: channel.enabled,
        config: config,
        createdAt: channel.createdAt,
      );
      notifyListeners();

      await _db.updateChannel(id, _channels[index].toMap());
    }
  }

  /// Delete channel
  Future<void> deleteChannel(String id) async {
    _channels.removeWhere((c) => c.id == id);
    notifyListeners();

    await _db.deleteChannel(id);
  }

  /// Get channel by ID
  Channel? getChannel(String id) {
    return _channels.where((c) => c.id == id).firstOrNull;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class Channel {
  final String id;
  final String type;
  final String name;
  final bool enabled;
  final Map<String, dynamic> config;
  final DateTime createdAt;

  Channel({
    required this.id,
    required this.type,
    required this.name,
    required this.enabled,
    required this.config,
    required this.createdAt,
  });

  factory Channel.fromMap(Map<String, dynamic> map) {
    return Channel(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      name: map['name'] ?? '',
      enabled: map['enabled'] == 1 || map['enabled'] == true,
      config: map['config'] != null 
          ? Map<String, dynamic>.from(map['config']) 
          : {},
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'enabled': enabled ? 1 : 0,
      'config': config.toString(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  IconData get icon {
    switch (type) {
      case 'telegram':
        return Icons.send;
      case 'discord':
        return Icons.chat_bubble;
      case 'whatsapp':
        return Icons.phone;
      case 'slack':
        return Icons.work;
      case 'signal':
        return Icons.signal_cellular_alt;
      case 'google_chat':
        return Icons.chat;
      case 'irc':
        return Icons.terminal;
      case 'matrix':
        return Icons.grid_view;
      case 'imessage':
        return Icons.message;
      case 'mattermost':
        return Icons.groups;
      case 'webchat':
        return Icons.language;
      default:
        return Icons.chat;
    }
  }

  Color get color {
    switch (type) {
      case 'telegram':
        return Colors.blue;
      case 'discord':
        return Colors.purple;
      case 'whatsapp':
        return Colors.green;
      case 'slack':
        return Colors.pink;
      case 'signal':
        return Colors.teal;
      case 'google_chat':
        return Colors.blue;
      case 'irc':
        return Colors.brown;
      case 'matrix':
        return Colors.indigo;
      case 'imessage':
        return Colors.blue;
      case 'mattermost':
        return Colors.red;
      case 'webchat':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
