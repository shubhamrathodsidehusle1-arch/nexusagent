/// RBAC (Role-Based Access Control) System
/// Enterprise-grade permission management

enum Permission {
  // Agents
  agent_read,
  agent_create,
  agent_edit,
  agent_delete,
  agent_execute,
  
  // Channels
  channel_read,
  channel_configure,
  channel_enable,
  channel_disable,
  
  // Tools
  tool_execute,
  tool_configure,
  
  // Workflows
  workflow_read,
  workflow_create,
  workflow_edit,
  workflow_delete,
  workflow_execute,
  
  // Sessions
  session_read,
  session_end,
  
  // Users
  user_read,
  user_invite,
  user_remove,
  user_role_change,
  
  // Settings
  settings_read,
  settings_edit,
  
  // Audit
  audit_read,
  
  // Admin
  admin_access,
}

enum Role {
  owner,
  admin,
  member,
  viewer,
}

class RolePermissions {
  final Role role;
  final List<Permission> permissions;

  const RolePermissions(this.role, this.permissions);

  static final Map<Role, RolePermissions> defaults = {
    Role.owner: RolePermissions(Role.owner, Permission.values),
    Role.admin: RolePermissions(Role.admin, [
      Permission.agent_read,
      Permission.agent_create,
      Permission.agent_edit,
      Permission.agent_delete,
      Permission.agent_execute,
      Permission.channel_read,
      Permission.channel_configure,
      Permission.channel_enable,
      Permission.channel_disable,
      Permission.tool_execute,
      Permission.tool_configure,
      Permission.workflow_read,
      Permission.workflow_create,
      Permission.workflow_edit,
      Permission.workflow_delete,
      Permission.workflow_execute,
      Permission.session_read,
      Permission.session_end,
      Permission.settings_read,
      Permission.settings_edit,
      Permission.audit_read,
    ]),
    Role.member: RolePermissions(Role.member, [
      Permission.agent_read,
      Permission.agent_execute,
      Permission.channel_read,
      Permission.tool_execute,
      Permission.workflow_read,
      Permission.workflow_execute,
      Permission.session_read,
    ]),
    Role.viewer: RolePermissions(Role.viewer, [
      Permission.agent_read,
      Permission.channel_read,
      Permission.workflow_read,
      Permission.session_read,
    ]),
  };
}

class User {
  final String id;
  final String email;
  final String name;
  final Role role;
  final String? workspaceId;
  final DateTime createdAt;
  final bool active;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.workspaceId,
    required this.createdAt,
    this.active = true,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    Role? role,
    String? workspaceId,
    DateTime? createdAt,
    bool? active,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      workspaceId: workspaceId ?? this.workspaceId,
      createdAt: createdAt ?? this.createdAt,
      active: active ?? this.active,
    );
  }
}

class RBACService {
  static final RBACService _instance = RBACService._internal();
  factory RBACService() => _instance;
  RBACService._internal();

  final Map<String, User> _users = {};
  final Map<String, Set<Permission>> _customPermissions = {}; // userId -> custom permissions

  /// Check if user has permission
  bool hasPermission(String userId, Permission permission) {
    final user = _users[userId];
    if (user == null) return false;
    if (!user.active) return false;

    // Check custom permissions first
    final custom = _customPermissions[userId];
    if (custom != null && custom.contains(permission)) {
      return true;
    }

    // Check role permissions
    final rolePerms = RolePermissions.defaults[user.role];
    return rolePerms?.permissions.contains(permission) ?? false;
  }

  /// Check if user has any of the permissions
  bool hasAnyPermission(String userId, List<Permission> permissions) {
    return permissions.any((p) => hasPermission(userId, p));
  }

  /// Check if user has all of the permissions
  bool hasAllPermissions(String userId, List<Permission> permissions) {
    return permissions.every((p) => hasPermission(userId, p));
  }

  /// Add user
  void addUser(User user) {
    _users[user.id] = user;
  }

  /// Remove user
  void removeUser(String userId) {
    _users.remove(userId);
    _customPermissions.remove(userId);
  }

  /// Update user role
  void updateUserRole(String userId, Role role) {
    final user = _users[userId];
    if (user != null) {
      _users[userId] = user.copyWith(role: role);
    }
  }

  /// Set custom permissions for user
  void setCustomPermissions(String userId, Set<Permission> permissions) {
    _customPermissions[userId] = permissions;
  }

  /// Get user
  User? getUser(String userId) => _users[userId];

  /// List users in workspace
  List<User> listUsers(String workspaceId) {
    return _users.values
        .where((u) => u.workspaceId == workspaceId)
        .toList();
  }

  /// Invite user
  Future<User> inviteUser({
    required String email,
    required String name,
    required Role role,
    required String workspaceId,
  }) async {
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      role: role,
      workspaceId: workspaceId,
      createdAt: DateTime.now(),
    );
    addUser(user);
    return user;
  }

  /// Get role name
  String getRoleName(Role role) {
    switch (role) {
      case Role.owner: return 'Owner';
      case Role.admin: return 'Admin';
      case Role.member: return 'Member';
      case Role.viewer: return 'Viewer';
    }
  }

  /// Get role description
  String getRoleDescription(Role role) {
    switch (role) {
      case Role.owner: return 'Full access to everything';
      case Role.admin: return 'Can manage all settings and users';
      case Role.member: return 'Can use agents and workflows';
      case Role.viewer: return 'Read-only access';
    }
  }

  /// Get permission label
  String getPermissionLabel(Permission permission) {
    return permission.name.replaceAll('_', ' ').split(' ').map((w) => 
      w[0].toUpperCase() + w.substring(1)
    ).join(' ');
  }
}
