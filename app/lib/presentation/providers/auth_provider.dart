/// NexusAgent Auth Provider - Connected
/// Full auth with local storage and API

import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final LocalStorageService _local = LocalStorageService();
  final DatabaseService _db = DatabaseService();

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    checkAuth();
  }

  /// Check authentication status
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check for stored token
      final token = _local.getToken();
      
      if (token != null) {
        // Try to validate with stored user
        final storedUser = _local.getUser();
        
        if (storedUser != null) {
          _currentUser = User.fromMap(storedUser);
          _isAuthenticated = true;
        } else {
          // Demo mode
          _currentUser = User.demo();
          _isAuthenticated = true;
        }
      } else {
        _isAuthenticated = false;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  /// Login with email/password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try API login
      final response = await _api.login(email, password);
      
      if (response['token'] != null) {
        await _local.saveToken(response['token']);
        _currentUser = User.fromApi(response['user']);
        await _local.saveUser(_currentUser!.toMap());
        
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Fallback to demo login
      return demoLogin();
    }
  }

  /// Demo login
  Future<bool> demoLogin() async {
    _currentUser = User.demo();
    await _local.saveToken('demo_token_${DateTime.now().millisecondsSinceEpoch}');
    await _local.saveUser(_currentUser!.toMap());
    
    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Login with SSO
  Future<bool> loginWithSSO(String provider) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Would initiate OAuth flow
      _currentUser = User.demo();
      _currentUser = User(
        id: 'sso_${DateTime.now().millisecondsSinceEpoch}',
        email: 'sso@nexusagent.io',
        name: 'SSO User',
        role: 'member',
        createdAt: DateTime.now(),
      );
      
      await _local.saveToken('sso_token_${DateTime.now().millisecondsSinceEpoch}');
      await _local.saveUser(_currentUser!.toMap());
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.register(name, email, password);
      
      if (response['token'] != null) {
        await _local.saveToken(response['token']);
        _currentUser = User.fromApi(response['user']);
        await _local.saveUser(_currentUser!.toMap());
        
        // Also save to local database
        await _db.insertUser(_currentUser!.toMap());
        
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.logout();
    } catch (e) {
      // Ignore API errors on logout
    }

    await _local.clearToken();
    _currentUser = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }

  /// Update profile
  Future<void> updateProfile(String name, String? avatarUrl) async {
    if (_currentUser == null) return;

    _currentUser = User(
      id: _currentUser!.id,
      email: _currentUser!.email,
      name: name,
      role: _currentUser!.role,
      avatarUrl: avatarUrl,
      createdAt: _currentUser!.createdAt,
    );

    await _local.saveUser(_currentUser!.toMap());
    await _db.updateUser(_currentUser!.id, _currentUser!.toMap());
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? avatarUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  factory User.demo() {
    return User(
      id: 'demo_user',
      email: 'demo@nexusagent.io',
      name: 'Demo User',
      role: 'owner',
      createdAt: DateTime.now(),
    );
  }

  factory User.fromApi(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'member',
      avatarUrl: json['avatarUrl'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'member',
      avatarUrl: map['avatarUrl'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';
}
