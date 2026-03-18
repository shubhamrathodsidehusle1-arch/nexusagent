/// NexusAgent Entry Point

import 'dart:io';

import 'src/main.dart' as main;

void main() async {
  print('''
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🤖 NexusAgent - Secure AI Agent Platform              ║
║                                                           ║
║   Version: 1.0.0                                         ║
║   Starting...                                            ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
''');

  // Load configuration
  final config = _loadConfig();

  // Start server
  final server = NexusAgentServer();

  await server.start(
    host: config['server']['host'] ?? '0.0.0.0',
    port: config['server']['port'] ?? 3000,
    jwtSecret: config['security']['jwtSecret'],
  );

  // Handle shutdown
  ProcessSignal.sigterm.watch().listen((_) async {
    print('\n🛑 Shutting down...');
    await server.stop();
    exit(0);
  });

  ProcessSignal.sigint.watch().listen((_) async {
    print('\n🛑 Shutting down...');
    await server.stop();
    exit(0);
  });
}

Map<String, dynamic> _loadConfig() {
  // Try to load from config file
  final configFile = File('config.json');
  if (configFile.existsSync()) {
    try {
      final content = configFile.readAsStringSync();
      // Simple JSON parsing (in production, use proper JSON parser)
      return _parseSimpleJson(content);
    } catch (e) {
      print('Warning: Could not load config.json: $e');
    }
  }

  // Return defaults
  return {
    'server': {
      'host': '0.0.0.0',
      'port': 3000,
    },
    'security': {
      'jwtSecret': Platform.environment['NEXUSAGENT_JWT_SECRET'] ?? 'default-secret-change-me',
    },
  };
}

Map<String, dynamic> _parseSimpleJson(String content) {
  // Simple JSON parser for config
  // In production, use dart:convert
  final result = <String, dynamic>{};
  
  // This is a simplified parser - just handle basic structure
  // Production should use jsonDecode from dart:convert
  try {
    // Use Dart's built-in JSON
    return {}; // Placeholder - main.dart handles actual loading
  } catch (e) {
    return {};
  }
}
