/// NexusAgent Input Validator - Security hardening
/// Addresses: T-EXEC-001, T-EXEC-002, T-EXEC-003 (prompt injection)

import 'dart:convert';

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final String? sanitizedInput;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.sanitizedInput,
  });
}

class InputValidator {
  // Direct prompt injection patterns
  static final List<RegExp> _directInjectionPatterns = [
    RegExp(r'(?i)ignore\s+(all\s+)?(previous|above|prior)\s+(instructions?|prompts?|rules?)'),
    RegExp(r'(?i)forget\s+(everything|all|what)\s+(you|i)\s+(know|said|learned)'),
    RegExp(r'(?i)you\s+are\s+(now|no longer|a|just|merely)\s+'),
    RegExp(r'(?i)system\s*:\s*', multiLine: true),
    RegExp(r'(?i)assistant\s*:\s*', multiLine: true),
    RegExp(r'(?i)\[INST\]|\[\/INST\]|\[SYS\]|\[\/SYS\]'),
    RegExp(r'(?i)```system|```assistant'),
    RegExp(r'(?i)new\s+instruction(s)?:|override\s+instruction(s)?:'),
    RegExp(r'(?i)disregard\s+(safety|security|guideline|policy|protocol)'),
    RegExp(r'(?i)(jailbreak|prompt\s+inject|DAN|developer\s+mode)'),
    RegExp(r'(?i)<\|(?:system|user|assistant|ipython)\|>'),
    RegExp(r'(?i)<(?:system|user|assistant|sep|sop|bos|eop)\s*>'),
    RegExp(r'(?i)#{1,6}\s*system', multiLine: true),
    RegExp(r'(?i)///.*system', multiLine: true),
  ];

  // Indirect injection patterns
  static final List<RegExp> _indirectInjectionPatterns = [
    RegExp(r'<!\[CDATA\['),
    RegExp(r'<\?xml\s+encoding='),
    RegExp(r'(?i)(onclick|onload|onerror|onfocus)\s*='),
    RegExp(r'(?i)javascript\s*:'),
    RegExp(r'(?i)<!--.*?(instruction|prompt|rule|command).*?-->', multiLine: true),
    RegExp(r'(?i)<meta\s+http-equiv="refresh"'),
    RegExp(r'data:text/html'),
    RegExp(r'(?i)import\s+os|import\s+sys|import\s+subprocess'),
  ];

  // Encoding evasion patterns
  static final List<RegExp> _encodingPatterns = [
    RegExp(r'\\x[0-9a-fA-F]{2}'),
    RegExp(r'\\u[0-9a-fA-F]{4}'),
    RegExp(r'&#x[0-9a-fA-F]{2,4};'),
    RegExp(r'&#\d+;'),
    RegExp(r'%[0-9a-fA-F]{2}'),
  ];

  // Suspicious patterns that warrant warning
  static final List<RegExp> _suspiciousPatterns = [
    RegExp(r'(?i)what\s+(can|do)\s+you\s+(know|remember|have)'),
    RegExp(r'(?i)list\s+(all\s+)?(files|commands|tools)'),
    RegExp(r'(?i)show\s+(me\s+)?(your|special|current)\s+(instructions?|capabilities?|mode)'),
    RegExp(r'(?i)role\s*:\s*'),
    RegExp(r'(?i)persona\s*:\s*'),
  ];

  // Zero-width characters
  static final RegExp _zeroWidthChars = RegExp(r'[\u200B\u200C\u200D\uFEFF]');

  /// Validate input
  ValidationResult validate(String input) {
    if (input.isEmpty) {
      return ValidationResult(isValid: true, sanitizedInput: input);
    }

    List<String> errors = [];
    List<String> warnings = [];

    // Check for direct injection
    for (final pattern in _directInjectionPatterns) {
      if (pattern.hasMatch(input)) {
        errors.add('Direct prompt injection detected: ${pattern.pattern}');
      }
    }

    // Check for indirect injection
    for (final pattern in _indirectInjectionPatterns) {
      if (pattern.hasMatch(input)) {
        errors.add('Indirect injection detected: ${pattern.pattern}');
      }
    }

    // Check for encoding evasion
    for (final pattern in _encodingPatterns) {
      if (pattern.hasMatch(input)) {
        warnings.add('Encoded content detected: ${pattern.pattern}');
      }
    }

    // Check for suspicious patterns
    for (final pattern in _suspiciousPatterns) {
      if (pattern.hasMatch(input)) {
        warnings.add('Suspicious pattern: ${pattern.pattern}');
      }
    }

    // Check for zero-width characters
    if (_zeroWidthChars.hasMatch(input)) {
      warnings.add('Zero-width characters detected');
    }

    // Sanitize input
    String sanitized = _sanitize(input);

    if (errors.isEmpty) {
      return ValidationResult(
        isValid: true,
        warnings: warnings,
        sanitizedInput: sanitized,
      );
    }

    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
      sanitizedInput: sanitized,
    );
  }

  /// Sanitize input
  String _sanitize(String input) {
    String result = input;

    // Remove zero-width characters
    result = result.replaceAll(_zeroWidthChars, '');

    // Normalize whitespace
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Escape potential control characters
    result = result.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    return result;
  }

  /// Validate JSON
  ValidationResult validateJson(String input) {
    try {
      jsonDecode(input);
      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: ['Invalid JSON: ${e.toString()}'],
      );
    }
  }

  /// Validate URL
  ValidationResult validateUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Check for internal IPs
      if (_isInternalIp(uri.host)) {
        return ValidationResult(
          isValid: false,
          errors: ['Internal URLs not allowed'],
        );
      }

      // Only allow http/https
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return ValidationResult(
          isValid: false,
          errors: ['Only HTTP/HTTPS URLs allowed'],
        );
      }

      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: ['Invalid URL: ${e.toString()}'],
      );
    }
  }

  bool _isInternalIp(String host) {
    final patterns = [
      'localhost',
      RegExp(r'^127\.'),
      RegExp(r'^10\.'),
      RegExp(r'^172\.(1[6-9]|2\d|3[01])\.'),
      RegExp(r'^192\.168\.'),
      RegExp(r'^::1$'),
      RegExp(r'^fe80:'),
      RegExp(r'^169\.254\.'),
    ];

    for (final pattern in patterns) {
      if (pattern is RegExp && pattern.hasMatch(host)) return true;
      if (pattern is String && host.startsWith(pattern)) return true;
    }

    return false;
  }
}
