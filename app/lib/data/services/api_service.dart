/// NexusAgent API Service
/// Connects mobile app to backend

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  String? _baseUrl;
  String? _token;

  /// Initialize with base URL
  void initialize({required String baseUrl}) {
    _baseUrl = baseUrl;

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle common errors
        if (error.response?.statusCode == 401) {
          // Token expired, need to refresh
          _token = null;
        }
        return handler.next(error);
      },
    ));
  }

  /// Set auth token
  Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  /// Get stored token
  Future<void> loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }

  /// Clear token
  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: 'auth_token');
  }

  // ============ Auth ============

  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    final response = await _dio.post('/api/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    if (response.data['token'] != null) {
      await setToken(response.data['token']);
    }
    return response.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/api/auth/me');
    return response.data;
  }

  // ============ Agents ============

  Future<List<dynamic>> getAgents() async {
    final response = await _dio.get('/api/agents');
    return response.data['agents'] ?? [];
  }

  Future<Map<String, dynamic>> getAgent(String agentId) async {
    final response = await _dio.get('/api/agents/$agentId');
    return response.data;
  }

  Future<Map<String, dynamic>> createAgent(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/agents', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateAgent(String agentId, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/agents/$agentId', data: data);
    return response.data;
  }

  Future<void> deleteAgent(String agentId) async {
    await _dio.delete('/api/agents/$agentId');
  }

  Future<Map<String, dynamic>> runAgent(String agentId, String input, {String? sessionId}) async {
    final response = await _dio.post('/api/agents/$agentId/run', data: {
      'input': input,
      if (sessionId != null) 'sessionId': sessionId,
    });
    return response.data;
  }

  // ============ Tools ============

  Future<List<dynamic>> getTools() async {
    final response = await _dio.get('/api/tools');
    return response.data['tools'] ?? [];
  }

  Future<Map<String, dynamic>> executeTool(String toolName, Map<String, dynamic> params) async {
    final response = await _dio.post('/api/tools/execute', data: {
      'toolName': toolName,
      'params': params,
    });
    return response.data;
  }

  // ============ Skills ============

  Future<List<dynamic>> getSkills() async {
    final response = await _dio.get('/api/skills');
    return response.data['skills'] ?? [];
  }

  Future<Map<String, dynamic>> installSkill(String source) async {
    final response = await _dio.post('/api/skills', data: {'source': source});
    return response.data;
  }

  // ============ Workflows ============

  Future<List<dynamic>> getWorkflows() async {
    final response = await _dio.get('/api/workflows');
    return response.data['workflows'] ?? [];
  }

  Future<Map<String, dynamic>> createWorkflow(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/workflows', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateWorkflow(String workflowId, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/workflows/$workflowId', data: data);
    return response.data;
  }

  Future<void> deleteWorkflow(String workflowId) async {
    await _dio.delete('/api/workflows/$workflowId');
  }

  Future<Map<String, dynamic>> runWorkflow(String workflowId) async {
    final response = await _dio.post('/api/workflows/$workflowId/run');
    return response.data;
  }

  // ============ Cron ============

  Future<List<dynamic>> getCronJobs() async {
    final response = await _dio.get('/api/cron');
    return response.data['jobs'] ?? [];
  }

  Future<Map<String, dynamic>> createCronJob(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/cron', data: data);
    return response.data;
  }

  Future<void> deleteCronJob(String jobId) async {
    await _dio.delete('/api/cron/$jobId');
  }

  // ============ Sessions ============

  Future<List<dynamic>> getSessions() async {
    final response = await _dio.get('/api/sessions');
    return response.data['sessions'] ?? [];
  }

  Future<Map<String, dynamic>> getSession(String sessionId) async {
    final response = await _dio.get('/api/sessions/$sessionId');
    return response.data;
  }

  Future<void> endSession(String sessionId) async {
    await _dio.delete('/api/sessions/$sessionId');
  }

  // ============ Channels ============

  Future<List<dynamic>> getChannels() async {
    final response = await _dio.get('/api/channels');
    return response.data['channels'] ?? [];
  }

  Future<void> enableChannel(String channelId) async {
    await _dio.post('/api/channels/$channelId/enable');
  }

  Future<void> disableChannel(String channelId) async {
    await _dio.post('/api/channels/$channelId/disable');
  }

  // ============ Analytics ============

  Future<Map<String, dynamic>> getAnalytics({
    String? startDate,
    String? endDate,
    String? agentId,
  }) async {
    final response = await _dio.get('/api/analytics', queryParameters: {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (agentId != null) 'agentId': agentId,
    });
    return response.data;
  }

  // ============ Team ============

  Future<List<dynamic>> getTeamMembers() async {
    final response = await _dio.get('/api/team/members');
    return response.data['members'] ?? [];
  }

  Future<Map<String, dynamic>> inviteMember(String email, String role) async {
    final response = await _dio.post('/api/team/invite', data: {
      'email': email,
      'role': role,
    });
    return response.data;
  }

  Future<void> updateMemberRole(String memberId, String role) async {
    await _dio.put('/api/team/members/$memberId', data: {'role': role});
  }

  Future<void> removeMember(String memberId) async {
    await _dio.delete('/api/team/members/$memberId');
  }

  // ============ Health ============

  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _dio.get('/health');
    return response.data;
  }
}
