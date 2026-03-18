/// NexusAgent Team Provider - Connected
/// Real team/user management

import 'package:flutter/material.dart';
import '../../data/services/database_service.dart';
import '../../data/services/api_service.dart';

class TeamProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final ApiService _api = ApiService();

  List<TeamMember> _members = [];
  bool _isLoading = false;
  String? _error;

  List<TeamMember> get members => _members;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load members if authenticated
  Future<void> loadIfAuthenticated(bool isAuthenticated) async {
    if (isAuthenticated) {
      await loadMembers();
    }
  }

  /// Load all team members
  Future<void> loadMembers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try local database first
      final dbUsers = await _db.getUsers();
      
      if (dbUsers.isNotEmpty) {
        _members = dbUsers.map((u) => TeamMember.fromMap(u)).toList();
      } else {
        // Load demo members
        _members = _getDemoMembers();
        
        // Save to database
        for (final member in _members) {
          await _db.insertUser(member.toMap());
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get demo members
  List<TeamMember> _getDemoMembers() {
    return [
      TeamMember(
        id: 'user_1',
        email: 'demo@nexusagent.io',
        name: 'Demo User',
        role: 'owner',
        avatarUrl: null,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      TeamMember(
        id: 'user_2',
        email: 'admin@nexusagent.io',
        name: 'Admin User',
        role: 'admin',
        avatarUrl: null,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      TeamMember(
        id: 'user_3',
        email: 'member@nexusagent.io',
        name: 'Team Member',
        role: 'member',
        avatarUrl: null,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  /// Invite member
  Future<void> inviteMember(String email, String role) async {
    final member = TeamMember(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: email.split('@').first,
      role: role,
      createdAt: DateTime.now(),
    );

    _members.add(member);
    notifyListeners();

    await _db.insertUser(member.toMap());
  }

  /// Update member role
  Future<void> updateMemberRole(String id, String role) async {
    final index = _members.indexWhere((m) => m.id == id);
    if (index != -1) {
      final member = _members[index];
      _members[index] = TeamMember(
        id: member.id,
        email: member.email,
        name: member.name,
        role: role,
        avatarUrl: member.avatarUrl,
        createdAt: member.createdAt,
      );
      notifyListeners();

      await _db.updateUser(id, _members[index].toMap());
    }
  }

  /// Remove member
  Future<void> removeMember(String id) async {
    _members.removeWhere((m) => m.id == id);
    notifyListeners();

    await _db.deleteUser(id);
  }

  /// Get member by ID
  TeamMember? getMember(String id) {
    return _members.where((m) => m.id == id).firstOrNull;
  }

  /// Get role color
  Color getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      case 'member':
        return Colors.green;
      case 'viewer':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class TeamMember {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? avatarUrl;
  final DateTime createdAt;

  TeamMember({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'member',
      avatarUrl: map['avatarUrl'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'avatarUrl': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
}
