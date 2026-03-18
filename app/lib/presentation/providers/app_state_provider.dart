/// NexusAgent App State Provider
/// Global app state

import 'package:flutter/material.dart';
import '../../data/services/local_storage_service.dart';

class AppStateProvider extends ChangeNotifier {
  final LocalStorageService _local = LocalStorageService();

  bool _isInitialized = false;
  bool _isOnline = true;
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'en';
  bool _showOnboarding = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isOnline => _isOnline;
  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get showOnboarding => _showOnboarding;

  /// Initialize app state
  Future<void> initialize() async {
    await _local.initialize();
    await loadSettings();
    _isInitialized = true;
    notifyListeners();
  }

  /// Load settings
  Future<void> loadSettings() async {
    final themeStr = _local.getThemeMode();
    _themeMode = _themeModeFromString(themeStr);
    _language = _local.getSetting<String>('language') ?? 'en';
    _showOnboarding = !_local.isOnboardingComplete();
    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _local.setThemeMode(_themeModeToString(mode));
    notifyListeners();
  }

  /// Set language
  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _local.setSetting('language', lang);
    notifyListeners();
  }

  /// Set online status
  void setOnline(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    _showOnboarding = false;
    await _local.setOnboardingComplete(true);
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
}
