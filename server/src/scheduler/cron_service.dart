/// NexusAgent Cron Scheduler
/// Task scheduling and automation

import 'dart:async';

class CronConfig {
  final Duration minInterval;
  final int maxJobs;

  CronConfig({
    this.minInterval = const Duration(seconds: 10),
    this.maxJobs = 100,
  });
}

class ScheduledJob {
  final String id;
  final String name;
  final String schedule; // cron expression
  final String task;
  final Map<String, dynamic> params;
  final bool enabled;
  final DateTime? lastRun;
  final DateTime? nextRun;
  final int runCount;
  final String? lastError;

  ScheduledJob({
    required this.id,
    required this.name,
    required this.schedule,
    required this.task,
    this.params = const {},
    this.enabled = true,
    this.lastRun,
    this.nextRun,
    this.runCount = 0,
    this.lastError,
  });
}

class CronService {
  static final CronService _instance = CronService._internal();
  factory CronService() => _instance;
  CronService._internal();

  CronConfig _config = CronConfig();
  final Map<String, ScheduledJob> _jobs = {};
  final Map<String, Timer> _timers = {};
  
  // Callback for executing jobs
  Function(String jobId, String task, Map<String, dynamic> params)? onJobExecute;

  /// Initialize scheduler
  void initialize(CronConfig config) {
    _config = config;
    print('Cron service initialized');
  }

  /// Add job
  String addJob({
    required String name,
    required String schedule,
    required String task,
    Map<String, dynamic> params = const {},
  }) {
    if (_jobs.length >= _config.maxJobs) {
      throw Exception('Max jobs limit reached');
    }

    final id = _generateId();
    final job = ScheduledJob(
      id: id,
      name: name,
      schedule: schedule,
      task: task,
      params: params,
      nextRun: _calculateNextRun(schedule),
    );

    _jobs[id] = job;

    // Start timer
    _startJobTimer(id, schedule);

    return id;
  }

  /// Remove job
  void removeJob(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);
    _jobs.remove(id);
  }

  /// Enable/disable job
  void setJobEnabled(String id, bool enabled) {
    final job = _jobs[id];
    if (job == null) return;

    _jobs[id] = ScheduledJob(
      id: job.id,
      name: job.name,
      schedule: job.schedule,
      task: job.task,
      params: job.params,
      enabled: enabled,
      lastRun: job.lastRun,
      nextRun: job.nextRun,
      runCount: job.runCount,
      lastError: job.lastError,
    );

    if (enabled) {
      _startJobTimer(id, job.schedule);
    } else {
      _timers[id]?.cancel();
      _timers.remove(id);
    }
  }

  /// Get job
  ScheduledJob? getJob(String id) => _jobs[id];

  /// List all jobs
  List<ScheduledJob> listJobs() => _jobs.values.toList();

  /// Get enabled jobs
  List<ScheduledJob> getEnabledJobs() => 
      _jobs.values.where((j) => j.enabled).toList();

  /// Run job now
  Future<void> runJob(String id) async {
    final job = _jobs[id];
    if (job == null || !job.enabled) return;

    await _executeJob(id);
  }

  /// Start job timer
  void _startJobTimer(String id, String schedule) {
    final interval = _parseScheduleToDuration(schedule);
    if (interval == null) return;

    _timers[id]?.cancel();
    _timers[id] = Timer.periodic(interval, (_) => _executeJob(id));
  }

  /// Execute job
  Future<void> _executeJob(String id) async {
    final job = _jobs[id];
    if (job == null || !job.enabled) return;

    try {
      // Execute callback
      if (onJobExecute != null) {
        await onJobExecute!(job.id, job.task, job.params);
      }

      // Update job
      _jobs[id] = ScheduledJob(
        id: job.id,
        name: job.name,
        schedule: job.schedule,
        task: job.task,
        params: job.params,
        enabled: job.enabled,
        lastRun: DateTime.now(),
        nextRun: _calculateNextRun(job.schedule),
        runCount: job.runCount + 1,
      );

      print('Job executed: ${job.name}');
    } catch (e) {
      _jobs[id] = ScheduledJob(
        id: job.id,
        name: job.name,
        schedule: job.schedule,
        task: job.task,
        params: job.params,
        enabled: job.enabled,
        lastRun: DateTime.now(),
        nextRun: _calculateNextRun(job.schedule),
        runCount: job.runCount,
        lastError: e.toString(),
      );
    }
  }

  /// Parse cron expression to duration
  Duration? _parseScheduleToDuration(String schedule) {
    // Simple parser for common patterns
    final parts = schedule.split(' ');
    if (parts.length < 5) return null;

    // @every X
    if (schedule.startsWith('@every ')) {
      final duration = schedule.substring(8).trim();
      return _parseDurationString(duration);
    }

    // Simple interval patterns
    // minute (*/X)
    if (parts[0].startsWith('*/')) {
      final minutes = int.tryParse(parts[0].substring(2));
      if (minutes != null) {
        return Duration(minutes: minutes);
      }
    }

    // Default: every minute
    return const Duration(minutes: 1);
  }

  Duration? _parseDurationString(String duration) {
    final match = RegExp(r'(\d+)\s*(s|sec|m|min|h|hour|d|day)').firstMatch(duration);
    if (match == null) return null;

    final value = int.parse(match.group(1)!);
    final unit = match.group(2);

    switch (unit) {
      case 's':
      case 'sec':
        return Duration(seconds: value);
      case 'm':
      case 'min':
        return Duration(minutes: value);
      case 'h':
      case 'hour':
        return Duration(hours: value);
      case 'd':
      case 'day':
        return Duration(days: value);
      default:
        return null;
    }
  }

  /// Calculate next run time
  DateTime? _calculateNextRun(String schedule) {
    final interval = _parseScheduleToDuration(schedule);
    if (interval == null) return null;
    return DateTime.now().add(interval);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Stop all jobs
  void stopAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// Resume all enabled jobs
  void resumeAll() {
    for (final job in _jobs.values) {
      if (job.enabled) {
        _startJobTimer(job.id, job.schedule);
      }
    }
  }
}
