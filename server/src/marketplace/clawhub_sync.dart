/// NexusAgent ClawHub Sync
/// Connect to skill marketplace (compatible with OpenClaw's ClawHub)

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ClawHubConfig {
  final String apiUrl;
  final String? apiKey;
  final bool autoUpdate;
  final Duration syncInterval;

  ClawHubConfig({
    this.apiUrl = 'https://clawhub.com/api',
    this.apiKey,
    this.autoUpdate = false,
    this.syncInterval = const Duration(hours: 1),
  });
}

class SkillListing {
  final String slug;
  final String name;
  final String description;
  final String author;
  final String version;
  final List<String> tags;
  final int downloads;
  final double rating;
  final bool featured;
  final DateTime updatedAt;

  SkillListing({
    required this.slug,
    required this.name,
    required this.description,
    required this.author,
    required this.version,
    required this.tags,
    required this.downloads,
    required this.rating,
    required this.featured,
    required this.updatedAt,
  });

  factory SkillListing.fromJson(Map<String, dynamic> json) {
    return SkillListing(
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? 'unknown',
      version: json['version'] as String? ?? '1.0.0',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      downloads: json['downloads'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      featured: json['featured'] as bool? ?? false,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ClawHubSync {
  final ClawHubConfig config;
  final http.Client _client = http.Client();

  Timer? _syncTimer;
  Function(String skillSlug)? onSkillInstalled;
  Function(String skillSlug)? onSkillUpdated;
  Function(String skillSlug, String error)? onSkillFailed;

  ClawHubSync(this.config);

  /// Start auto-sync
  void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(config.syncInterval, (_) => sync());
  }

  /// Stop auto-sync
  void stopAutoSync() {
    _syncTimer?.cancel();
  }

  /// Search skills
  Future<List<SkillListing>> search(String query, {List<String>? tags, int limit = 20}) async {
    final uri = Uri.parse('${config.apiUrl}/skills/search').replace(
      queryParameters: {
        'q': query,
        if (tags != null) 'tags': tags.join(','),
        'limit': limit.toString(),
      },
    );

    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Search failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return (data['skills'] as List)
        .map((s) => SkillListing.fromJson(s))
        .toList();
  }

  /// Get featured skills
  Future<List<SkillListing>> getFeatured() async {
    final uri = Uri.parse('${config.apiUrl}/skills/featured');

    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to get featured: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return (data['skills'] as List)
        .map((s) => SkillListing.fromJson(s))
        .toList();
  }

  /// Get skill details
  Future<Map<String, dynamic>> getSkillDetails(String slug) async {
    final uri = Uri.parse('${config.apiUrl}/skills/$slug');

    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Skill not found: $slug');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Install skill
  Future<bool> install(String slug, {String? version}) async {
    try {
      // Get skill download URL
      final details = await getSkillDetails(slug);
      final downloadUrl = details['downloadUrl'] as String?;

      if (downloadUrl == null) {
        onSkillFailed?.call(slug, 'No download URL');
        return false;
      }

      // Download skill bundle
      final bundleResponse = await _client.get(Uri.parse(downloadUrl));

      if (bundleResponse.statusCode != 200) {
        onSkillFailed?.call(slug, 'Download failed');
        return false;
      }

      // In production, would extract and install the skill
      // For now, simulate
      print('Would install skill: $slug from $downloadUrl');
      
      onSkillInstalled?.call(slug);
      return true;
    } catch (e) {
      onSkillFailed?.call(slug, e.toString());
      return false;
    }
  }

  /// Update skill
  Future<bool> update(String slug) async {
    try {
      final details = await getSkillDetails(slug);
      
      // Check if update available
      // In production, compare versions
      
      print('Would update skill: $slug');
      onSkillUpdated?.call(slug);
      return true;
    } catch (e) {
      onSkillFailed?.call(slug, e.toString());
      return false;
    }
  }

  /// Sync installed skills
  Future<SyncResult> sync() async {
    final result = SyncResult();
    
    try {
      // Get installed skills from local storage
      // Check for updates
      
      print('Syncing with ClawHub...');
      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Publish skill (for skill developers)
  Future<bool> publish({
    required String name,
    required String description,
    required String readme,
    required List<String> tags,
    required Map<String, dynamic> config,
  }) async {
    final uri = Uri.parse('${config.apiUrl}/skills');

    final response = await _client.post(
      uri,
      headers: {
        ..._headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'readme': readme,
        'tags': tags,
        'config': config,
      }),
    );

    return response.statusCode == 201;
  }

  /// Report skill issue
  Future<bool> report(String slug, String issue, String description) async {
    final uri = Uri.parse('${config.apiUrl}/skills/$slug/report');

    final response = await _client.post(
      uri,
      headers: {
        ..._headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'issue': issue,
        'description': description,
      }),
    );

    return response.statusCode == 200;
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (config.apiKey != null) 'Authorization': 'Bearer ${config.apiKey}',
  };

  void dispose() {
    _syncTimer?.cancel();
    _client.close();
  }
}

class SyncResult {
  bool success = false;
  String? error;
  int installed = 0;
  int updated = 0;
  int failed = 0;
}
