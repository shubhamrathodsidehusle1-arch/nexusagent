/// NexusAgent Auth Middleware
/// JWT-based authentication for all endpoints

import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthConfig {
  final String jwtSecret;
  final Duration tokenExpiry;
  final List<String> publicPaths;

  AuthConfig({
    required this.jwtSecret,
    this.tokenExpiry = const Duration(days: 7),
    this.publicPaths = const ['/health', '/api/auth/login', '/api/auth/register'],
  });
}

class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final List<String> permissions;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'user',
    this.permissions = const [],
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  AuthConfig? _config;
  final Map<String, User> _users = {};
  final Map<String, DateTime> _tokens = {};

  /// Initialize auth service
  void initialize(AuthConfig config) {
    _config = config;
    print('Auth service initialized');
  }

  /// Register user
  Future<User?> register(String email, String password, String name) async {
    // Check if user exists
    for (final user in _users.values) {
      if (user.email == email) return null;
    }

    final user = User(
      id: _generateId(),
      email: email,
      name: name,
      role: 'user',
      permissions: ['read', 'write'],
    );

    // In production, hash password before storing
    _users[email] = user;
    _tokens[user.id] = DateTime.now();

    return user;
  }

  /// Login
  Future<String?> login(String email, String password) async {
    final user = _users[email];
    if (user == null) return null;

    // In production, verify password hash
    final token = _generateToken(user);
    _tokens[token] = DateTime.now();

    return token;
  }

  /// Verify token
  User? verifyToken(String token) {
    if (_config == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = jsonDecode(utf8.decode(base64Decode(parts[1])));
      final userId = payload['sub'] as String?;
      
      if (userId == null) return null;

      // Find user by ID
      for (final user in _users.values) {
        if (user.id == userId) return user;
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  /// Check if path requires auth
  bool requiresAuth(String path) {
    if (_config == null) return false;
    return !_config!.publicPaths.contains(path);
  }

  /// Generate JWT token
  String _generateToken(User user) {
    if (_config == null) return '';

    final header = base64Encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'}));
    final payload = base64Encode(jsonEncode({
      'sub': user.id,
      'email': user.email,
      'role': user.role,
      'permissions': user.permissions,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': (DateTime.now().add(_config!.tokenExpiry).millisecondsSinceEpoch ~/ 1000),
    }));
    
    final signature = base64Encode(
      Hmac(sha256, utf8.encode(_config!.jwtSecret))
        .convert(utf8.encode('$header.$payload'))
        .bytes
    );

    return '$header.$payload.$signature';
  }

  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final hash = sha256.convert(utf8.encode('$now${_users.length}'));
    return hash.toString().substring(0, 16);
  }

  /// Cleanup expired tokens
  void cleanup() {
    if (_config == null) return;
    
    final expired = _tokens.entries
        .where((e) => DateTime.now().difference(e.value) > _config!.tokenExpiry)
        .map((e) => e.key)
        .toList();

    for (final token in expired) {
      _tokens.remove(token);
    }
  }
}

/// Auth middleware for HTTP requests
class AuthMiddleware {
  final AuthService _auth = AuthService();

  /// Middleware function
  Future<AuthResult> authenticate(
    String? token, 
    String path,
  ) async {
    // Public paths don't need auth
    if (!_auth.requiresAuth(path)) {
      return AuthResult(authenticated: true, user: null);
    }

    // No token = not authenticated
    if (token == null || token.isEmpty) {
      return AuthResult(authenticated: false, error: 'No token provided');
    }

    // Verify token
    final user = _auth.verifyToken(token);
    if (user == null) {
      return AuthResult(authenticated: false, error: 'Invalid token');
    }

    return AuthResult(authenticated: true, user: user);
  }

  /// Extract token from header
  String? extractToken(Map<String, String> headers) {
    final auth = headers['authorization'];
    if (auth == null) return null;
    
    if (auth.startsWith('Bearer ')) {
      return auth.substring(7);
    }
    return null;
  }
}

class AuthResult {
  final bool authenticated;
  final User? user;
  final String? error;

  AuthResult({
    required this.authenticated,
    this.user,
    this.error,
  });
}
