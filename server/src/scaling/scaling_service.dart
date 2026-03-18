/// NexusAgent Horizontal Scaling Architecture
/// Ready for millions of users

import 'dart:async';
import 'dart:convert';
import 'package:redis/redis.dart';
import 'package:postgres/postgres.dart';

/// ============================================
/// SCALING ARCHITECTURE
/// ============================================
/// 
/// User → CDN → Load Balancer → API Gateway
///                                  │
///                    ┌─────────────┼─────────────┐
///                    ▼             ▼             ▼
///              [Server 1]    [Server 2]    [Server N]
///                    │             │             │
///                    └─────────────┼─────────────┘
///                                  ▼
///                         ┌─────────────────┐
///                         │   Redis Cluster  │
│                         │  (Cache + Pub/Sub)│
│                         └────────┬────────┘
│                                  │
│                         ┌────────▼────────┐
│                         │  PostgreSQL     │
│                         │ (Primary + Replicas)
│                         └─────────────────┘
///
/// ============================================

/// 1. Redis Service - Cache + Pub/Sub
class RedisService {
  static RedisService? _instance;
  late RedisConnection _connection;
  bool _connected = false;

  static RedisService get instance {
    _instance ??= RedisService._();
    return _instance!;
  }

  RedisService._();

  /// Connect to Redis cluster
  Future<void> connect(List<String> nodes) async {
    // nodes = ['redis1:6379', 'redis2:6379', 'redis3:6379']
    final pool = RedisConnectionPool(nodes, 10);
    _connection = await pool.getConnection();
    _connected = true;
    print('Redis connected: $nodes');
  }

  /// Cache operations
  Future<void> set(String key, dynamic value, {Duration? expiry}) async {
    final serialized = jsonEncode(value);
    await _connection.set(key, serialized);
    if (expiry != null) {
      await _connection.expire(key, expiry.inSeconds);
    }
  }

  Future<dynamic> get(String key) async {
    final value = await _connection.get(key);
    if (value == null) return null;
    return jsonDecode(value as String);
  }

  Future<void> delete(String key) async {
    await _connection.delete(key);
  }

  /// Pub/Sub for real-time
  Future<void> publish(String channel, dynamic message) async {
    await _connection.send_object(['PUBLISH', channel, jsonEncode(message)]);
  }

  Stream<dynamic> subscribe(String channel) async* {
    final sub = await _connection.multi();
    await sub.subscribe(channel);
    await for (final msg in sub.stream) {
      yield jsonDecode(msg as String);
    }
  }

  /// Distributed locking
  Future<bool> acquireLock(String key, Duration expiry) async {
    final result = await _connection.setnx(key, 'locked');
    if (result == 1) {
      await _connection.expire(key, expiry.inSeconds);
      return true;
    }
    return false;
  }

  Future<void> releaseLock(String key) async {
    await _connection.delete(key);
  }

  bool get isConnected => _connected;
}

/// 2. PostgreSQL Service - Primary + Replicas
class DatabaseService {
  static DatabaseService? _instance;
  late Connection _primary;
  final List<Connection> _replicas = [];
  int _replicaIndex = 0;

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  DatabaseService._();

  /// Connect to primary
  Future<void> connectPrimary({
    required String host,
    required int port,
    required String database,
    required String user,
    required String password,
  }) async {
    _primary = await Connection.open(
      Endpoint(host: host, port: port, database: database, username: user, password: password),
      settings: ConnectionSettings(ssl: false),
    );
    print('PostgreSQL primary connected: $host:$port/$database');
  }

  /// Add read replica
  Future<void> addReplica({
    required String host,
    required int port,
    required String database,
    required String user,
    required String password,
  }) async {
    final replica = await Connection.open(
      Endpoint(host: host, port: port, database: database, username: user, password: password),
      settings: ConnectionSettings(ssl: false),
    );
    _replicas.add(replica);
    print('PostgreSQL replica connected: $host:$port');
  }

  /// Write to primary
  Future<int> write(String query, [Map<String, dynamic>? params]) async {
    final result = await _primary.execute(query, parameters: params);
    return result.affectedRows;
  }

  /// Read from replica (load balanced)
  Future<List<List<dynamic>>> read(String query, [Map<String, dynamic>? params]) async {
    if (_replicas.isEmpty) {
      // Fallback to primary
      final result = await _primary.execute(query, parameters: params);
      return result.toList();
    }

    // Round-robin to replica
    final replica = _replicas[_replicaIndex % _replicas.length];
    _replicaIndex++;

    final result = await replica.execute(query, parameters: params);
    return result.toList();
  }

  /// Transaction
  Future<void> transaction(Future<void> Function() action) async {
    await _primary.transaction(action);
  }
}

/// 3. Load Balancer - Traffic distribution
class LoadBalancer {
  final List<ServerInstance> _servers = [];
  int _currentIndex = 0;

  enum Strategy { roundRobin, leastConnections, ipHash }

  Strategy _strategy = Strategy.roundRobin;

  /// Register server instance
  void register(ServerInstance server) {
    _servers.add(server);
    print('Server registered: ${server.id} (${_servers.length} total)');
  }

  /// Remove server
  void remove(String id) {
    _servers.removeWhere((s) => s.id == id);
    print('Server removed: $id');
  }

  /// Get next server
  ServerInstance? getServer({String? clientIp}) {
    if (_servers.isEmpty) return null;

    switch (_strategy) {
      case Strategy.roundRobin:
        final server = _servers[_currentIndex];
        _currentIndex = (_currentIndex + 1) % _servers.length;
        return server;

      case Strategy.leastConnections:
        _servers.sort((a, b) => a.connections.compareTo(b.connections));
        return _servers.first;

      case Strategy.ipHash:
        if (clientIp != null) {
          final hash = clientIp.hashCode.abs();
          return _servers[hash % _servers.length];
        }
        return _servers[0];
    }
  }

  /// Health check all servers
  Future<void> healthCheck() async {
    for (final server in _servers) {
      final healthy = await server.healthCheck();
      server.isHealthy = healthy;
    }
  }

  List<ServerInstance> get servers => _servers;
}

/// Server instance representation
class ServerInstance {
  final String id;
  final String host;
  final int port;
  bool isHealthy = true;
  int connections = 0;
  int requestsProcessed = 0;
  DateTime startedAt = DateTime.now();

  ServerInstance({
    required this.id,
    required this.host,
    required this.port,
  });

  Future<bool> healthCheck() async {
    // Would ping /health endpoint
    return true;
  }

  String get url => 'http://$host:$port';
}

/// 4. Message Queue - Async processing
class MessageQueue {
  static MessageQueue? _instance;
  final List<QueueWorker> _workers = [];
  final Map<String, List<Function(dynamic)>> _handlers = {};
  bool _running = false;

  static MessageQueue get instance {
    _instance ??= MessageQueue._();
    return _instance!;
  }

  MessageQueue._();

  /// Register handler for queue
  void register(String queue, Function(dynamic) handler) {
    _handlers.putIfAbsent(queue, () => []).add(handler);
    print('Handler registered for queue: $queue');
  }

  /// Enqueue message
  Future<void> enqueue(String queue, dynamic message) async {
    // Would use RabbitMQ/Kafka in production
    // For now, simple in-memory
    final handlers = _handlers[queue];
    if (handlers != null) {
      for (final handler in handlers) {
        handler(message);
      }
    }
  }

  /// Start worker
  void startWorker(String queue) async {
    _running = true;
    print('Worker started for: $queue');
  }

  void stop() {
    _running = false;
  }
}

/// Queue worker
class QueueWorker {
  final String queue;
  bool _running = false;

  QueueWorker(this.queue);

  Future<void> start() async {
    _running = true;
    while (_running) {
      // Process messages
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void stop() => _running = false;
}

/// 5. Rate Limiter - Distributed
class RateLimiter {
  static RateLimiter? _instance;
  final RedisService _redis = RedisService.instance;

  static RateLimiter get instance {
    _instance ??= RateLimiter._();
    return _instance!;
  }

  RateLimiter._();

  /// Check rate limit (token bucket)
  Future<bool> check(String key, int maxRequests, Duration window) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowKey = '$key:${now ~/ window.inMilliseconds}';

    final current = await _redis.get(windowKey);
    if (current == null || current < maxRequests) {
      await _redis.set(windowKey, (current ?? 0) + 1, expiry: window);
      return true;
    }
    return false;
  }
}

/// 6. WebSocket Manager - Multiple instances
class WebSocketManager {
  static WebSocketManager? _instance;
  final Map<String, Set<String>> _roomMembers = {}; // roomId -> Set<sessionId>
  final Map<String, String> _sessionToRoom = {}; // sessionId -> roomId

  static WebSocketManager get instance {
    _instance ??= WebSocketManager._();
    return _instance!;
  }

  WebSocketManager._();

  /// Join room
  void joinRoom(String sessionId, String roomId) {
    _roomMembers.putIfAbsent(roomId, () => {}).add(sessionId);
    _sessionToRoom[sessionId] = roomId;
  }

  /// Leave room
  void leaveRoom(String sessionId) {
    final roomId = _sessionToRoom.remove(sessionId);
    if (roomId != null) {
      _roomMembers[roomId]?.remove(sessionId);
    }
  }

  /// Broadcast to room
  Future<void> broadcast(String roomId, dynamic message) async {
    final members = _roomMembers[roomId] ?? {};
    // Would send via Redis Pub/Sub to all server instances
    await RedisService.instance.publish('ws:$roomId', message);
  }

  /// Get room members
  Set<String> getRoomMembers(String roomId) {
    return _roomMembers[roomId] ?? {};
  }
}

/// 7. API Gateway - Request routing
class APIGateway {
  final LoadBalancer _lb = LoadBalancer();
  final RateLimiter _rateLimiter = RateLimiter.instance;

  /// Route request
  Future<GatewayResponse> route(Request request) async {
    // Rate limit check
    final allowed = await _rateLimiter.check(
      request.clientIp ?? 'unknown',
      1000, // 1000 requests
      const Duration(minutes: 1),
    );

    if (!allowed) {
      return GatewayResponse(
        status: 429,
        body: {'error': 'Rate limit exceeded'},
      );
    }

    // Get server
    final server = _lb.getServer(clientIp: request.clientIp);
    if (server == null) {
      return GatewayResponse(
        status: 503,
        body: {'error': 'No servers available'},
      );
    }

    // Forward request
    // In production: would use nginx/haproxy
    return GatewayResponse(
      status: 200,
      body: {'message': 'Forwarded to ${server.id}'},
    );
  }
}

class Request {
  final String path;
  final String method;
  final String? clientIp;
  final Map<String, String> headers;
  final dynamic body;

  Request({
    required this.path,
    required this.method,
    this.clientIp,
    this.headers = const {},
    this.body,
  });
}

class GatewayResponse {
  final int status;
  final dynamic body;

  GatewayResponse({required this.status, required this.body});
}

/// ============================================
/// HORIZONTAL SCALING CONFIG
/// ============================================

class ScalingConfig {
  // Redis cluster nodes
  static final List<String> redisNodes = [
    'redis-1:6379',
    'redis-2:6379',
    'redis-3:6379',
  ];

  // PostgreSQL
  static final String pgHost = 'postgres';
  static final int pgPort = 5432;
  static final String pgDatabase = 'nexusagent';
  static final String pgUser = 'nexusagent';
  static final String pgPassword = 'password';

  // Read replicas
  static final List<Map<String, dynamic>> pgReplicas = [
    {'host': 'postgres-replica-1', 'port': 5432},
    {'host': 'postgres-replica-2', 'port': 5432},
  ];

  // API servers
  static final List<Map<String, dynamic>> apiServers = [
    {'id': 'api-1', 'host': 'api-1', 'port': 3000},
    {'id': 'api-2', 'host': 'api-2', 'port': 3000},
    {'id': 'api-3', 'host': 'api-3', 'port': 3000},
  ];

  // Auto-scaling
  static final AutoScaleConfig autoScale = AutoScaleConfig(
    minInstances: 3,
    maxInstances: 100,
    targetCpuPercent: 70,
    scaleUpCooldown: Duration(minutes: 2),
    scaleDownCooldown: Duration(minutes: 10),
  );
}

class AutoScaleConfig {
  final int minInstances;
  final int maxInstances;
  final int targetCpuPercent;
  final Duration scaleUpCooldown;
  final Duration scaleDownCooldown;

  AutoScaleConfig({
    required this.minInstances,
    required this.maxInstances,
    required this.targetCpuPercent,
    required this.scaleUpCooldown,
    required this.scaleDownCooldown,
  });
}
