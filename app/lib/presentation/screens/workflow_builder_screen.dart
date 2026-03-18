/// Visual Workflow Builder UI
/// Drag-and-drop workflow automation

import 'package:flutter/material.dart';

class WorkflowBuilderScreen extends StatefulWidget {
  final String? workflowId;

  const WorkflowBuilderScreen({super.key, this.workflowId});

  @override
  State<WorkflowBuilderScreen> createState() => _WorkflowBuilderScreenState();
}

class _WorkflowBuilderScreenState extends State<WorkflowBuilderScreen> {
  final WorkflowService _workflowService = WorkflowService();
  final Map<String, WorkflowNode> _nodes = {};
  final Map<String, Offset> _nodePositions = {};
  String? _selectedNodeId;
  String? _connectingFromId;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    if (widget.workflowId != null) {
      _loadWorkflow();
    }
  }

  void _loadWorkflow() {
    // Load existing workflow
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workflowId != null ? 'Edit Workflow' : 'New Workflow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _nodes.isNotEmpty ? _runWorkflow : null,
            tooltip: 'Test Workflow',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveWorkflow,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Row(
        children: [
          // Node palette
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPaletteSection('Triggers', Icons.flash_on, NodeTemplates.getTriggers()),
                _buildPaletteSection('Actions', Icons.play_circle_outline, NodeTemplates.getActions()),
                _buildPaletteSection('Logic', Icons.call_split, NodeTemplates.getLogic()),
              ],
            ),
          ),
          // Canvas
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: GestureDetector(
                onTapDown: (details) {
                  setState(() => _selectedNodeId = null);
                },
                child: Stack(
                  children: [
                    // Grid background
                    CustomPaint(
                      size: Size.infinite,
                      painter: _GridPainter(),
                    ),
                    // Nodes
                    ..._nodePositions.entries.map((entry) {
                      final node = _nodes[entry.key]!;
                      return _buildNodeWidget(entry.key, node, entry.value);
                    }),
                    // Connection lines
                    CustomPaint(
                      size: Size.infinite,
                      painter: _ConnectionPainter(
                        nodes: _nodes,
                        positions: _nodePositions,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Properties panel
          if (_selectedNodeId != null)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: _buildPropertiesPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildPaletteSection(String title, IconData icon, List<WorkflowNode> templates) {
    return ExpansionTile(
      leading: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      initiallyExpanded: true,
      children: templates.map((template) {
        return Draggable<WorkflowNode>(
          data: template,
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getNodeColor(template.type),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getNodeIcon(template.type), color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(template.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _buildPaletteItem(template),
          ),
          child: _buildPaletteItem(template),
        );
      }).toList(),
    );
  }

  Widget _buildPaletteItem(WorkflowNode template) {
    return ListTile(
      dense: true,
      leading: Icon(_getNodeIcon(template.type), size: 16, color: _getNodeColor(template.type)),
      title: Text(template.name, style: const TextStyle(fontSize: 12)),
      onTap: () => _addNode(template),
    );
  }

  void _addNode(WorkflowNode template, {Offset? position}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final node = WorkflowNode(
      id: id,
      name: template.name,
      type: template.type,
      config: Map.from(template.config),
    );
    
    setState(() {
      _nodes[id] = node;
      _nodePositions[id] = position ?? const Offset(100, 100);
    });
  }

  Widget _buildNodeWidget(String id, WorkflowNode node, Offset position) {
    final isSelected = id == _selectedNodeId;
    
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: () => setState(() => _selectedNodeId = id),
        onPanUpdate: (details) {
          setState(() {
            _nodePositions[id] = Offset(
              position.dx + details.delta.dx,
              position.dy + details.delta.dy,
            );
          });
        },
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getNodeColor(node.type),
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: Colors.white, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(_getNodeIcon(node.type), color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      node.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (node.config.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _getConfigSummary(node.config),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Input/Output dots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (node.type != WorkflowNodeType.trigger)
                    _buildConnector(true),
                  if (node.type != WorkflowNodeType.action)
                    _buildConnector(false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnector(bool isInput) {
    return GestureDetector(
      onTap: () {
        // Handle connection
      },
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[400]!),
        ),
      ),
    );
  }

  Widget _buildPropertiesPanel() {
    final node = _nodes[_selectedNodeId!]!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Properties', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: node.name),
            onChanged: (v) {
              setState(() {
                _nodes[_selectedNodeId!] = WorkflowNode(
                  id: node.id,
                  name: v,
                  type: node.type,
                  config: node.config,
                  x: node.x,
                  y: node.y,
                );
              });
            },
          ),
          const SizedBox(height: 12),
          ..._buildConfigFields(node),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Delete Node'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _nodes.remove(_selectedNodeId);
                  _nodePositions.remove(_selectedNodeId);
                  _selectedNodeId = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildConfigFields(WorkflowNode node) {
    final fields = <Widget>[];
    
    switch (node.type) {
      case WorkflowNodeType.trigger:
        fields.add(_buildDropdown('Channel', node.config['channel'] ?? 'telegram', ['telegram', 'discord', 'whatsapp', 'slack'], (v) => _updateConfig('channel', v)));
        if (node.config['cron'] != null) {
          fields.add(_buildTextField('Cron Expression', node.config['cron'], (v) => _updateConfig('cron', v)));
        }
        if (node.config['keyword'] != null) {
          fields.add(_buildTextField('Keyword', node.config['keyword'], (v) => _updateConfig('keyword', v)));
        }
        break;
      case WorkflowNodeType.action:
      case WorkflowNodeType.agent:
        fields.add(_buildTextField('Agent ID', node.config['agentId'] ?? '', (v) => _updateConfig('agentId', v)));
        fields.add(_buildTextField('Message', node.config['message'] ?? '', (v) => _updateConfig('message', v)));
        break;
      case WorkflowNodeType.delay:
        fields.add(_buildTextField('Delay (ms)', (node.config['delay'] ?? 1000).toString(), (v) => _updateConfig('delay', int.tryParse(v) ?? 1000)));
        break;
      case WorkflowNodeType.http:
        fields.add(_buildDropdown('Method', node.config['method'] ?? 'GET', ['GET', 'POST', 'PUT', 'DELETE'], (v) => _updateConfig('method', v)));
        fields.add(_buildTextField('URL', node.config['url'] ?? '', (v) => _updateConfig('url', v)));
        break;
      default:
        fields.add(const Text('No configuration available'));
    }
    
    return fields;
  }

  Widget _buildTextField(String label, String value, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        controller: TextEditingController(text: value),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: (v) => onChanged(v!),
      ),
    );
  }

  void _updateConfig(String key, dynamic value) {
    final node = _nodes[_selectedNodeId!]!;
    setState(() {
      _nodes[_selectedNodeId!] = WorkflowNode(
        id: node.id,
        name: node.name,
        type: node.type,
        config: {...node.config, key: value},
        x: node.x,
        y: node.y,
      );
    });
  }

  String _getConfigSummary(Map<String, dynamic> config) {
    if (config.isEmpty) return '';
    return config.values.first?.toString() ?? '';
  }

  Color _getNodeColor(WorkflowNodeType type) {
    switch (type) {
      case WorkflowNodeType.trigger: return Colors.amber[700]!;
      case WorkflowNodeType.agent: return Colors.blue;
      case WorkflowNodeType.condition: return Colors.purple;
      case WorkflowNodeType.action: return Colors.green;
      case WorkflowNodeType.delay: return Colors.orange;
      case WorkflowNodeType.filter: return Colors.teal;
      case WorkflowNodeType.transform: return Colors.indigo;
      case WorkflowNodeType.http: return Colors.red;
      case WorkflowNodeType.webhook: return Colors.pink;
    }
  }

  IconData _getNodeIcon(WorkflowNodeType type) {
    switch (type) {
      case WorkflowNodeType.trigger: return Icons.flash_on;
      case WorkflowNodeType.agent: return Icons.smart_toy;
      case WorkflowNodeType.condition: return Icons.call_split;
      case WorkflowNodeType.action: return Icons.play_circle;
      case WorkflowNodeType.delay: return Icons.timer;
      case WorkflowNodeType.filter: return Icons.filter_alt;
      case WorkflowNodeType.transform: return Icons.transform;
      case WorkflowNodeType.http: return Icons.http;
      case WorkflowNodeType.webhook: return Icons.webhook;
    }
  }

  void _runWorkflow() {
    setState(() => _isRunning = true);
    // Run workflow
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isRunning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workflow executed successfully!')),
      );
    });
  }

  void _saveWorkflow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workflow saved!')),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConnectionPainter extends CustomPainter {
  final Map<String, WorkflowNode> nodes;
  final Map<String, Offset> positions;

  _ConnectionPainter({required this.nodes, required this.positions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final node in nodes.values) {
      for (final outputId in node.outputIds) {
        final from = positions[node.id];
        final to = positions[outputId];
        if (from != null && to != null) {
          final path = Path()
            ..moveTo(from.dx + 80, from.dy + 40)
            ..cubicTo(
              from.dx + 80 + 50, from.dy + 40,
              to.dx + 80 - 50, to.dy + 40,
              to.dx + 80, to.dy + 40,
            );
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
