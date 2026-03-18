class Agent {
  final String id;
  final String orgId;
  final String name;
  final String description;
  final String? avatarUrl;
  final String status;
  final AgentConfig config;
  final DateTime createdAt;
  final DateTime? lastRunAt;
  final int runCount;
  final List<String> enabledTools;
  final List<Channel> channels;

  Agent({
    required this.id,
    required this.orgId,
    required this.name,
    this.description = '',
    this.avatarUrl,
    required this.status,
    required this.config,
    required this.createdAt,
    this.lastRunAt,
    this.runCount = 0,
    this.enabledTools = const [],
    this.channels = const [],
  });
}

class AgentConfig {
  final String model;
  final int maxTokens;
  final double temperature;
  final String? systemPrompt;
  final int contextWindow;
  final bool enableMemory;

  AgentConfig({
    this.model = 'gpt-4',
    this.maxTokens = 4096,
    this.temperature = 0.7,
    this.systemPrompt,
    this.contextWindow = 8192,
    this.enableMemory = true,
  });
}

class AgentRun {
  final String id;
  final String agentId;
  final String status;
  final String? input;
  final String? output;
  final List<RunStep> steps;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int tokensUsed;

  AgentRun({
    required this.id,
    required this.agentId,
    required this.status,
    this.input,
    this.output,
    this.steps = const [],
    required this.startedAt,
    this.endedAt,
    this.tokensUsed = 0,
  });

  Duration? get duration => endedAt?.difference(startedAt);
}

class RunStep {
  final int order;
  final String action;
  final String? result;
  final Duration? duration;
  final bool success;

  RunStep({
    required this.order,
    required this.action,
    this.result,
    this.duration,
    required this.success,
  });
}

class Channel {
  final String id;
  final String orgId;
  final String type;
  final String name;
  final bool enabled;
  final Map<String, dynamic> config;
  final DateTime createdAt;

  Channel({
    required this.id,
    required this.orgId,
    required this.type,
    required this.name,
    required this.enabled,
    this.config = const {},
    required this.createdAt,
  });
}

class Message {
  final String id;
  final String channelId;
  final String direction;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String? agentId;

  Message({
    required this.id,
    required this.channelId,
    required this.direction,
    required this.content,
    this.metadata = const {},
    required this.timestamp,
    this.agentId,
  });
}

class MemoryEntry {
  final String id;
  final String orgId;
  final String content;
  final List<String> tags;
  final List<double> embedding;
  final DateTime createdAt;
  final DateTime? accessedAt;
  final int accessCount;

  MemoryEntry({
    required this.id,
    required this.orgId,
    required this.content,
    this.tags = const [],
    this.embedding = const [],
    required this.createdAt,
    this.accessedAt,
    this.accessCount = 0,
  });
}

class Organization {
  final String id;
  final String name;
  final String plan;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final int memberCount;
  final int agentCount;

  Organization({
    required this.id,
    required this.name,
    this.plan = 'starter',
    this.settings = const {},
    required this.createdAt,
    this.memberCount = 1,
    this.agentCount = 0,
  });
}

class User {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final Organization? organization;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.organization,
    required this.createdAt,
  });
}

class Analytics {
  final int totalMessages;
  final int totalAgents;
  final int activeAgents;
  final int totalRuns;
  final double avgResponseTime;
  final int tokensUsed;
  final List<DailyMetric> dailyMetrics;

  Analytics({
    this.totalMessages = 0,
    this.totalAgents = 0,
    this.activeAgents = 0,
    this.totalRuns = 0,
    this.avgResponseTime = 0,
    this.tokensUsed = 0,
    this.dailyMetrics = const [],
  });
}

class DailyMetric {
  final DateTime date;
  final int messages;
  final int runs;
  final int tokens;

  DailyMetric({
    required this.date,
    this.messages = 0,
    this.runs = 0,
    this.tokens = 0,
  });
}
