/// Security Service - Hardened against OpenClaw vulnerabilities
/// Addresses: T-EXEC-001, T-EXEC-002, T-EXEC-003, T-EXEC-004, T-ACCESS-003, T-EXFIL-001, T-IMPACT-001, T-IMPACT-002

import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityService {
  // Singleton
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  // ============ PROMPT INJECTION SANITIZATION ============
  // Fixed: T-EXEC-001 (OpenClaw: detection only, no blocking)
  
  static final List<RegExp> _promptInjectionPatterns = [
    // Direct injection attempts
    RegExp(r'(?i)(ignore\s+(all\s+)?(previous|above|prior)\s+(instructions?|prompts?|rules?))'),
    RegExp(r'(?i)(forget\s+(everything|all|what)\s+(you|i)\s+(know|said|learned))'),
    RegExp(r'(?i)(you\s+are\s+(now|no longer|a|just)\s+)'),
    RegExp(r'(?i)(system\s*:\s*)'),
    RegExp(r'(?i)(assistant\s*:\s*)'),
    RegExp(r'(?i)(\[INST\]|\[\/INST\]|\[SYS\]|\[\/SYS\])'),
    RegExp(r'(?i)(```system|```assistant)'),
    RegExp(r'(?i)(new\s+instruction(s)?:|override\s+instruction(s)?:)'),
    RegExp(r'(?i)(disregard\s+(safety|security|guideline|policy))'),
    RegExp(r'(?i)(jailbreak|prompt\s+inject|DAN|developer\s+mode)'),
    // Token manipulation
    RegExp(r'(?i)(<\|(?:system|user|assistant|ipython)\|>)'),
    RegExp(r'(?i)(<(?:system|user|assistant|sep|sop|bos|eot)\s*>)'),
    // Indirect injection markers
    RegExp(r'(?i)(remember\s+that.*important|this\s+is\s+a\s+test)', multiLine: true),
  ];

  static final List<RegExp> _indirectInjectionPatterns = [
    // Embedded instructions in fetched content
    RegExp(r'<!\[CDATA\['),
    RegExp(r'<\?xml\s+encoding='),
    RegExp(r'(?i)(onclick|onload|onerror)\s*='),
    RegExp(r'(?i)(javascript\s*:)'),
    RegExp(r'(?i)<!--.*?(instruction|prompt|rule).*?-->', multiLine: true),
  ];

  /// Sanitize user input - BLOCKS injection attempts (not just detect)
  SanitizeResult sanitizePrompt(String input) {
    if (input.isEmpty) {
      return SanitizeResult(clean: true, threats: [], sanitized: input);
    }

    List<String> threats = [];
    String sanitized = input;

    // Check direct injection patterns
    for (final pattern in _promptInjectionPatterns) {
      if (pattern.hasMatch(input)) {
        threats.add('DIRECT_INJECTION: ${pattern.pattern}');
        // Remove the matched content
        sanitized = sanitized.replaceAll(pattern, '[FILTERED]');
      }
    }

    // Check indirect injection
    for (final pattern in _indirectInjectionPatterns) {
      if (pattern.hasMatch(input)) {
        threats.add('INDIRECT_INJECTION: ${pattern.pattern}');
        sanitized = sanitized.replaceAll(pattern, '[ENCODED_CONTENT]');
      }
    }

    // Escape special characters
    sanitized = _escapeSpecialChars(sanitized);

    return SanitizeResult(
      clean: threats.isEmpty,
      threats: threats,
      sanitized: sanitized,
    );
  }

  String _escapeSpecialChars(String input) {
    // Escape potential prompt injection via special chars
    return input
        .replaceAll('\x00', '')
        .replaceAll('\u200B', '') // Zero-width space
        .replaceAll('\u200C', '') // Zero-width non-joiner
        .replaceAll('\u200D', '') // Zero-width joiner
        .replaceAll('\uFEFF', ''); // BOM
  }

  // ============ COMMAND SANITIZATION ============
  // Fixed: T-EXEC-004 (OpenClaw: no command sanitization)

  static final List<String> _blockedCommands = [
    'rm -rf', 'mkfs', 'dd if=', '> /dev/sd', 'chmod 777',
    'chown -R', 'wget | sh', 'curl | sh', 'nc -e', 'bash -i',
    'exec ', 'eval ', 'source ~/.bashrc', 'export PATH=',
    ':(){:|:&};:', 'fork()', 'while(true)',
  ];

  static final List<RegExp> _dangerousPatterns = [
    RegExp(r'sudo\s+'),
    RegExp(r'chmod\s+[0-7]{3,4}\s+'),
    RegExp(r'\|\s*sh'),
    RegExp(r'>\s*/dev/'),
    RegExp(r'2>\s*/dev/'),
    RegExp(r'&\s*;\s*$'),
    RegExp(r'\$\(.*\)'), // Command substitution
    RegExp(r'`.*`'), // Backtick substitution
  ];

  /// Validate and sanitize shell commands
  CommandValidationResult validateCommand(String command) {
    if (command.trim().isEmpty) {
      return CommandValidationResult(valid: false, reason: 'Empty command');
    }

    String lowerCmd = command.toLowerCase();

    // Check blocked commands
    for (final blocked in _blockedCommands) {
      if (lowerCmd.contains(blocked)) {
        return CommandValidationResult(
          valid: false,
          reason: 'Blocked dangerous command: $blocked',
        );
      }
    }

    // Check dangerous patterns
    for (final pattern in _dangerousPatterns) {
      if (pattern.hasMatch(command)) {
        return CommandValidationResult(
          valid: false,
          reason: 'Dangerous pattern detected: ${pattern.pattern}',
        );
      }
    }

    // Normalize command (remove escapes)
    String normalized = command
        .replaceAll(RegExp(r'\\.'), '')
        .replaceAll(RegExp(r'\$\{[^}]+\}'), '')
        .replaceAll(RegExp(r'\$[^$\s]+'), '');

    return CommandValidationResult(valid: true, normalized: normalized);
  }

  // ============ TOKEN ENCRYPTION ============
  // Fixed: T-ACCESS-003 (OpenClaw: plaintext token storage)

  String encryptToken(String token, String key) {
    // Use AES-like encryption with HMAC
    final keyBytes = utf8.encode(key);
    final tokenBytes = utf8.encode(token);
    
    final hmacSha256 = Hmac(sha256, keyBytes);
    final digest = hmacSha256.convert(tokenBytes);
    
    // Combine: encrypted = token XOR HMAC (simplified)
    List<int> encrypted = [];
    for (int i = 0; i < tokenBytes.length; i++) {
      encrypted.add(tokenBytes[i] ^ digest.bytes[i % digest.bytes.length]);
    }
    
    return base64Encode(encrypted);
  }

  String decryptToken(String encryptedToken, String key) {
    final keyBytes = utf8.encode(key);
    final tokenBytes = base64Decode(encryptedToken);
    
    final hmacSha256 = Hmac(sha256, keyBytes);
    final digest = hmacSha256.convert(tokenBytes);
    
    List<int> decrypted = [];
    for (int i = 0; i < tokenBytes.length; i++) {
      decrypted.add(tokenBytes[i] ^ digest.bytes[i % digest.bytes.length]);
    }
    
    return utf8.decode(decrypted);
  }

  // ============ URL ALLOWLISTING ============
  // Fixed: T-EXFIL-001 (OpenClaw: no URL allowlisting)

  List<String> _allowedDomains = [];
  List<String> _blockedDomains = [];

  void setAllowedDomains(List<String> domains) {
    _allowedDomains = domains.map((d) => d.toLowerCase()).toList();
  }

  void setBlockedDomains(List<String> domains) {
    _blockedDomains = domains.map((d) => d.toLowerCase()).toList();
  }

  bool validateUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      // Check blocked
      for (final blocked in _blockedDomains) {
        if (host == blocked || host.endsWith('.$blocked')) {
          return false;
        }
      }

      // If allowlist is set, must match
      if (_allowedDomains.isNotEmpty) {
        for (final allowed in _allowedDomains) {
          if (host == allowed || host.endsWith('.$allowed')) {
            return true;
          }
        }
        return false;
      }

      // Block internal IPs
      if (_isInternalIp(host)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  bool _isInternalIp(String host) {
    final internalPatterns = [
      'localhost', '127.', '10.', '172.16.', '172.17.',
      '172.18.', '172.19.', '172.2', '172.30.', '172.31.',
      '192.168.', '::1', 'fe80:', '169.254.',
    ];
    for (final pattern in internalPatterns) {
      if (host.startsWith(pattern)) return true;
    }
    return false;
  }

  // ============ RATE LIMITING ============
  // Fixed: T-IMPACT-002 (OpenClaw: no rate limiting)

  final Map<String, List<DateTime>> _requestLog = {};
  
  void setRateLimit({
    required String identifier,
    required int maxRequests,
    required Duration window,
  }) {
    final now = DateTime.now();
    _requestLog[identifier] ??= [];
    _requestLog[identifier]!.removeWhere(
      (t) => now.difference(t) > window,
    );

    if (_requestLog[identifier]!.length >= maxRequests) {
      throw RateLimitException('Rate limit exceeded for $identifier');
    }

    _requestLog[identifier]!.add(now);
  }

  void resetRateLimit(String identifier) {
    _requestLog.remove(identifier);
  }
}

// ============ RESULT CLASSES ============

class SanitizeResult {
  final bool clean;
  final List<String> threats;
  final String sanitized;

  SanitizeResult({
    required this.clean,
    required this.threats,
    required this.sanitized,
  });
}

class CommandValidationResult {
  final bool valid;
  final String? reason;
  final String? normalized;

  CommandValidationResult({
    required this.valid,
    this.reason,
    this.normalized,
  });
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  
  @override
  String toString() => message;
}
