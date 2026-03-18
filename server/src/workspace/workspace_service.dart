/// NexusAgent Multi-Tenant Workspace Service
/// Fixes: OpenClaw not designed for adversarial multi-user environments

import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

enum WorkspaceRole {
  owner,
  admin,
  member,
  viewer,
}

class Workspace {
  final String id;
  final String name;
  final String ownerId;
  final Map<String, WorkspaceRole> members;
  final Map<String, dynamic> settings;
  final DateTime createdAt;

  Workspace({
    required this.id,
    required this.name,
    required this.ownerId,
    Map<String, WorkspaceRole>? members,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
  })  : members = members ?? {},
        settings = settings ?? {},
        createdAt = createdAt ?? DateTime.now();
}

class WorkspaceService {
  static final WorkspaceService _instance = WorkspaceService._internal();
  factory WorkspaceService() => _instance;
  WorkspaceService._internal();

  final Map<String, Workspace> _workspaces = {};
  final Map<String, String> _userWorkspaces = {}; // userId -> workspaceId

  /// Create workspace
  Workspace createWorkspace({
    required String name,
    required String ownerId,
  }) {
    final workspace = Workspace(
      id: _generateId(),
      name: name,
      ownerId: ownerId,
      members: {ownerId: WorkspaceRole.owner},
    );

    _workspaces[workspace.id] = workspace;
    _userWorkspaces[ownerId] = workspace.id;

    return workspace;
  }

  /// Get workspace
  Workspace? getWorkspace(String workspaceId) {
    return _workspaces[workspaceId];
  }

  /// Get workspace for user
  Workspace? getUserWorkspace(String userId) {
    final workspaceId = _userWorkspaces[userId];
    if (workspaceId == null) return null;
    return _workspaces[workspaceId];
  }

  /// Add member to workspace
  bool addMember(String workspaceId, String userId, WorkspaceRole role) {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) return false;

    workspace.members[userId] = role;
    _userWorkspaces[userId] = workspaceId;

    return true;
  }

  /// Remove member
  bool removeMember(String workspaceId, String userId) {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) return false;

    workspace.members.remove(userId);
    _userWorkspaces.remove(userId);

    return true;
  }

  /// Check if user has access
  bool hasAccess(String workspaceId, String userId, {WorkspaceRole? minRole}) {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) return false;

    final role = workspace.members[userId];
    if (role == null) return false;

    if (minRole == null) return true;

    // Check role hierarchy
    final roleLevels = {
      WorkspaceRole.owner: 4,
      WorkspaceRole.admin: 3,
      WorkspaceRole.member: 2,
      WorkspaceRole.viewer: 1,
    };

    return (roleLevels[role] ?? 0) >= (roleLevels[minRole] ?? 0);
  }

  /// List workspaces for user
  List<Workspace> listUserWorkspaces(String userId) {
    return _workspaces.values
        .where((w) => w.members.containsKey(userId))
        .toList();
  }

  /// Update workspace settings
  bool updateSettings(String workspaceId, Map<String, dynamic> settings) {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) return false;

    workspace.settings.addAll(settings);
    return true;
  }

  /// Delete workspace
  bool deleteWorkspace(String workspaceId, String requestingUserId) {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) return false;

    // Only owner can delete
    if (workspace.ownerId != requestingUserId) return false;

    // Remove all member associations
    for (final userId in workspace.members.keys) {
      _userWorkspaces.remove(userId);
    }

    _workspaces.remove(workspaceId);
    return true;
  }

  String _generateId() {
    final data = '${DateTime.now().microsecondsSinceEpoch}';
    return sha256.convert(utf8.encode(data)).toString().substring(0, 16);
  }
}
