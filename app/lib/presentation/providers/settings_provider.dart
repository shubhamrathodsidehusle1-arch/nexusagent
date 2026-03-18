/// NexusAgent Settings Provider
/// Connected to database and local storage

import 'package:flutter/material.dart';
import '../data/services/database_service.dart';
import '../data/services/local_storage_service.dart';
import '../data/services/api_service.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final LocalStorageService _local = LocalStorageService();
  final ApiService _api = ApiService();

  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _language = 'en';
  String _serverUrl = 'http://localhost:3000';
  int _sessionTimeout = 24; // hours
  bool _autoSync = true;
  bool _isLoading = false;
  String? _error;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  String get language => _language;
  String get serverUrl => _serverUrl;
  int get sessionTimeout => _sessionTimeout;
  bool get autoSync => _autoSync;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load settings
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load from local storage
      final themeModeStr = _local.getThemeMode();
      _themeMode = _themeModeFromString(themeModeStr);
      
      _notificationsEnabled = _local.getSetting<bool>('notifications_enabled') ?? true;
      _soundEnabled = _local.getSetting<bool>('sound_enabled') ?? true;
      _vibrationEnabled = _local.getSetting<bool>('vibration_enabled') ?? true;
      _language = _local.getSetting<String>('language') ?? 'en';
      _serverUrl = _local.getSetting<String>('server_url') ?? 'http://localhost:3000';
      _sessionTimeout = _local.getSetting<int>('session_timeout') ?? 24;
      _autoSync = _local.getSetting<bool>('auto_sync') ?? true;

      // Try to load from database
      final dbTheme = await _db.getSetting('theme_mode');
      if (dbTheme != null) {
        _themeMode = _themeModeFromString(dbTheme);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _local.setThemeMode(_themeModeToString(mode));
    await _db.setSetting('theme_mode', _themeModeToString(mode));
    notifyListeners();
  }

  /// Set notifications
  Future<void> setNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    await _local.setSetting('notifications_enabled', enabled);
    notifyListeners();
  }

  /// Set sound
  Future<void> setSound(bool enabled) async {
    _soundEnabled = enabled;
    await _local.setSetting('sound_enabled', enabled);
    notifyListeners();
  }

  /// Set vibration
  Future<void> setVibration(bool enabled) async {
    _vibrationEnabled = enabled;
    await _local.setSetting('vibration_enabled', enabled);
    notifyListeners();
  }

  /// Set language
  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _local.setSetting('language', lang);
    notifyListeners();
  }

  /// Set server URL
  Future<void> setServerUrl(String url) async {
    _serverUrl = url;
    await _local.setSetting('server_url', url);
    _api.updateBaseUrl(url);
    notifyListeners();
  }

  /// Set session timeout
  Future<void> setSessionTimeout(int hours) async {
    _sessionTimeout = hours;
    await _local.setSetting('session_timeout', hours);
    notifyListeners();
  }

  /// Set auto sync
  Future<void> setAutoSync(bool enabled) async {
    _autoSync = enabled;
    await _local.setSetting('auto_sync', enabled);
    notifyListeners();
  }

  /// Test server connection
  Future<bool> testConnection() async {
    try {
      return await _api.testConnection();
    } catch (e) {
      return false;
    }
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    await _local.setThemeMode('system');
    await _local.setSetting('notifications_enabled', true);
    await _local.setSetting('sound_enabled', true);
    await _local.setSetting('vibration_enabled', true);
    await _local.setSetting('language', 'en');
    await _local.setSetting('session_timeout', 24);
    await _local.setSetting('auto_sync', true);
    
    _themeMode = ThemeMode.system;
    _notificationsEnabled = true;
    _soundEnabled = true;
    _vibrationEnabled = true;
    _language = 'en';
    _sessionTimeout = 24;
    _autoSync = true;
    
    notifyListeners();
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
