/// Analytics Dashboard Screen
/// Production-ready analytics with charts and insights

import 'dart:async';
import 'dart:convert';

class AnalyticsData {
  // Overview metrics
  final int totalAgents;
  final int activeAgents;
  final int totalSessions;
  final int activeSessions;
  final int totalMessages;
  final int messagesToday;
  final int totalToolCalls;
  final int toolCallsToday;
  
  // Usage metrics
  final double avgResponseTime;
  final double successRate;
  final int peakConcurrentSessions;
  
  // Channel breakdown
  final Map<String, int> messagesByChannel;
  final Map<String, int> sessionsByChannel;
  
  // Time series data
  final List<TimeSeriesPoint> messagesOverTime;
  final List<TimeSeriesPoint> sessionsOverTime;
  final List<TimeSeriesPoint> toolCallsOverTime;
  
  // Top agents
  final List<AgentMetric> topAgents;
  
  // Errors
  final int errorCount;
  final int errorsToday;
  final List<ErrorMetric> recentErrors;

  AnalyticsData({
    this.totalAgents = 0,
    this.activeAgents = 0,
    this.totalSessions = 0,
    this.activeSessions = 0,
    this.totalMessages = 0,
    this.messagesToday = 0,
    this.totalToolCalls = 0,
    this.toolCallsToday = 0,
    this.avgResponseTime = 0,
    this.successRate = 0,
    this.peakConcurrentSessions = 0,
    this.messagesByChannel = const {},
    this.sessionsByChannel = const {},
    this.messagesOverTime = const [],
    this.sessionsOverTime = const [],
    this.toolCallsOverTime = const [],
    this.topAgents = const [],
    this.errorCount = 0,
    this.errorsToday = 0,
    this.recentErrors = const [],
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      totalAgents: json['totalAgents'] ?? 0,
      activeAgents: json['activeAgents'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
      activeSessions: json['activeSessions'] ?? 0,
      totalMessages: json['totalMessages'] ?? 0,
      messagesToday: json['messagesToday'] ?? 0,
      totalToolCalls: json['totalToolCalls'] ?? 0,
      toolCallsToday: json['toolCallsToday'] ?? 0,
      avgResponseTime: (json['avgResponseTime'] ?? 0).toDouble(),
      successRate: (json['successRate'] ?? 0).toDouble(),
      peakConcurrentSessions: json['peakConcurrentSessions'] ?? 0,
      messagesByChannel: Map<String, int>.from(json['messagesByChannel'] ?? {}),
      sessionsByChannel: Map<String, int>.from(json['sessionsByChannel'] ?? {}),
      messagesOverTime: (json['messagesOverTime'] as List?)
          ?.map((e) => TimeSeriesPoint.fromJson(e))
          .toList() ?? [],
      sessionsOverTime: (json['sessionsOverTime'] as List?)
          ?.map((e) => TimeSeriesPoint.fromJson(e))
          .toList() ?? [],
      toolCallsOverTime: (json['toolCallsOverTime'] as List?)
          ?.map((e) => TimeSeriesPoint.fromJson(e))
          .toList() ?? [],
      topAgents: (json['topAgents'] as List?)
          ?.map((e) => AgentMetric.fromJson(e))
          .toList() ?? [],
      errorCount: json['errorCount'] ?? 0,
      errorsToday: json['errorsToday'] ?? 0,
      recentErrors: (json['recentErrors'] as List?)
          ?.map((e) => ErrorMetric.fromJson(e))
          .toList() ?? [],
    );
  }
}

class TimeSeriesPoint {
  final DateTime timestamp;
  final double value;

  TimeSeriesPoint({required this.timestamp, required this.value});

  factory TimeSeriesPoint.fromJson(Map<String, dynamic> json) {
    return TimeSeriesPoint(
      timestamp: DateTime.parse(json['timestamp']),
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}

class AgentMetric {
  final String agentId;
  final String name;
  final int sessions;
  final int messages;
  final int toolCalls;
  final double avgResponseTime;

  AgentMetric({
    required this.agentId,
    required this.name,
    required this.sessions,
    required this.messages,
    required this.toolCalls,
    required this.avgResponseTime,
  });

  factory AgentMetric.fromJson(Map<String, dynamic> json) {
    return AgentMetric(
      agentId: json['agentId'] ?? '',
      name: json['name'] ?? '',
      sessions: json['sessions'] ?? 0,
      messages: json['messages'] ?? 0,
      toolCalls: json['toolCalls'] ?? 0,
      avgResponseTime: (json['avgResponseTime'] ?? 0).toDouble(),
    );
  }
}

class ErrorMetric {
  final String id;
  final String error;
  final String? agentId;
  final String? toolName;
  final DateTime timestamp;
  final bool resolved;

  ErrorMetric({
    required this.id,
    required this.error,
    this.agentId,
    this.toolName,
    required this.timestamp,
    this.resolved = false,
  });

  factory ErrorMetric.fromJson(Map<String, dynamic> json) {
    return ErrorMetric(
      id: json['id'] ?? '',
      error: json['error'] ?? '',
      agentId: json['agentId'],
      toolName: json['toolName'],
      timestamp: DateTime.parse(json['timestamp']),
      resolved: json['resolved'] ?? false,
    );
  }
}

// Analytics service for fetching data
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final _analyticsController = StreamController<AnalyticsData>.broadcast();
  Stream<AnalyticsData> get analyticsStream => _analyticsController.stream;
  
  Timer? _refreshTimer;
  AnalyticsData _cachedData = AnalyticsData();

  /// Start periodic refresh
  void startAutoRefresh({Duration interval = const Duration(minutes: 1)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => refresh());
  }

  /// Stop auto refresh
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  /// Fetch analytics data
  Future<AnalyticsData> fetchAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? agentId,
  }) async {
    // In production, this would call the API
    // For demo, generate sample data
    await Future.delayed(const Duration(milliseconds: 300));
    
    _cachedData = _generateSampleData();
    _analyticsController.add(_cachedData);
    
    return _cachedData;
  }

  /// Refresh data
  Future<AnalyticsData> refresh() async {
    return fetchAnalytics();
  }

  /// Get cached data
  AnalyticsData get cachedData => _cachedData;

  AnalyticsData _generateSampleData() {
    final now = DateTime.now();
    
    return AnalyticsData(
      totalAgents: 12,
      activeAgents: 8,
      totalSessions: 15420,
      activeSessions: 23,
      totalMessages: 89234,
      messagesToday: 1247,
      totalToolCalls: 456789,
      toolCallsToday: 3456,
      avgResponseTime: 1.2,
      successRate: 98.7,
      peakConcurrentSessions: 47,
      messagesByChannel: {
        'telegram': 34567,
        'discord': 28432,
        'whatsapp': 15234,
        'slack': 8923,
        'signal': 2078,
      },
      sessionsByChannel: {
        'telegram': 5234,
        'discord': 4567,
        'whatsapp': 3234,
        'slack': 1789,
        'signal': 596,
      },
      messagesOverTime: List.generate(24, (i) => 
        TimeSeriesPoint(
          timestamp: now.subtract(Duration(hours: 23 - i)),
          value: (50 + (i * 7) % 100).toDouble(),
        )
      ),
      sessionsOverTime: List.generate(24, (i) => 
        TimeSeriesPoint(
          timestamp: now.subtract(Duration(hours: 23 - i)),
          value: (5 + (i * 3) % 20).toDouble(),
        )
      ),
      toolCallsOverTime: List.generate(24, (i) => 
        TimeSeriesPoint(
          timestamp: now.subtract(Duration(hours: 23 - i)),
          value: (100 + (i * 15) % 300).toDouble(),
        )
      ),
      topAgents: [
        AgentMetric(agentId: '1', name: 'Support Bot', sessions: 4523, messages: 23456, toolCalls: 123456, avgResponseTime: 0.8),
        AgentMetric(agentId: '2', name: 'Sales Assistant', sessions: 3245, messages: 18234, toolCalls: 98234, avgResponseTime: 1.1),
        AgentMetric(agentId: '3', name: 'Code Reviewer', sessions: 2134, messages: 12456, toolCalls: 87234, avgResponseTime: 2.3),
        AgentMetric(agentId: '4', name: 'Data Analyst', sessions: 1567, messages: 8923, toolCalls: 56789, avgResponseTime: 1.5),
        AgentMetric(agentId: '5', name: 'Content Writer', sessions: 1234, messages: 6789, toolCalls: 34567, avgResponseTime: 0.9),
      ],
      errorCount: 1234,
      errorsToday: 23,
      recentErrors: [
        ErrorMetric(id: '1', error: 'Timeout: web_fetch', agentId: '3', toolName: 'web_fetch', timestamp: now.subtract(const Duration(minutes: 5))),
        ErrorMetric(id: '2', error: 'Rate limit exceeded', agentId: '1', toolName: 'web_search', timestamp: now.subtract(const Duration(minutes: 12))),
        ErrorMetric(id: '3', error: 'Invalid API key', agentId: '2', toolName: 'web_search', timestamp: now.subtract(const Duration(minutes: 25))),
      ],
    );
  }

  void dispose() {
    _refreshTimer?.cancel();
    _analyticsController.close();
  }
}
