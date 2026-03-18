/// NexusAgent Streaming Service
/// Real-time streaming responses

import 'dart:async';

enum StreamingMode {
  off,
  partial,
  block,
  progress,
}

class StreamChunk {
  final String content;
  final bool isFinal;
  final Map<String, dynamic>? metadata;

  StreamChunk({
    required this.content,
    this.isFinal = false,
    this.metadata,
  });
}

class StreamingService {
  static final StreamingService _instance = StreamingService._internal();
  factory StreamingService() => _instance;
  StreamingService._internal();

  final Map<String, StreamController<StreamChunk>> _streams = {};

  /// Create streaming session
  Stream<StreamChunk> createStream(String sessionId) {
    final controller = StreamController<StreamChunk>.broadcast();
    _streams[sessionId] = controller;
    return controller.stream;
  }

  /// Send chunk
  void sendChunk(String sessionId, StreamChunk chunk) {
    _streams[sessionId]?.add(chunk);
  }

  /// Send final chunk and close
  void endStream(String sessionId, String finalContent) {
    final controller = _streams[sessionId];
    if (controller != null) {
      controller.add(StreamChunk(content: finalContent, isFinal: true));
      controller.close();
      _streams.remove(sessionId);
    }
  }

  /// Cancel stream
  void cancelStream(String sessionId) {
    _streams[sessionId]?.close();
    _streams.remove(sessionId);
  }

  /// Check if streaming
  bool isStreaming(String sessionId) {
    return _streams.containsKey(sessionId);
  }

  /// Get active stream count
  int get activeStreams => _streams.length;
}
