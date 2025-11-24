// lib/screens/admin/questionnaire_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';
import 'dart:convert';

/// Questionnaire Management Screen - Manage questionnaire questions and options
class QuestionnaireManagementScreen extends StatefulWidget {
  const QuestionnaireManagementScreen({super.key});

  @override
  State<QuestionnaireManagementScreen> createState() => _QuestionnaireManagementScreenState();
}

class _QuestionnaireManagementScreenState extends State<QuestionnaireManagementScreen> {
  Map<String, dynamic>? _config;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _loading = true);
    try {
      final doc = await AdminService.getQuestionnaireConfig();
      if (doc.exists) {
        setState(() {
          _config = doc.data();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;

    try {
      await AdminService.updateQuestionnaireConfig(_config!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Questionnaire updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _editField(String key, dynamic value) {
    showDialog(
      context: context,
      builder: (context) => _EditFieldDialog(
        fieldName: key,
        currentValue: value,
        onSave: (newValue) {
          setState(() {
            _config![key] = newValue;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _config == null
              ? const Center(child: Text('No questionnaire config found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Questionnaire Configuration',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _saveConfig,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Changes'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Body Types
                      _ConfigSection(
                        title: 'Body Types',
                        items: _config!['bodyTypes'] as List<dynamic>? ?? [],
                        onEdit: () => _editField('bodyTypes', _config!['bodyTypes']),
                      ),
                      const SizedBox(height: 16),
                      // Size Ranges
                      _ConfigSection(
                        title: 'Size Ranges',
                        items: _config!['sizeRanges'] as List<dynamic>? ?? [],
                        onEdit: () => _editField('sizeRanges', _config!['sizeRanges']),
                      ),
                      const SizedBox(height: 16),
                      // Fit Preferences
                      _ConfigSection(
                        title: 'Fit Preferences',
                        items: _config!['fitPrefs'] as List<dynamic>? ?? [],
                        onEdit: () => _editField('fitPrefs', _config!['fitPrefs']),
                      ),
                      const SizedBox(height: 16),
                      // Style Goals
                      _ConfigSection(
                        title: 'Style Goals',
                        items: _config!['styleGoals'] as List<dynamic>? ?? [],
                        onEdit: () => _editField('styleGoals', _config!['styleGoals']),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _ConfigSection extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final VoidCallback onEdit;

  const _ConfigSection({
    required this.title,
    required this.items,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                return Chip(
                  label: Text(item.toString()),
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditFieldDialog extends StatefulWidget {
  final String fieldName;
  final dynamic currentValue;
  final Function(dynamic) onSave;

  const _EditFieldDialog({
    required this.fieldName,
    required this.currentValue,
    required this.onSave,
  });

  @override
  State<_EditFieldDialog> createState() => _EditFieldDialogState();
}

class _EditFieldDialogState extends State<_EditFieldDialog> {
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    if (widget.currentValue is List) {
      _items = List<String>.from(widget.currentValue.map((e) => e.toString()));
    } else {
      _items = [];
    }
  }

  void _addItem() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Item',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _items.add(controller.text.trim());
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.fieldName}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListView.builder(
              shrinkWrap: true,
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_items[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeItem(index),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_items);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

