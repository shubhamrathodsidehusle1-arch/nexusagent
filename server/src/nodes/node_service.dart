/// NexusAgent Node Pairing System
/// Mobile device pairing for remote control

import 'dart:async';
import 'dart:convert';
import 'dart:math';

class NodePairingConfig {
  final Duration codeExpiry;
  final int codeLength;
  final Duration sessionTimeout;

  NodePairingConfig({
    this.codeExpiry = const Duration(seconds: 10), // Much shorter than OpenClaw
    this.codeLength = 6,
    this.sessionTimeout = const Duration(days: 30),
  });
}

class PairedNode {
  final String id;
  final String name;
  final String platform; // ios, android, mac, windows, linux
  final String deviceToken;
  final DateTime pairedAt;
  DateTime lastSeen;
  final Map<String, dynamic> capabilities;

  PairedNode({
    required this.id,
    required this.name,
    required this.platform,
    required this.deviceToken,
    required this.pairedAt,
    DateTime? lastSeen,
    this.capabilities = const {},
  }) : lastSeen = lastSeen ?? pairedAt;
}

class PairingRequest {
  final String code;
  final String nodeName;
  final String platform;
  final DateTime createdAt;
  final Completer<PairedNode> completer;

  PairingRequest({
    required this.code,
    required this.nodeName,
    required this.platform,
    required this.completer,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class NodeService {
  static final NodeService _instance = NodeService._internal();
  factory NodeService() => _instance;
  NodeService._internal();

  NodePairingConfig _config = NodePairingConfig();
  final Map<String, PairedNode> _pairedNodes = {};
  final Map<String, PairingRequest> _pendingPairings = {};
  Timer? _cleanupTimer;

  // Callbacks
  Function(PairedNode node)? onNodePaired;
  Function(String nodeId)? onNodeDisconnected;

  /// Initialize
  void initialize(NodePairingConfig config) {
    _config = config;
    _startCleanup();
    print('Node pairing service initialized');
  }

  /// Generate pairing code
  String generatePairingCode(String nodeName, String platform) {
    final code = _generateCode();
    
    final completer = Completer<PairedNode>();
    _pendingPairings[code] = PairingRequest(
      code: code,
      nodeName: nodeName,
      platform: platform,
      completer: completer,
    );

    // Auto-expire
    Timer(_config.codeExpiry, () {
      if (!_pendingPairings[code]!.completer.isCompleted) {
        _pendingPairings[code]!.completer.completeError('Pairing code expired');
        _pendingPairings.remove(code);
      }
    });

    return code;
  }

  /// Complete pairing
  Future<PairedNode> completePairing(
    String code,
    String deviceToken,
    Map<String, dynamic> capabilities,
  ) async {
    final request = _pendingPairings[code];
    if (request == null) {
      throw Exception('Invalid or expired pairing code');
    }

    if (request.completer.isCompleted) {
      throw Exception('Pairing already completed');
    }

    final nodeId = _generateId();
    final node = PairedNode(
      id: nodeId,
      name: request.nodeName,
      platform: request.platform,
      deviceToken: deviceToken,
      pairedAt: DateTime.now(),
      capabilities: capabilities,
    );

    _pairedNodes[nodeId] = node;
    _pendingPairings.remove(code);

    request.completer.complete(node);
    onNodePaired?.call(node);

    return node;
  }

  /// Get node by ID
  PairedNode? getNode(String nodeId) {
    return _pairedNodes[nodeId];
  }

  /// List all paired nodes
  List<PairedNode> listNodes() {
    return _pairedNodes.values.toList();
  }

  /// Update node last seen
  void updateLastSeen(String nodeId) {
    _pairedNodes[nodeId]?.lastSeen = DateTime.now();
  }

  /// Send command to node
  Future<Map<String, dynamic>?> sendCommand(
    String nodeId,
    String command,
    Map<String, dynamic> params,
  ) async {
    final node = _pairedNodes[nodeId];
    if (node == null) {
      throw Exception('Node not found: $nodeId');
    }

    // In production, would send via push notification or WebSocket
    print('Would send command to node $nodeId: $command');
    return {'status': 'sent'};
  }

  /// Request node location
  Future<Map<String, dynamic>?> getLocation(String nodeId) async {
    final node = _pairedNodes[nodeId];
    if (node == null) return null;

    // In production, would request location from device
    return {
      'latitude': 0.0,
      'longitude': 0.0,
      'accuracy': 0,
    };
  }

  /// Take screenshot on node
  Future<String?> takeScreenshot(String nodeId) async {
    final node = _pairedNodes[nodeId];
    if (node == null) return null;

    // In production, would trigger screenshot on device
    print('Would take screenshot on node $nodeId');
    return null;
  }

  /// List photos on node
  Future<List<Map<String, dynamic>>> listPhotos(String nodeId, {int limit = 10}) async {
    final node = _pairedNodes[nodeId];
    if (node == null) return [];

    // In production, would list photos from device
    return [];
  }

  /// Unpair node
  void unpair(String nodeId) {
    _pairedNodes.remove(nodeId);
    onNodeDisconnected?.call(nodeId);
  }

  /// Generate code
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No ambiguous chars
    final random = Random.secure();
    return List.generate(_config.codeLength, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generate ID
  String _generateId() {
    final random = Random.secure();
    return List.generate(32, (_) => '0123456789abcdef'[random.nextInt(16)]).join();
  }

  /// Cleanup expired pairings
  void _startCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final now = DateTime.now();
      
      // Remove expired pending pairings
      _pendingPairings.removeWhere((code, request) {
        return now.difference(request.createdAt) > _config.codeExpiry;
      });

      // Check for dead nodes
      _pairedNodes.removeWhere((id, node) {
        return now.difference(node.lastSeen) > _config.sessionTimeout;
      });
    });
  }

  /// Shutdown
  void shutdown() {
    _cleanupTimer?.cancel();
    _pairedNodes.clear();
    _pendingPairings.clear();
  }
}
