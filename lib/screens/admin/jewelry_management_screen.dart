// lib/screens/admin/jewelry_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';

/// Jewelry Management Screen - Manage jewelry recommendations
class JewelryManagementScreen extends StatefulWidget {
  const JewelryManagementScreen({super.key});

  @override
  State<JewelryManagementScreen> createState() => _JewelryManagementScreenState();
}

class _JewelryManagementScreenState extends State<JewelryManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jewelry Items',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Jewelry'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jewelry_items')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.diamond, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No jewelry items yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _showAddDialog,
                          child: const Text('Add First Item'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    return _JewelryItemCard(
                      itemId: doc.id,
                      itemData: doc.data() as Map<String, dynamic>,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditJewelryDialog(),
    );
  }
}

class _JewelryItemCard extends StatelessWidget {
  final String itemId;
  final Map<String, dynamic> itemData;

  const _JewelryItemCard({
    required this.itemId,
    required this.itemData,
  });

  Future<void> _deleteItem(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${itemData['name'] ?? 'this item'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('jewelry_items').doc(itemId).delete();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _editItem(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddEditJewelryDialog(
        itemId: itemId,
        itemData: itemData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.diamond, size: 40),
        title: Text(itemData['name'] ?? 'Untitled'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${itemData['type'] ?? 'N/A'}'),
            Text('Skin Tone: ${itemData['skinTone'] ?? 'N/A'}'),
            Text('Description: ${itemData['description'] ?? 'N/A'}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editItem(context),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteItem(context),
              tooltip: 'Delete',
              color: Colors.red,
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _AddEditJewelryDialog extends StatefulWidget {
  final String? itemId;
  final Map<String, dynamic>? itemData;

  const _AddEditJewelryDialog({this.itemId, this.itemData});

  @override
  State<_AddEditJewelryDialog> createState() => _AddEditJewelryDialogState();
}

class _AddEditJewelryDialogState extends State<_AddEditJewelryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _skinToneController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemData != null) {
      _nameController.text = widget.itemData!['name'] ?? '';
      _typeController.text = widget.itemData!['type'] ?? '';
      _skinToneController.text = widget.itemData!['skinTone'] ?? '';
      _descriptionController.text = widget.itemData!['description'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _skinToneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final itemData = {
        'name': _nameController.text.trim(),
        'type': _typeController.text.trim(),
        'skinTone': _skinToneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.itemId != null) {
        await FirebaseFirestore.instance
            .collection('jewelry_items')
            .doc(widget.itemId)
            .update(itemData);
      } else {
        itemData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('jewelry_items').add(itemData);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.itemId != null ? 'Item updated' : 'Item added'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.itemId != null ? 'Edit Jewelry' : 'Add Jewelry'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Type (e.g., Necklace, Earrings)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _skinToneController,
                decoration: const InputDecoration(
                  labelText: 'Recommended Skin Tone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.itemId != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

