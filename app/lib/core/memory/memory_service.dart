/// Memory Management Service - Fixes OpenClaw memory issues
/// Addresses: Session context overflow, unbounded memory growth, inefficient retrieval

import 'dart:convert';
import 'dart:math';

class MemoryService {
  // Singleton
  static final MemoryService _instance = MemoryService._internal();
  factory MemoryService() => _instance;
  MemoryService._internal();

  // ============ CONFIGURATION ============
  
  /// Maximum tokens per session (OpenClaw: unbounded)
  int maxSessionTokens = 8000;
  
  /// Maximum memories to store per session
  int maxSessionMemories = 100;
  
  /// Auto-prune threshold (percentage)
  double pruneThreshold = 0.8;
  
  /// Semantic similarity threshold
  double similarityThreshold = 0.7;

  // ============ STORAGE ============
  
  final Map<String, List<MemoryEntry>> _sessionMemory = {};
  final Map<String, List<SemanticMemory>> _semanticMemory = {};
  final Map<String, int> _tokenUsage = {};

  // ============ SESSION MEMORY MANAGEMENT ============

  /// Add memory to session with automatic pruning
  void addToSession(String sessionId, MemoryEntry entry) {
    _sessionMemory[sessionId] ??= [];
    
    // Check token limit
    int currentTokens = _tokenUsage[sessionId] ?? 0;
    if (currentTokens + entry.tokens > maxSessionTokens) {
      _pruneSession(sessionId);
    }

    _sessionMemory[sessionId]!.add(entry);
    _tokenUsage[sessionId] = currentTokens + entry.tokens;

    // Also add to semantic memory for search
    _addToSemantic(sessionId, entry);
  }

  /// Get session context within token limit
  List<MemoryEntry> getSessionContext(String sessionId, {int? maxTokens}) {
    final memories = _sessionMemory[sessionId] ?? [];
    if (maxTokens == null) maxTokens = maxSessionTokens;

    // Start from most recent
    List<MemoryEntry> context = [];
    int tokenCount = 0;

    for (int i = memories.length - 1; i >= 0 && tokenCount < maxTokens; i--) {
      context.insert(0, memories[i]);
      tokenCount += memories[i].tokens;
    }

    return context;
  }

  /// Prune old memories when limit reached
  void _pruneSession(String sessionId) {
    final memories = _sessionMemory[sessionId];
    if (memories == null || memories.isEmpty) return;

    // Remove oldest memories until under threshold
    int targetTokens = (maxSessionTokens * pruneThreshold).toInt();
    int currentTokens = _tokenUsage[sessionId] ?? 0;

    while (currentTokens > targetTokens && memories.isNotEmpty) {
      final removed = memories.removeAt(0);
      currentTokens -= removed.tokens;
    }

    _tokenUsage[sessionId] = currentTokens;
  }

  // ============ SEMANTIC MEMORY (Vector-like search) ============

  /// Add to semantic index
  void _addToSemantic(String sessionId, MemoryEntry entry) {
    _semanticMemory[sessionId] ??= [];
    
    // Generate simple embedding hash (in production, use actual embeddings)
    final embedding = _generateEmbedding(entry.content);
    
    _semanticMemory[sessionId]!.add(SemanticMemory(
      content: entry.content,
      embedding: embedding,
      timestamp: entry.timestamp,
      metadata: entry.metadata,
    ));
  }

  /// Search semantic memory
  List<SemanticMemory> searchSemantic(String sessionId, String query, {int limit = 5}) {
    final memories = _semanticMemory[sessionId];
    if (memories == null || memories.isEmpty) return [];

    final queryEmbedding = _generateEmbedding(query);
    
    // Calculate similarities
    List<MapEntry<SemanticMemory, double>> scored = [];
    for (final memory in memories) {
      double similarity = _cosineSimilarity(queryEmbedding, memory.embedding);
      if (similarity >= similarityThreshold) {
        scored.add(MapEntry(memory, similarity));
      }
    }

    // Sort by similarity and return top results
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(limit).map((e) => e.key).toList();
  }

  /// Generate simple embedding (hash-based for demo)
  List<double> _generateEmbedding(String text) {
    // Simple hash-based "embedding" for demonstration
    // In production, use actual embedding models
    final hash = text.hashCode;
    final random = Random(hash);
    return List.generate(128, (_) => random.nextDouble() * 2 - 1);
  }

  /// Cosine similarity between embeddings
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;
    
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  // ============ LONG-TERM MEMORY ============

  final Map<String, List<MemoryEntry>> _longTermMemory = {};

  /// Archive important memories to long-term storage
  void archiveToLongTerm(String sessionId, MemoryEntry entry) {
    _longTermMemory[sessionId] ??= [];
    _longTermMemory[sessionId]!.add(entry);
  }

  /// Retrieve from long-term memory
  List<MemoryEntry> getLongTermMemory(String sessionId, {int limit = 20}) {
    final memories = _longTermMemory[sessionId];
    if (memories == null) return [];
    
    // Return most recent
    final start = memories.length > limit ? memories.length - limit : 0;
    return memories.sublist(start);
  }

  // ============ CLEANUP ============

  /// Clear session memory
  void clearSession(String sessionId) {
    _sessionMemory.remove(sessionId);
    _semanticMemory.remove(sessionId);
    _tokenUsage.remove(sessionId);
  }

  /// Get memory stats
  MemoryStats getStats(String sessionId) {
    return MemoryStats(
      sessionTokenCount: _tokenUsage[sessionId] ?? 0,
      maxTokens: maxSessionTokens,
      sessionMemoryCount: _sessionMemory[sessionId]?.length ?? 0,
      semanticMemoryCount: _semanticMemory[sessionId]?.length ?? 0,
      longTermMemoryCount: _longTermMemory[sessionId]?.length ?? 0,
    );
  }
}

// ============ DATA CLASSES ============

class MemoryEntry {
  final String content;
  final int tokens;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  MemoryEntry({
    required this.content,
    required this.tokens,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();
}

class SemanticMemory {
  final String content;
  final List<double> embedding;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  SemanticMemory({
    required this.content,
    required this.embedding,
    required this.timestamp,
    this.metadata,
  });
}

class MemoryStats {
  final int sessionTokenCount;
  final int maxTokens;
  final int sessionMemoryCount;
  final int semanticMemoryCount;
  final int longTermMemoryCount;

  MemoryStats({
    required this.sessionTokenCount,
    required this.maxTokens,
    required this.sessionMemoryCount,
    required this.semanticMemoryCount,
    required this.longTermMemoryCount,
  });

  double get usagePercentage => sessionTokenCount / maxTokens;
  bool get needsPruning => usagePercentage > 0.8;
}
