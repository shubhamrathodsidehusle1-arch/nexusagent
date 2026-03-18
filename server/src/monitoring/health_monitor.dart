/// NexusAgent Health Monitor
/// Monitors channel health and auto-restarts

class HealthMonitorConfig {
  final int checkIntervalMinutes;
  final int staleThresholdMinutes;
  final int maxRestartsPerHour;
  final bool autoRestart;

  HealthMonitorConfig({
    this.checkIntervalMinutes = 5,
    this.staleThresholdMinutes = 30,
    this.maxRestartsPerHour = 10,
    this.autoRestart = true,
  });
}

class HealthStatus {
  final String channel;
  final String status; // healthy, stale, dead
  final DateTime lastEvent;
  final int restartsLastHour;
  final String? error;

  HealthStatus({
    required this.channel,
    required this.status,
    required this.lastEvent,
    required this.restartsLastHour,
    this.error,
  });
}

class HealthMonitor {
  static final HealthMonitor _instance = HealthMonitor._internal();
  factory HealthMonitor() => _instance;
  HealthMonitor._internal();

  HealthMonitorConfig _config = HealthMonitorConfig();
  final Map<String, HealthStatus> _channelStatus = {};
  final Map<String, List<DateTime>> _restartHistory = {};
  Timer? _monitorTimer;

  Function(String channel)? onChannelStale;
  Function(String channel)? onChannelDead;
  Function(String channel)? onChannelRestart;

  /// Initialize
  void initialize(HealthMonitorConfig config) {
    _config = config;
    _startMonitoring();
    print('Health monitor initialized');
  }

  /// Start monitoring
  void _startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(
      Duration(minutes: _config.checkIntervalMinutes),
      (_) => _checkAllChannels(),
    );
  }

  /// Update channel status
  void updateChannelStatus(String channel, DateTime lastEvent, {String? error}) {
    final now = DateTime.now();
    final stale = now.difference(lastEvent).inMinutes > _config.staleThresholdMinutes;

    _channelStatus[channel] = HealthStatus(
      channel: channel,
      status: stale ? 'stale' : 'healthy',
      lastEvent: lastEvent,
      restartsLastHour: _getRestartsLastHour(channel),
      error: error,
    );
  }

  /// Check all channels
  void _checkAllChannels() {
    final now = DateTime.now();

    for (final entry in _channelStatus.entries) {
      final status = entry.value;
      final minutesSinceLast = now.difference(status.lastEvent).inMinutes;

      if (minutesSinceLast > _config.staleThresholdMinutes * 2) {
        // Channel dead
        if (status.status != 'dead') {
          _channelStatus[entry.key] = HealthStatus(
            channel: entry.key,
            status: 'dead',
            lastEvent: status.lastEvent,
            restartsLastHour: status.restartsLastHour,
          );
          onChannelDead?.call(entry.key);
          _restartChannel(entry.key);
        }
      } else if (minutesSinceLast > _config.staleThresholdMinutes) {
        // Channel stale
        if (status.status == 'healthy') {
          _channelStatus[entry.key] = HealthStatus(
            channel: entry.key,
            status: 'stale',
            lastEvent: status.lastEvent,
            restartsLastHour: status.restartsLastHour,
          );
          onChannelStale?.call(entry.key);
        }
      }
    }
  }

  /// Restart channel
  void _restartChannel(String channel) {
    if (!_config.autoRestart) return;
    if (_getRestartsLastHour(channel) >= _config.maxRestartsPerHour) return;

    _restartHistory[channel] ??= [];
    _restartHistory[channel]!.add(DateTime.now());

    onChannelRestart?.call(channel);
  }

  int _getRestartsLastHour(String channel) {
    final history = _restartHistory[channel] ?? [];
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    return history.where((t) => t.isAfter(oneHourAgo)).length;
  }

  /// Get all statuses
  List<HealthStatus> getAllStatus() => _channelStatus.values.toList();

  /// Get specific channel status
  HealthStatus? getStatus(String channel) => _channelStatus[channel];

  /// Stop
  void stop() {
    _monitorTimer?.cancel();
  }
}
