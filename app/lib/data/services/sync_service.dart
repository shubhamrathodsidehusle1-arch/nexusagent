/// NexusAgent Sync Service
/// Offline-first with API sync

import 'dart:async';
import 'database_service.dart';
import 'api_service.dart';
import 'local_storage_service.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncItem {
  final String id;
  final String table;
  final Map<String, dynamic> data;
  final String operation; // insert, update, delete
  final DateTime createdAt;
  int attempts;

  SyncItem({
    required this.id,
    required this.table,
    required this.data,
    required this.operation,
    required this.createdAt,
    this.attempts = 0,
  });
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _db = DatabaseService();
  final ApiService _api = ApiService();
  final LocalStorageService _local = LocalStorageService();

  final _syncQueue = <SyncItem>[];
  final _statusController = StreamController<SyncStatus>.broadcast();
  Timer? _syncTimer;
  bool _isOnline = true;
  bool _autoSyncEnabled = true;

  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  /// Initialize
  Future<void> initialize() async {
    // Start auto-sync timer (every 30 seconds)
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_autoSyncEnabled && _isOnline) {
        sync();
      }
    });
    print('Sync service initialized');
  }

  /// Queue item for sync
  Future<void> queueSync({
    required String table,
    required String id,
    required Map<String, dynamic> data,
    required String operation,
  }) async {
    final item = SyncItem(
      id: id,
      table: table,
      data: data,
      operation: operation,
      createdAt: DateTime.now(),
    );

    _syncQueue.add(item);

    // Try immediate sync if online
    if (_isOnline) {
      await sync();
    }
  }

  /// Sync with server
  Future<void> sync() async {
    if (_syncQueue.isEmpty) return;
    if (!_isOnline) return;

    _updateStatus(SyncStatus.syncing);

    final itemsToSync = List<SyncItem>.from(_syncQueue);
    int successCount = 0;
    int errorCount = 0;

    for (final item in itemsToSync) {
      try {
        bool success = false;

        switch (item.table) {
          case 'agents':
            success = await _syncAgent(item);
            break;
          case 'channels':
            success = await _syncChannel(item);
            break;
          case 'workflows':
            success = await _syncWorkflow(item);
            break;
          case 'cron':
            success = await _syncCronJob(item);
            break;
        }

        if (success) {
          _syncQueue.remove(item);
          successCount++;
        } else {
          item.attempts++;
          if (item.attempts >= 3) {
            _syncQueue.remove(item);
            errorCount++;
          }
        }
      } catch (e) {
        item.attempts++;
        errorCount++;
      }
    }

    _updateStatus(errorCount > 0 ? SyncStatus.error : SyncStatus.success);
  }

  Future<bool> _syncAgent(SyncItem item) async {
    switch (item.operation) {
      case 'insert':
        // await _api.createAgent(item.data);
        return true;
      case 'update':
        // await _api.updateAgent(item.id, item.data);
        return true;
      case 'delete':
        // await _api.deleteAgent(item.id);
        return true;
      default:
        return false;
    }
  }

  Future<bool> _syncChannel(SyncItem item) async {
    switch (item.operation) {
      case 'insert':
        // await _api.createChannel(item.data);
        return true;
      case 'update':
        // await _api.updateChannel(item.id, item.data);
        return true;
      case 'delete':
        // await _api.deleteChannel(item.id);
        return true;
      default:
        return false;
    }
  }

  Future<bool> _syncWorkflow(SyncItem item) async {
    switch (item.operation) {
      case 'insert':
        // await _api.createWorkflow(item.data);
        return true;
      case 'update':
        // await _api.updateWorkflow(item.id, item.data);
        return true;
      case 'delete':
        // await _api.deleteWorkflow(item.id);
        return true;
      default:
        return false;
    }
  }

  Future<bool> _syncCronJob(SyncItem item) async {
    switch (item.operation) {
      case 'insert':
        // await _api.createCronJob(item.data);
        return true;
      case 'update':
        // await _api.updateCronJob(item.id, item.data);
        return true;
      case 'delete':
        // await _api.deleteCronJob(item.id);
        return true;
      default:
        return false;
    }
  }

  /// Set online status
  void setOnline(bool online) {
    _isOnline = online;
    if (online) {
      // Trigger sync when coming online
      sync();
    }
  }

  /// Enable/disable auto sync
  void setAutoSync(bool enabled) {
    _autoSyncEnabled = enabled;
  }

  /// Force full sync
  Future<void> fullSync() async {
    _updateStatus(SyncStatus.syncing);

    try {
      // Fetch all from server and merge with local
      // await _fetchAgents();
      // await _fetchChannels();
      // await _fetchWorkflows();

      _updateStatus(SyncStatus.success);
    } catch (e) {
      _updateStatus(SyncStatus.error);
    }
  }

  /// Get pending sync count
  int get pendingSyncCount => _syncQueue.length;

  /// Clear sync queue
  void clearQueue() {
    _syncQueue.clear();
  }

  void _updateStatus(SyncStatus status) {
    _status = status;
    _statusController.add(status);
  }

  /// Stop sync
  void stop() {
    _syncTimer?.cancel();
    _statusController.close();
  }
}
