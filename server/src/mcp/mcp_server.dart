/// NexusAgent MCP Server
/// Model Context Protocol - Tool provider interface
/// Compatible with Claude MCP specification

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MCPConfig {
  final String serverName;
  final String serverVersion;
  final String? authToken;

  MCPConfig({
    required this.serverName,
    required this.serverVersion,
    this.authToken,
  });
}

class MCPTool {
  final String name;
  final String description;
  final Map<String, MCPParameter> inputSchema;

  MCPTool({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'inputSchema': {
      'type': 'object',
      'properties': inputSchema.map((k, v) => MapEntry(k, v.toJson())),
    },
  };
}

class MCPParameter {
  final String type;
  final String? description;
  final bool required;

  MCPParameter({
    required this.type,
    this.description,
    this.required = false,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    if (description != null) 'description': description,
  };
}

class MCPResource {
  final String uri;
  final String name;
  final String? description;
  final String mimeType;

  MCPResource({
    required this.uri,
    required this.name,
    this.description,
    this.mimeType = 'text/plain',
  });

  Map<String, dynamic> toJson() => {
    'uri': uri,
    'name': name,
    if (description != null) 'description': description,
    'mimeType': mimeType,
  };
}

class MCPPrompt {
  final String name;
  final String description;
  final List<MCPromptArgument> arguments;

  MCPPrompt({
    required this.name,
    required this.description,
    this.arguments = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'arguments': arguments.map((a) => a.toJson()).toList(),
  };
}

class MCPromptArgument {
  final String name;
  final String? description;
  final bool required;

  MCPromptArgument({
    required this.name,
    this.description,
    this.required = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    'required': required,
  };
}

class MCPRequest {
  final String jsonrpc = '2.0';
  final String method;
  final dynamic params;
  final String? id;

  MCPRequest({
    required this.method,
    this.params,
    this.id,
  });

  Map<String, dynamic> toJson() => {
    'jsonrpc': jsonrpc,
    'method': method,
    if (params != null) 'params': params,
    if (id != null) 'id': id,
  };
}

class MCPResponse {
  final String jsonrpc = '2.0';
  final dynamic result;
  final MCPError? error;
  final String? id;

  MCPResponse({
    this.result,
    this.error,
    this.id,
  });

  Map<String, dynamic> toJson() => {
    'jsonrpc': jsonrpc,
    if (result != null) 'result': result,
    if (error != null) 'error': error!.toJson(),
    if (id != null) 'id': id,
  };
}

class MCPError {
  final int code;
  final String message;
  final dynamic data;

  MCPError({
    required this.code,
    required this.message,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    if (data != null) 'data': data,
  };

  static const parseError = MCPError(code: -32700, message: 'Parse error');
  static const invalidRequest = MCPError(code: -32600, message: 'Invalid Request');
  static const methodNotFound = MCPError(code: -32601, message: 'Method not found');
  static const invalidParams = MCPError(code: -32602, message: 'Invalid params');
  static const internalError = MCPError(code: -32603, message: 'Internal error');
}

class MCPServer {
  final MCPConfig config;
  
  final List<MCPTool> _tools = [];
  final List<MCPResource> _resources = [];
  final List<MCPPrompt> _prompts = [];

  Function(String toolName, Map<String, dynamic> params)? onToolCall;

  MCPServer(this.config);

  /// Register a tool
  void registerTool(MCPTool tool) {
    _tools.add(tool);
  }

  /// Register a resource
  void registerResource(MCPResource resource) {
    _resources.add(resource);
  }

  /// Register a prompt
  void registerPrompt(MCPPrompt prompt) {
    _prompts.add(prompt);
  }

  /// Handle incoming request
  Future<MCPResponse> handleRequest(MCPRequest request) async {
    try {
      switch (request.method) {
        case 'initialize':
          return _handleInitialize(request);
        case 'tools/list':
          return _handleToolsList(request);
        case 'tools/call':
          return await _handleToolsCall(request);
        case 'resources/list':
          return _handleResourcesList(request);
        case 'resources/read':
          return _handleResourcesRead(request);
        case 'prompts/list':
          return _handlePromptsList(request);
        case 'prompts/get':
          return _handlePromptsGet(request);
        default:
          return MCPResponse(
            error: MCPError.methodNotFound,
            id: request.id,
          );
      }
    } catch (e) {
      return MCPResponse(
        error: MCPError(code: -32603, message: e.toString()),
        id: request.id,
      );
    }
  }

  /// Handle JSON-RPC request
  Future<MCPResponse> handleJson(String json) async {
    try {
      final data = jsonDecode(json);
      
      // Batch requests
      if (data is List) {
        final responses = <MCPResponse>[];
        for (final item in data) {
          final request = MCPRequest(
            method: item['method'] as String,
            params: item['params'],
            id: item['id']?.toString(),
          );
          responses.add(await handleRequest(request));
        }
        // Return first for simplicity
        return responses.first;
      }

      // Single request
      final request = MCPRequest(
        method: data['method'] as String,
        params: data['params'],
        id: data['id']?.toString(),
      );
      return handleRequest(request);
    } catch (e) {
      return MCPResponse(error: MCPError.parseError);
    }
  }

  MCPResponse _handleInitialize(MCPRequest request) {
    return MCPResponse(
      result: {
        'protocolVersion': '2024-11-05',
        'capabilities': {
          'tools': {},
          'resources': {},
          'prompts': {},
        },
        'serverInfo': {
          'name': config.serverName,
          'version': config.serverVersion,
        },
      },
      id: request.id,
    );
  }

  MCPResponse _handleToolsList(MCPRequest request) {
    return MCPResponse(
      result: {
        'tools': _tools.map((t) => t.toJson()).toList(),
      },
      id: request.id,
    );
  }

  Future<MCPResponse> _handleToolsCall(MCPRequest request) async {
    final params = request.params as Map<String, dynamic>?;
    final toolName = params?['name'] as String?;
    final toolArgs = (params?['arguments'] as Map<String, dynamic>?) ?? {};

    if (toolName == null) {
      return MCPResponse(error: MCPError.invalidParams, id: request.id);
    }

    // Call registered handler
    if (onToolCall != null) {
      final result = await onToolCall!(toolName, toolArgs);
      return MCPResponse(
        result: {
          'content': [
            {
              'type': 'text',
              'text': result.toString(),
            }
          ],
        },
        id: request.id,
      );
    }

    return MCPResponse(
      error: MCPError(code: -32601, message: 'Tool handler not found'),
      id: request.id,
    );
  }

  MCPResponse _handleResourcesList(MCPRequest request) {
    return MCPResponse(
      result: {
        'resources': _resources.map((r) => r.toJson()).toList(),
      },
      id: request.id,
    );
  }

  MCPResponse _handleResourcesRead(MCPRequest request) {
    final params = request.params as Map<String, dynamic>?;
    final uri = params?['uri'] as String?;

    final resource = _resources.where((r) => r.uri == uri).firstOrNull;
    if (resource == null) {
      return MCPResponse(
        error: MCPError(code: -32601, message: 'Resource not found'),
        id: request.id,
      );
    }

    return MCPResponse(
      result: {
        'contents': [
          {
            'uri': resource.uri,
            'mimeType': resource.mimeType,
            'text': 'Resource content for $uri',
          }
        ],
      },
      id: request.id,
    );
  }

  MCPResponse _handlePromptsList(MCPRequest request) {
    return MCPResponse(
      result: {
        'prompts': _prompts.map((p) => p.toJson()).toList(),
      },
      id: request.id,
    );
  }

  MCPResponse _handlePromptsGet(MCPRequest request) {
    final params = request.params as Map<String, dynamic>?;
    final name = params?['name'] as String?;

    final prompt = _prompts.where((p) => p.name == name).firstOrNull;
    if (prompt == null) {
      return MCPResponse(
        error: MCPError(code: -32601, message: 'Prompt not found'),
        id: request.id,
      );
    }

    return MCPResponse(
      result: {
        'messages': [
          {
            'role': 'user',
            'content': {
              'type': 'text',
              'text': 'Prompt: ${prompt.name}',
            },
          }
        ],
      },
      id: request.id,
    );
  }
}

/// MCP Client for connecting to external MCP servers
class MCPClient {
  final String serverUrl;
  final String? authToken;

  MCPClient({
    required this.serverUrl,
    this.authToken,
  });

  Future<dynamic> callTool(String name, Map<String, dynamic> args) async {
    final response = await http.post(
      Uri.parse(serverUrl),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'tools/call',
        'params': {
          'name': name,
          'arguments': args,
        },
        'id': '1',
      }),
    );

    final data = jsonDecode(response.body);
    return data['result'];
  }

  Future<List<MCPTool>> listTools() async {
    final response = await http.post(
      Uri.parse(serverUrl),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'tools/list',
        'id': '1',
      }),
    );

    final data = jsonDecode(response.body);
    final tools = data['result']['tools'] as List;
    return tools.map((t) => MCPTool(
      name: t['name'],
      description: t['description'],
      inputSchema: {},
    )).toList();
  }
}
