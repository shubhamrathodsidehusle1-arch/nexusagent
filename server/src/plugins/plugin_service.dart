/// NexusAgent Plugin System
/// Extensible plugin architecture

import 'dart:async';
import 'dart:io';
import 'dart:convert';

class PluginManifest {
  final String id;
  final String name;
  final String version;
  final String description;
  final String author;
  final String? homepage;
  final List<String> dependencies;
  final Map<String, PluginConfig> config;
  final List<String> skills;
  final List<String> tools;
  final Map<String, dynamic> metadata;

  PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    this.homepage,
    this.dependencies = const [],
    this.config = const {},
    this.skills = const [],
    this.tools = const [],
    this.metadata = const {},
  });

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    return PluginManifest(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      version: json['version'] ?? '1.0.0',
      description: json['description'] ?? '',
      author: json['author'] ?? 'unknown',
      homepage: json['homepage'],
      dependencies: List<String>.from(json['dependencies'] ?? []),
      config: (json['config'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, PluginConfig.fromJson(v)),
      ) ?? {},
      skills: List<String>.from(json['skills'] ?? []),
      tools: List<String>.from(json['tools'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'description': description,
    'author': author,
    'homepage': homepage,
    'dependencies': dependencies,
    'config': config.map((k, v) => MapEntry(k, v.toJson())),
    'skills': skills,
    'tools': tools,
    'metadata': metadata,
  };
}

class PluginConfig {
  final String type;
  final String? description;
  final bool required;
  final dynamic defaultValue;

  PluginConfig({
    required this.type,
    this.description,
    this.required = false,
    this.defaultValue,
  });

  factory PluginConfig.fromJson(Map<String, dynamic> json) {
    return PluginConfig(
      type: json['type'] ?? 'string',
      description: json['description'],
      required: json['required'] ?? false,
      defaultValue: json['default'],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'description': description,
    'required': required,
    'default': defaultValue,
  };
}

class Plugin {
  final PluginManifest manifest;
  final String path;
  final bool enabled;
  final DateTime loadedAt;
  final Map<String, dynamic> _exports;

  Plugin({
    required this.manifest,
    required this.path,
    this.enabled = false,
    DateTime? loadedAt,
    Map<String, dynamic>? exports,
  })  : loadedAt = loadedAt ?? DateTime.now(),
        _exports = exports ?? {};

  dynamic operator [](String key) => _exports[key];
  void operator []=(String key, dynamic value) => _exports[key] = value;
}

class PluginService {
  static final PluginService _instance = PluginService._internal();
  factory PluginService() => _instance;
  PluginService._internal();

  final Map<String, Plugin> _plugins = {};
  final List<String> _loadPaths = [];
  final _pluginController = StreamController<Plugin>.broadcast();

  Stream<Plugin> get pluginStream => _pluginController.stream;

  /// Add plugin search path
  void addLoadPath(String path) {
    if (!_loadPaths.contains(path)) {
      _loadPaths.add(path);
    }
  }

  /// Load plugin from directory
  Future<Plugin?> loadPlugin(String path) async {
    try {
      final manifestFile = File('$path/openclaw.plugin.json');
      if (!await manifestFile.exists()) {
        print('Plugin manifest not found: $path');
        return null;
      }

      final content = await manifestFile.readAsString();
      final manifest = PluginManifest.fromJson(jsonDecode(content));

      // Check for conflicts
      if (_plugins.containsKey(manifest.id)) {
        print('Plugin already loaded: ${manifest.id}');
        return null;
      }

      // Load plugin
      final plugin = Plugin(
        manifest: manifest,
        path: path,
        enabled: true,
      );

      _plugins[manifest.id] = plugin;
      _pluginController.add(plugin);

      print('Plugin loaded: ${manifest.name} v${manifest.version}');
      return plugin;
    } catch (e) {
      print('Failed to load plugin: $e');
      return null;
    }
  }

  /// Load all plugins from search paths
  Future<void> loadAllPlugins() async {
    for (final path in _loadPaths) {
      final dir = Directory(path);
      if (!await dir.exists()) continue;

      await for (final entity in dir.list()) {
        if (entity is Directory) {
          await loadPlugin(entity.path);
        }
      }
    }
  }

  /// Unload plugin
  void unloadPlugin(String pluginId) {
    final plugin = _plugins.remove(pluginId);
    if (plugin != null) {
      print('Plugin unloaded: ${plugin.manifest.name}');
    }
  }

  /// Enable/disable plugin
  void setEnabled(String pluginId, bool enabled) {
    final plugin = _plugins[pluginId];
    if (plugin != null) {
      _plugins[pluginId] = Plugin(
        manifest: plugin.manifest,
        path: plugin.path,
        enabled: enabled,
        loadedAt: plugin.loadedAt,
        exports: plugin._exports,
      );
    }
  }

  /// Get plugin
  Plugin? getPlugin(String pluginId) => _plugins[pluginId];

  /// List plugins
  List<Plugin> listPlugins() => _plugins.values.toList();

  /// List enabled plugins
  List<Plugin> get enabledPlugins => 
      _plugins.values.where((p) => p.enabled).toList();

  /// Get plugin skills
  List<String> getPluginSkills() {
    final skills = <String>[];
    for (final plugin in enabledPlugins) {
      skills.addAll(plugin.manifest.skills);
    }
    return skills;
  }

  /// Get plugin tools
  List<String> getPluginTools() {
    final tools = <String>[];
    for (final plugin in enabledPlugins) {
      tools.addAll(plugin.manifest.tools);
    }
    return tools;
  }

  /// Get plugin config schema
  Map<String, PluginConfig> getPluginConfig(String pluginId) {
    return _plugins[pluginId]?.manifest.config ?? {};
  }

  /// Dispose
  void dispose() {
    _plugins.clear();
    _pluginController.close();
  }
}
