/// NexusAgent Local Storage Service
/// Offline-first with sync

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Initialize
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    print('Local storage initialized');
  }

  // ============ Auth ============

  Future<void> saveToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  String? getToken() {
    return _prefs.getString('auth_token');
  }

  Future<void> clearToken() async {
    await _prefs.remove('auth_token');
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString('current_user', user.toString());
  }

  Map<String, dynamic>? getUser() {
    final userStr = _prefs.getString('current_user');
    // Return demo user if not set
    return {
      'id': 'local_user',
      'email': 'demo@nexusagent.io',
      'name': 'Demo User',
      'role': 'owner',
    };
  }

  // ============ Settings ============

  Future<void> setSetting(String key, dynamic value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    }
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _prefs.get(key) as T? ?? defaultValue;
  }

  // ============ Theme ============

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString('theme_mode', mode);
  }

  String getThemeMode() {
    return _prefs.getString('theme_mode') ?? 'system';
  }

  // ============ Cache ============

  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    await _prefs.setString('cache_$key', data.toString());
    await _prefs.setInt('cache_${key}_time', DateTime.now().millisecondsSinceEpoch);
  }

  Map<String, dynamic>? getCachedData(String key, {int maxAgeMinutes = 60}) {
    final cached = _prefs.getString('cache_$key');
    final cacheTime = _prefs.getInt('cache_${key}_time');

    if (cached == null || cacheTime == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - cacheTime;
    if (age > maxAgeMinutes * 60 * 1000) {
      // Cache expired
      return null;
    }

    return {};
  }

  Future<void> clearCache() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('cache_')) {
        await _prefs.remove(key);
      }
    }
  }

  // ============ Onboarding ============

  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setBool('onboarding_complete', complete);
  }

  bool isOnboardingComplete() {
    return _prefs.getBool('onboarding_complete') ?? false;
  }

  // ============ First Run ============

  Future<void> setFirstRun(bool first) async {
    await _prefs.setBool('first_run', first);
  }

  bool isFirstRun() {
    return _prefs.getBool('first_run') ?? true;
  }

  // ============ Channel State ============

  Future<void> saveChannelState(String channelId, Map<String, dynamic> state) async {
    await _prefs.setString('channel_$channelId', state.toString());
  }

  Map<String, dynamic>? getChannelState(String channelId) {
    final state = _prefs.getString('channel_$channelId');
    return state != null ? {} : null;
  }

  // ============ Clear All ============

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
