/// NexusAgent Channel Configuration
/// Complete channel configuration with all OpenClaw features

import 'channel_policy.dart';

class ChannelConfig {
  // DM/Group policies
  ChannelPolicy policy;
  
  // Model routing
  Map<String, String> modelByChannel;
  
  // Heartbeat
  HeartbeatConfig heartbeat;
  
  // Multi-account
  Map<String, AccountConfig> accounts;
  String? defaultAccount;
  
  // Media
  int mediaMaxMb;
  bool sendReadReceipts;
  
  // History
  int historyLimit;
  
  // Reply
  ReplyMode replyToMode;
  
  // Streaming
  StreamingMode streaming;
  
  // Custom commands
  List<CustomCommand> customCommands;
  
  // Retry
  RetryConfig retry;
  
  // Network
  NetworkConfig network;
  
  // Proxy
  String? proxy;
  
  // Webhook
  WebhookConfig? webhook;
  
  // Actions enabled
  ChannelActions actions;

  ChannelConfig({
    this.policy = const ChannelPolicy(),
    this.modelByChannel = const {},
    HeartbeatConfig? heartbeat,
    this.accounts = const {},
    this.defaultAccount,
    this.mediaMaxMb = 50,
    this.sendReadReceipts = true,
    this.historyLimit = 50,
    this.replyToMode = ReplyMode.first,
    this.streaming = StreamingMode.off,
    this.customCommands = const [],
    RetryConfig? retry,
    NetworkConfig? network,
    this.proxy,
    this.webhook,
    ChannelActions? actions,
  })  : heartbeat = heartbeat ?? HeartbeatConfig(),
        retry = retry ?? RetryConfig(),
        network = network ?? NetworkConfig(),
        actions = actions ?? ChannelActions();
}

class HeartbeatConfig {
  bool showOk;
  bool showAlerts;
  bool useIndicator;

  HeartbeatConfig({
    this.showOk = true,
    this.showAlerts = true,
    this.useIndicator = false,
  });
}

class AccountConfig {
  String? authDir;
  bool? sendReadReceipts;
  DMPolicy? dmPolicy;
  List<String> allowFrom;

  AccountConfig({
    this.authDir,
    this.sendReadReceipts,
    this.dmPolicy,
    this.allowFrom = const [],
  });
}

enum ReplyMode {
  off,
  first,
  all,
}

enum StreamingMode {
  off,
  partial,
  block,
  progress,
}

class CustomCommand {
  final String command;
  final String description;
  final String? response;
  final List<String>? skills;
  final String? systemPrompt;

  CustomCommand({
    required this.command,
    required this.description,
    this.response,
    this.skills,
    this.systemPrompt,
  });
}

class RetryConfig {
  int attempts;
  int minDelayMs;
  int maxDelayMs;
  double jitter;
  int? maxAttempts;

  RetryConfig({
    this.attempts = 3,
    this.minDelayMs = 400,
    this.maxDelayMs = 30000,
    this.jitter = 0.1,
    this.maxAttempts,
  });
}

class NetworkConfig {
  bool autoSelectFamily;
  String dnsResultOrder;

  NetworkConfig({
    this.autoSelectFamily = true,
    this.dnsResultOrder = 'ipv4first',
  });
}

class WebhookConfig {
  final String url;
  final String? secret;
  final String? path;

  WebhookConfig({
    required this.url,
    this.secret,
    this.path,
  });
}

class ChannelActions {
  bool reactions;
  bool sendMessage;
  bool stickers;
  bool polls;
  bool permissions;
  bool messages;
  bool threads;
  bool pins;
  bool search;
  bool memberInfo;
  bool roleInfo;
  bool roles;
  bool channelInfo;
  bool voiceStatus;
  bool events;
  bool moderation;

  ChannelActions({
    this.reactions = true,
    this.sendMessage = true,
    this.stickers = true,
    this.polls = true,
    this.permissions = true,
    this.messages = true,
    this.threads = true,
    this.pins = true,
    this.search = true,
    this.memberInfo = true,
    this.roleInfo = true,
    this.roles = false,
    this.channelInfo = true,
    this.voiceStatus = true,
    this.events = true,
    this.moderation = false,
  });
}

class TelegramChannelConfig extends ChannelConfig {
  // Telegram-specific
  String? botToken;
  bool linkPreview;
  String? reactionNotifications;
  bool configWrites;

  TelegramChannelConfig({
    super.policy,
    super.modelByChannel,
    super.heartbeat,
    super.accounts,
    super.defaultAccount,
    super.mediaMaxMb = 100,
    super.sendReadReceipts = true,
    super.historyLimit = 50,
    super.replyToMode,
    super.streaming,
    super.customCommands,
    super.retry,
    super.network,
    super.proxy,
    super.webhook,
    super.actions,
    this.botToken,
    this.linkPreview = true,
    this.reactionNotifications = 'own',
    this.configWrites = true,
  });
}

class DiscordChannelConfig extends ChannelConfig {
  // Discord-specific
  String? token;
  bool allowBots;
  DiscordDMConfig? dm;
  Map<String, DiscordGuildConfig> guilds;

  DiscordChannelConfig({
    super.policy,
    super.modelByChannel,
    super.heartbeat,
    super.accounts,
    super.defaultAccount,
    super.mediaMaxMb = 8,
    super.sendReadReceipts = true,
    super.historyLimit = 20,
    super.replyToMode = ReplyMode.off,
    super.streaming,
    super.customCommands,
    super.retry,
    super.network,
    super.proxy,
    super.webhook,
    super.actions,
    this.token,
    this.allowBots = false,
    this.dm,
    this.guilds = const {},
  });
}

class DiscordDMConfig {
  bool enabled;
  bool groupEnabled;
  List<String> groupChannels;

  DiscordDMConfig({
    this.enabled = true,
    this.groupEnabled = false,
    this.groupChannels = const [],
  });
}

class DiscordGuildConfig {
  final String? slug;
  final bool requireMention;
  final bool ignoreOtherMentions;
  final String? reactionNotifications;
  final List<String> users;
  final Map<String, GuildChannelConfig> channels;

  DiscordGuildConfig({
    this.slug,
    this.requireMention = false,
    this.ignoreOtherMentions = true,
    this.reactionNotifications = 'own',
    this.users = const [],
    this.channels = const {},
  });
}

class GuildChannelConfig {
  final bool allow;
  final bool requireMention;
  final List<String> users;
  final List<String> skills;
  final String? systemPrompt;

  GuildChannelConfig({
    this.allow = true,
    this.requireMention = false,
    this.users = const [],
    this.skills = const [],
    this.systemPrompt,
  });
}

class WhatsAppChannelConfig extends ChannelConfig {
  // WhatsApp-specific
  int textChunkLimit;
  ChunkMode chunkMode;

  WhatsAppChannelConfig({
    super.policy,
    super.modelByChannel,
    super.heartbeat,
    super.accounts,
    super.defaultAccount,
    super.mediaMaxMb = 50,
    super.sendReadReceipts = true,
    super.historyLimit = 50,
    super.replyToMode,
    super.streaming,
    super.customCommands,
    super.retry,
    super.network,
    super.proxy,
    super.webhook,
    super.actions,
    this.textChunkLimit = 4000,
    this.chunkMode = ChunkMode.length,
  });
}

enum ChunkMode {
  length,
  newline,
}
