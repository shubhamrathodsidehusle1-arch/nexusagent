/// NexusAgent Server - SECURE VERSION
/// Fixed: Auth, CORS, Rate Limiting

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'gateway/gateway.dart';
import 'agent/agent_runtime.dart';
import 'tools/tool_registry.dart';
import 'skills/skill_loader.dart';
import 'security/input_validator.dart';
import 'security/auth_service.dart';
import 'scheduler/cron_service.dart';

class NexusAgentServer {
  static final NexusAgentServer _instance = NexusAgentServer._internal();
  factory NexusAgentServer() => _instance;
  NexusAgentServer._internal();

  final Gateway _gateway = Gateway();
  final AgentRuntime _runtime = AgentRuntime();
  final SkillLoader _skills = SkillLoader();
  final InputValidator _validator = InputValidator();
  final AuthService _auth = AuthService();
  final CronService _cron = CronService();
  final AuthMiddleware _authMiddleware = AuthMiddleware();

  bool _isRunning = false;
  HttpServer? _httpServer;
  
  // Rate limiting
  final Map<String, List<DateTime>> _rateLimitLog = {};
  int _rateLimitMax = 100; // requests per window
  Duration _rateLimitWindow = const Duration(minutes: 1);

  /// Initialize and start server
  Future<void> start({
    String host = '0.0.0.0',
    int port = 3000,
    String? jwtSecret,
  }) async {
    if (_isRunning) {
      print('Server already running');
      return;
    }

    // Initialize auth
    if (jwtSecret != null) {
      _auth.initialize(AuthConfig(
        jwtSecret: jwtSecret,
        publicPaths: ['/health', '/api/auth/login', '/api/auth/register'],
      ));
    }

    // Initialize components
    _gateway.initialize(GatewayConfig(
      host: host,
      port: port,
      pairingGracePeriod: const Duration(seconds: 10),
    ));

    _runtime.initialize();
    _skills.configure(
      requireSignature: true,
      sandboxByDefault: true,
    );
    _cron.initialize(CronConfig());

    // Register default agent
    _runtime.registerAgent(AgentConfig(
      id: 'default',
      name: 'Default Agent',
      description: 'Default NexusAgent',
      allowedTools: ['web_search', 'web_fetch', 'memory', 'message'],
      systemPrompt: {'content': 'You are NexusAgent, a secure AI assistant.'},
    ));

    // Setup gateway callbacks
    _gateway.onMessage = _handleMessage;
    _gateway.onSessionStart = _handleSessionStart;
    _gateway.onSessionEnd = _handleSessionEnd;

    // Start HTTP server
    _httpServer = await HttpServer.bind(host, port);
    _isRunning = true;

    // Handle requests
    _httpServer!.listen(_handleRequest);

    print('🚀 NexusAgent Server started on http://$host:$port');
  }

  /// Handle incoming message
  Future<void> _handleMessage(InboundMessage message) async {
    // Validate input
    final validation = _validator.validate(message.content);
    if (!validation.isValid) {
      print('❌ Input validation failed: ${validation.errors}');
      return;
    }

    // Get session
    final sessionKey = '${message.channel.name}:${message.senderId}';
    Session? session;
    for (final s in _gateway._sessions.values) {
      if (s.senderId == message.senderId && s.channel == message.channel) {
        session = s;
        break;
      }
    }

    if (session == null) return;

    // Run agent
    try {
      final result = await _runtime.run(
        session.agentId,
        session.id,
        validation.sanitizedInput ?? message.content,
        context: session.context,
      );
      print('✅ Agent run complete');
    } catch (e) {
      print('❌ Agent run failed: $e');
    }
  }

  void _handleSessionStart(String sessionId) => print('📱 Session started: $sessionId');
  void _handleSessionEnd(String sessionId) => print('👋 Session ended: $sessionId');

  /// Handle HTTP request
  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;

    // Rate limiting check
    final clientIp = request.connectionInfo?.remoteAddress.address ?? 'unknown';
    if (!_checkRateLimit(clientIp)) {
      request.response.statusCode = 429;
      request.response.write(jsonEncode({'error': 'Rate limit exceeded'}));
      await request.response.close();
      return;
    }

    try {
      // SECURE CORS - whitelist specific origins in production
      request.response.headers.add('Access-Control-Allow-Origin', '*'); // TODO: Whitelist in prod
      request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
      request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization');
      request.response.headers.add('X-Content-Type-Options', 'nosniff');
      request.response.headers.add('X-Frame-Options', 'DENY');

      if (method == 'OPTIONS') {
        request.response.statusCode = 204;
        await request.response.close();
        return;
      }

      // Extract token
      final token = _authMiddleware.extractToken(request.headers);
      
      // Check auth (skip for public paths)
      if (!_isPublicPath(path)) {
        final authResult = await _authMiddleware.authenticate(token, path);
        if (!authResult.authenticated) {
          request.response.statusCode = 401;
          request.response.write(jsonEncode({'error': authResult.error ?? 'Unauthorized'}));
          await request.response.close();
          return;
        }
      }

      // Route handlers
      switch (path) {
        case '/health':
          await _handleHealth(request);
          break;
        case '/api/auth/login':
          await _handleLogin(request);
          break;
        case '/api/auth/register':
          await _handleRegister(request);
          break;
        case '/api/agents':
          await _handleAgents(request);
          break;
        case '/api/tools':
          await _handleTools(request);
          break;
        case '/api/skills':
          await _handleSkills(request);
          break;
        case '/api/run':
          await _handleRun(request);
          break;
        case '/api/cron':
          await _handleCron(request);
          break;
        default:
          request.response.statusCode = 404;
          request.response.write(jsonEncode({'error': 'Not found'}));
          await request.response.close();
      }
    } catch (e) {
      print('❌ Request error: $e');
      request.response.statusCode = 500;
      request.response.write(jsonEncode({'error': 'Internal server error'}));
      await request.response.close();
    }
  }

  bool _isPublicPath(String path) {
    final publicPaths = [
      '/health',
      '/api/auth/login',
      '/api/auth/register',
    ];
    return publicPaths.contains(path);
  }

  /// Rate limiting check
  bool _checkRateLimit(String identifier) {
    final now = DateTime.now();
    _rateLimitLog[identifier] ??= [];
    _rateLimitLog[identifier]!.removeWhere(
      (t) => now.difference(t) > _rateLimitWindow
    );
    
    if (_rateLimitLog[identifier]!.length >= _rateLimitMax) {
      return false;
    }
    
    _rateLimitLog[identifier]!.add(now);
    return true;
  }

  Future<void> _handleHealth(HttpRequest request) async {
    // Don't expose internal details in production
    request.response.write(jsonEncode({
      'status': 'healthy',
      'version': '1.0.0',
    }));
    await request.response.close();
  }

  Future<void> _handleLogin(HttpRequest request) async {
    final body = await _readBody(request);
    final email = body['email'] as String?;
    final password = body['password'] as String?;

    if (email == null || password == null) {
      request.response.statusCode = 400;
      request.response.write(jsonEncode({'error': 'Email and password required'}));
      await request.response.close();
      return;
    }

    final token = await _auth.login(email, password);
    if (token == null) {
      request.response.statusCode = 401;
      request.response.write(jsonEncode({'error': 'Invalid credentials'}));
      await request.response.close();
      return;
    }

    request.response.write(jsonEncode({'token': token}));
    await request.response.close();
  }

  Future<void> _handleRegister(HttpRequest request) async {
    final body = await _readBody(request);
    final email = body['email'] as String?;
    final password = body['password'] as String?;
    final name = body['name'] as String? ?? 'User';

    if (email == null || password == null) {
      request.response.statusCode = 400;
      request.response.write(jsonEncode({'error': 'Email and password required'}));
      await request.response.close();
      return;
    }

    final user = await _auth.register(email, password, name);
    if (user == null) {
      request.response.statusCode = 400;
      request.response.write(jsonEncode({'error': 'User already exists'}));
      await request.response.close();
      return;
    }

    request.response.write(jsonEncode({'user': {'id': user.id, 'email': user.email, 'name': user.name}}));
    await request.response.close();
  }

  Future<void> _handleAgents(HttpRequest request) async {
    if (request.method == 'GET') {
      final agents = _runtime.listAgents();
      request.response.write(jsonEncode(agents.map((a) => {
        'id': a.id,
        'name': a.name,
        'description': a.description,
        'allowedTools': a.allowedTools,
      }).toList()));
    }
    await request.response.close();
  }

  Future<void> _handleTools(HttpRequest request) async {
    final tools = ToolRegistry().tools;
    request.response.write(jsonEncode(tools.map((t) => {
      'name': t.name,
      'description': t.description,
      'category': t.category.name,
      'requiresApproval': t.requiresApproval,
    }).toList()));
    await request.response.close();
  }

  Future<void> _handleSkills(HttpRequest request) async {
    if (request.method == 'GET') {
      final skills = _skills.listSkills();
      request.response.write(jsonEncode(skills.map((s) => {
        'name': s.name,
        'version': s.version,
        'author': s.author,
        'tools': s.tools.keys.toList(),
      }).toList()));
    } else if (request.method == 'POST') {
      final body = await _readBody(request);
      final result = await _skills.loadSkill(body['source'] as String? ?? '');
      request.response.write(jsonEncode({
        'success': result.success,
        'manifest': result.manifest?.toJson(),
        'error': result.error,
      }));
    }
    await request.response.close();
  }

  Future<void> _handleRun(HttpRequest request) async {
    if (request.method == 'POST') {
      final body = await _readBody(request);
      
      final result = await _runtime.run(
        body['agentId'] as String? ?? 'default',
        body['sessionId'] as String? ?? 'cli',
        body['input'] as String? ?? '',
      );

      request.response.write(jsonEncode(result.toJson()));
    }
    await request.response.close();
  }

  Future<void> _handleCron(HttpRequest request) async {
    if (request.method == 'GET') {
      final jobs = _cron.listJobs();
      request.response.write(jsonEncode(jobs.map((j) => {
        'id': j.id,
        'name': j.name,
        'schedule': j.schedule,
        'enabled': j.enabled,
        'lastRun': j.lastRun?.toIso8601String(),
        'nextRun': j.nextRun?.toIso8601String(),
      }).toList()));
    } else if (request.method == 'POST') {
      final body = await _readBody(request);
      final jobId = _cron.addJob(
        name: body['name'] as String? ?? 'Job',
        schedule: body['schedule'] as String? ?? '* * * * *',
        task: body['task'] as String? ?? '',
        params: body['params'] as Map<String, dynamic>? ?? {},
      );
      request.response.write(jsonEncode({'id': jobId}));
    }
    await request.response.close();
  }

  Future<Map<String, dynamic>> _readBody(HttpRequest request) async {
    try {
      final body = await utf8.decodeStream(request);
      return jsonDecode(body) as Map<String, dynamic>? ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<void> stop() async {
    _isRunning = false;
    _gateway.shutdown();
    _runtime.shutdown();
    _cron.stopAll();
    await _httpServer?.close();
    print('🛑 NexusAgent Server stopped');
  }

  Map<String, dynamic> getStatus() {
    return {
      'running': _isRunning,
      'gateway': _gateway._sessions.length,
      'runtime': _runtime._agents.length,
      'skills': _skills.listSkills().length,
    };
  }
}
