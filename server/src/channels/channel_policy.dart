/// NexusAgent Channel Policy Service
/// DM/Group policies: pairing, allowlist, open, disabled

enum DMPolicy {
  pairing,   // Default - pairing code required
  allowlist, // Only allowlisted senders
  open,      // Allow all (requires allowFrom: ["*"])
  disabled,  // Ignore all DMs
}

enum GroupPolicy {
  allowlist, // Default - only allowlisted groups
  open,      // Bypass group allowlists
  disabled,  // Block all group messages
}

class ChannelPolicy {
  final DMPolicy dmPolicy;
  final GroupPolicy groupPolicy;
  final List<String> allowFrom;
  final List<String> groupAllowFrom;
  final Map<String, GroupConfig> groupConfigs;

  ChannelPolicy({
    this.dmPolicy = DMPolicy.pairing,
    this.groupPolicy = GroupPolicy.allowlist,
    this.allowFrom = const [],
    this.groupAllowFrom = const [],
    this.groupConfigs = const {},
  });

  factory ChannelPolicy.fromJson(Map<String, dynamic> json) {
    return ChannelPolicy(
      dmPolicy: DMPolicy.values.firstWhere(
        (e) => e.name == json['dmPolicy'],
        orElse: () => DMPolicy.pairing,
      ),
      groupPolicy: GroupPolicy.values.firstWhere(
        (e) => e.name == json['groupPolicy'],
        orElse: () => GroupPolicy.allowlist,
      ),
      allowFrom: List<String>.from(json['allowFrom'] ?? []),
      groupAllowFrom: List<String>.from(json['groupAllowFrom'] ?? []),
      groupConfigs: (json['groups'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, GroupConfig.fromJson(v)),
      ) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'dmPolicy': dmPolicy.name,
    'groupPolicy': groupPolicy.name,
    'allowFrom': allowFrom,
    'groupAllowFrom': groupAllowFrom,
    'groups': groupConfigs.map((k, v) => MapEntry(k, v.toJson())),
  };
}

class GroupConfig {
  final bool requireMention;
  final List<String> allowFrom;
  final List<String> skills;
  final String? systemPrompt;
  final Map<String, TopicConfig> topics;

  GroupConfig({
    this.requireMention = false,
    this.allowFrom = const [],
    this.skills = const [],
    this.systemPrompt,
    this.topics = const {},
  });

  factory GroupConfig.fromJson(Map<String, dynamic> json) {
    return GroupConfig(
      requireMention: json['requireMention'] ?? false,
      allowFrom: List<String>.from(json['allowFrom'] ?? []),
      skills: List<String>.from(json['skills'] ?? []),
      systemPrompt: json['systemPrompt'],
      topics: (json['topics'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, TopicConfig.fromJson(v)),
      ) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'requireMention': requireMention,
    'allowFrom': allowFrom,
    'skills': skills,
    'systemPrompt': systemPrompt,
    'topics': topics.map((k, v) => MapEntry(k, v.toJson())),
  };
}

class TopicConfig {
  final bool requireMention;
  final List<String> skills;
  final String? systemPrompt;

  TopicConfig({
    this.requireMention = false,
    this.skills = const [],
    this.systemPrompt,
  });

  factory TopicConfig.fromJson(Map<String, dynamic> json) {
    return TopicConfig(
      requireMention: json['requireMention'] ?? false,
      skills: List<String>.from(json['skills'] ?? []),
      systemPrompt: json['systemPrompt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'requireMention': requireMention,
    'skills': skills,
    'systemPrompt': systemPrompt,
  };
}

class ChannelPolicyService {
  static final ChannelPolicyService _instance = ChannelPolicyService._internal();
  factory ChannelPolicyService() => _instance;
  ChannelPolicyService._internal();

  final Map<String, ChannelPolicy> _channelPolicies = {};
  final Map<String, List<PairingRequest>> _pendingPairings = {};

  /// Set channel policy
  void setPolicy(String channel, ChannelPolicy policy) {
    _channelPolicies[channel] = policy;
  }

  /// Get channel policy
  ChannelPolicy getPolicy(String channel) {
    return _channelPolicies[channel] ?? ChannelPolicy();
  }

  /// Check if sender is allowed
  bool isSenderAllowed(String channel, String senderId) {
    final policy = getPolicy(channel);
    
    if (policy.allowFrom.contains('*')) return true;
    return policy.allowFrom.any((s) => s.contains(senderId));
  }

  /// Check if group is allowed
  bool isGroupAllowed(String channel, String groupId) {
    final policy = getPolicy(channel);
    
    if (policy.groupPolicy == GroupPolicy.open) return true;
    if (policy.groupPolicy == GroupPolicy.disabled) return false;
    
    if (policy.groupAllowFrom.contains('*')) return true;
    return policy.groupAllowFrom.any((s) => s.contains(groupId));
  }

  /// Get pending pairing requests
  int getPendingPairings(String channel) {
    return _pendingPairings[channel]?.length ?? 0;
  }

  /// Check if can create pairing (max 3 pending)
  bool canCreatePairing(String channel) {
    final pending = _pendingPairings[channel]?.length ?? 0;
    return pending < 3;
  }
}

// Pairing management
class PairingRequest {
  final String code;
  final String channel;
  final String senderId;
  final String senderName;
  final DateTime createdAt;
  final DateTime expiresAt;

  PairingRequest({
    required this.code,
    required this.channel,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
