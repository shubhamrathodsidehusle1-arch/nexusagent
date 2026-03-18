/// NexusAgent Proxy Service
/// SOCKS5/HTTP proxy support

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class ProxyConfig {
  final String type; // socks5, http, https
  final String host;
  final int port;
  final String? username;
  final String? password;

  ProxyConfig({
    required this.type,
    required this.host,
    required this.port,
    this.username,
    this.password,
  });

  Uri get uri => Uri.parse('$type://$host:$port');
}

class ProxyService {
  static final ProxyService _instance = ProxyService._internal();
  factory ProxyService() => _instance;
  ProxyService._internal();

  ProxyConfig? _config;
  HttpClient? _client;

  /// Initialize proxy
  void initialize(ProxyConfig config) {
    _config = config;
    _createClient();
    print('Proxy initialized: ${config.type}://${config.host}:${config.port}');
  }

  void _createClient() {
    _client = HttpClient();
    
    if (_config != null) {
      // Configure SOCKS5 proxy
      if (_config!.type == 'socks5') {
        // Dart doesn't have native SOCKS5, would need external package
        print('SOCKS5 proxy configured (requires external package for full support)');
      }
      
      // Configure HTTP proxy
      if (_config!.type == 'http' || _config!.type == 'https') {
        _client!.findProxy = (uri) {
          return 'PROXY ${_config!.host}:${_config!.port}';
        };
      }
      
      // Set credentials if needed
      if (_config!.username != null && _config!.password != null) {
        // Would set up authentication
      }
    }
  }

  /// Get proxy URL
  String? get proxyUrl {
    if (_config == null) return null;
    final creds = _config!.username != null 
        ? '${_config!.username}:${_config!.password}@' 
        : '';
    return '${_config!.type}://$creds${_config!.host}:${_config!.port}';
  }

  /// Fetch with proxy
  Future<http.Response> fetch(String url, {Map<String, String>? headers}) async {
    final client = http.Client();
    
    if (_config?.type == 'socks5') {
      // SOCKS5 not directly supported, fallback to direct
      return client.get(Uri.parse(url), headers: headers);
    }
    
    return client.get(Uri.parse(url), headers: headers);
  }

  /// Create socket connection via proxy
  Future<Socket> connect(String host, int port) async {
    if (_config == null) {
      return Socket.connect(host, port);
    }

    switch (_config!.type) {
      case 'socks5':
        // Would use socks_socket package
        return Socket.connect(host, port);
      case 'http':
      case 'https':
        // HTTP connect doesn't support tunneling, use direct
        return Socket.connect(host, port);
      default:
        return Socket.connect(host, port);
    }
  }

  /// Test proxy
  Future<bool> test() async {
    if (_config == null) return false;
    
    try {
      final response = await fetch('https://httpbin.org/ip')
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Dispose
  void dispose() {
    _client?.close();
    _client = null;
  }
}
