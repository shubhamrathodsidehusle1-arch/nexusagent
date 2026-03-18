class AppConstants {
  static const String appName = 'NexusAgent';
  static const String tagline = 'Your AI Command Center';
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  static const String apiBaseUrl = 'https://api.nexusagent.ai';
}

class ChannelTypes {
  static const String telegram = 'telegram';
  static const String discord = 'discord';
  static const String slack = 'slack';
  static const String whatsapp = 'whatsapp';
  static const String signal = 'signal';
  
  static const List<Map<String, String>> channels = [
    {'id': telegram, 'name': 'Telegram', 'icon': '✈️'},
    {'id': discord, 'name': 'Discord', 'icon': '🎮'},
    {'id': slack, 'name': 'Slack', 'icon': '💬'},
    {'id': whatsapp, 'name': 'WhatsApp', 'icon': '📱'},
    {'id': signal, 'name': 'Signal', 'icon': '🔒'},
  ];
}

class AgentStatuses {
  static const String offline = 'offline';
  static const String online = 'online';
  static const String running = 'running';
  static const String error = 'error';
  
  static const Map<String, String> statusLabels = {
    offline: 'Offline',
    online: 'Online',
    running: 'Running',
    error: 'Error',
  };
}

class AgentTemplates {
  static const List<Map<String, dynamic>> templates = [
    {
      'id': 'assistant',
      'name': 'AI Assistant',
      'description': 'General purpose AI assistant',
      'icon': '🤖',
    },
    {
      'id': 'coder',
      'name': 'Code Expert',
      'description': 'Helps with programming tasks',
      'icon': '💻',
    },
    {
      'id': 'writer',
      'name': 'Content Writer',
      'description': 'Creates articles and content',
      'icon': '✍️',
    },
    {
      'id': 'analyst',
      'name': 'Data Analyst',
      'description': 'Analyzes data and provides insights',
      'icon': '📊',
    },
    {
      'id': 'researcher',
      'name': 'Research Assistant',
      'description': 'Helps with research and information',
      'icon': '🔬',
    },
    {
      'id': 'custom',
      'name': 'Custom Agent',
      'description': 'Build from scratch',
      'icon': '✨',
    },
  ];
}

class ToolCategories {
  static const List<Map<String, String>> categories = [
    {'id': 'search', 'name': 'Search', 'icon': '🔍'},
    {'id': 'browse', 'name': 'Browse', 'icon': '🌐'},
    {'id': 'code', 'name': 'Code', 'icon': '💻'},
    {'id': 'memory', 'name': 'Memory', 'icon': '🧠'},
    {'id': 'message', 'name': 'Message', 'icon': '💬'},
    {'id': 'file', 'name': 'File', 'icon': '📁'},
  ];
}
