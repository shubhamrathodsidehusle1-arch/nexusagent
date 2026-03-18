import 'package:flutter/material.dart';

class SecurityCenterScreen extends StatefulWidget {
  const SecurityCenterScreen({super.key});

  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityScreenState extends State<SecurityCenterScreen> {
  // Security toggles
  bool _promptInjectionBlock = true;
  bool _commandSanitization = true;
  bool _urlAllowlist = true;
  bool _rateLimiting = true;
  bool _sandboxByDefault = true;
  bool _tokenEncryption = true;

  // Security stats
  int _blockedInjections = 47;
  int _sanitizedCommands = 23;
  int _blockedUrls = 12;
  int _rateLimitHits = 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Center'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security Score
            _buildSecurityScore(),
            const SizedBox(height: 24),

            // Threat Stats
            _buildThreatStats(),
            const SizedBox(height: 24),

            // Protection Settings
            _buildSectionTitle('Protection Settings'),
            const SizedBox(height: 12),
            
            _buildToggle(
              'Prompt Injection Blocking',
              'Actively block direct and indirect prompt injection',
              Icons.shield_outlined,
              _promptInjectionBlock,
              (v) => setState(() => _promptInjectionBlock = v),
            ),
            
            _buildToggle(
              'Command Sanitization',
              'Block dangerous shell commands before execution',
              Icons.terminal,
              _commandSanitization,
              (v) => setState(() => _commandSanitization = v),
            ),
            
            _buildToggle(
              'URL Allowlisting',
              'Only allow requests to approved domains',
              Icons.link_off,
              _urlAllowlist,
              (v) => setState(() => _urlAllowlist = v),
            ),
            
            _buildToggle(
              'Rate Limiting',
              'Prevent DoS via request throttling',
              Icons.speed,
              _rateLimiting,
              (v) => setState(() => _rateLimiting = v),
            ),
            
            _buildToggle(
              'Sandbox by Default',
              'Run all skills and code in isolated sandboxes',
              Icons.hardware,
              _sandboxByDefault,
              (v) => setState(() => _sandboxByDefault = v),
            ),
            
            _buildToggle(
              'Token Encryption',
              'Encrypt API tokens and credentials at rest',
              Icons.lock_outline,
              _tokenEncryption,
              (v) => setState(() => _tokenEncryption = v),
            ),

            const SizedBox(height: 24),

            // Advanced Settings
            _buildSectionTitle('Advanced'),
            const SizedBox(height: 12),
            
            _buildActionButton(
              'Configure URL Allowlist',
              'Manage allowed and blocked domains',
              Icons.dns_outlined,
              () {},
            ),
            
            _buildActionButton(
              'View Audit Logs',
              'Full security event history',
              Icons.history,
              () {},
            ),
            
            _buildActionButton(
              '2FA Settings',
              'Two-factor authentication',
              Icons.verified_user_outlined,
              () {},
            ),

            const SizedBox(height: 24),

            // Comparison with OpenClaw
            _buildComparison(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityScore() {
    int score = (_promptInjectionBlock ? 15 : 0) +
        (_commandSanitization ? 15 : 0) +
        (_urlAllowlist ? 15 : 0) +
        (_rateLimiting ? 15 : 0) +
        (_sandboxByDefault ? 20 : 0) +
        (_tokenEncryption ? 20 : 0);

    Color scoreColor;
    String grade;
    if (score >= 90) {
      scoreColor = Colors.green;
      grade = 'A';
    } else if (score >= 70) {
      scoreColor = Colors.lightGreen;
      grade = 'B';
    } else if (score >= 50) {
      scoreColor = Colors.orange;
      grade = 'C';
    } else {
      scoreColor = Colors.red;
      grade = 'D';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withValues(alpha: 0.2), scoreColor.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: scoreColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                grade,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Security Score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$score/100 - All major OpenClaw vulnerabilities fixed',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatStats() {
    return Row(
      children: [
        _buildStatCard('Injections\nBlocked', _blockedInjections.toString(), Colors.red),
        const SizedBox(width: 8),
        _buildStatCard('Commands\nSanitized', _sanitizedCommands.toString(), Colors.orange),
        const SizedBox(width: 8),
        _buildStatCard('URLs\nBlocked', _blockedUrls.toString(), Colors.purple),
        const SizedBox(width: 8),
        _buildStatCard('Rate\nLimits', _rateLimitHits.toString(), Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        secondary: Icon(icon, color: value ? Colors.green : Colors.grey),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
      ),
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildComparison() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'How We Fix OpenClaw Issues',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFixItem('T-EXEC-001', 'Prompt Injection', 'BLOCKS instead of just detecting'),
          _buildFixItem('T-EXEC-004', 'Command Sanitization', 'Validates and blocks dangerous commands'),
          _buildFixItem('T-ACCESS-003', 'Token Storage', 'Encrypts tokens at rest'),
          _buildFixItem('T-EXFIL-001', 'URL Allowlisting', 'Whitelist-based URL validation'),
          _buildFixItem('T-IMPACT-001', 'Sandbox', 'Default to isolate sandbox'),
          _buildFixItem('T-IMPACT-002', 'Rate Limiting', 'Per-sender rate limits'),
        ],
      ),
    );
  }

  Widget _buildFixItem(String id, String title, String fix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              id,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            child: Text(
              '$title: $fix',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
