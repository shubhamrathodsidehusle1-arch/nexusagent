import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/agent_model.dart';

class AgentRunScreen extends StatefulWidget {
  final Agent agent;
  
  const AgentRunScreen({super.key, required this.agent});

  @override
  State<AgentRunScreen> createState() => _AgentRunScreenState();
}

class _AgentRunScreenState extends State<AgentRunScreen> {
  final _inputController = TextEditingController();
  bool _isRunning = false;
  List<RunStep> _steps = [];
  String? _output;
  
  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
  
  Future<void> _runAgent() async {
    if (_inputController.text.isEmpty) return;
    
    setState(() {
      _isRunning = true;
      _steps = [];
      _output = null;
    });
    
    // Simulate agent execution steps
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _steps.add(RunStep(order: 1, action: 'Parsing input', success: true, duration: const Duration(milliseconds: 120))));
    
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _steps.add(RunStep(order: 2, action: 'Loading context from memory', success: true, duration: const Duration(milliseconds: 350))));
    
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _steps.add(RunStep(order: 3, action: 'Analyzing with GPT-4', success: true, duration: const Duration(milliseconds: 850))));
    
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _steps.add(RunStep(order: 4, action: 'Generating response', success: true, duration: const Duration(milliseconds: 420))));
    
    setState(() {
      _isRunning = false;
      _output = '''Here's my analysis based on the context:

1. **Key Observations**
   - The project is progressing well
   - Team alignment is strong
   - Market conditions are favorable

2. **Recommendations**
   - Continue current trajectory
   - Focus on user acquisition
   - Monitor competitor activity

3. **Next Steps**
   - Schedule planning session
   - Review metrics weekly
   - Prepare for scaling phase

The agent has successfully processed your request and provided actionable insights based on the available data.''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.agent.name),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Agent Info
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(widget.agent.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.agent.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(widget.agent.description, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.online.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.online, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Online', style: TextStyle(fontSize: 12, color: AppColors.online)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _inputController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter your prompt...',
                    suffixIcon: IconButton(
                      icon: _isRunning 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                      onPressed: _isRunning ? null : _runAgent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildQuickChip('Summarize'),
                    _buildQuickChip('Analyze'),
                    _buildQuickChip('Code'),
                    _buildQuickChip('Write'),
                  ],
                ),
              ],
            ),
          ),
          
          // Execution Steps
          if (_steps.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Execution', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${_steps.length} steps', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return _buildStepItem(step);
                },
              ),
            ),
          ],
          
          // Output
          if (_output != null) ...[
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('Response', style: TextStyle(fontWeight: FontWeight.w600)),
                        Spacer(),
                        Icon(Icons.copy, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(_output!, style: const TextStyle(height: 1.6)),
                  ],
                ),
              ),
            ),
          ] else
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🤖', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 16),
                    Text('Ready to run', style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildQuickChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: () => _inputController.text = '$label ',
      ),
    );
  }
  
  Widget _buildStepItem(RunStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: step.success ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(step.success ? Icons.check : Icons.close, size: 14, color: step.success ? AppColors.success : AppColors.error),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(step.action, style: const TextStyle(fontSize: 13))),
          Text('${step.duration?.inMilliseconds ?? 0}ms', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
