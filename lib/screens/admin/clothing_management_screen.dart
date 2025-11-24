// lib/screens/admin/clothing_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';

/// Clothing Management Screen - Add, edit, delete clothing items
class ClothingManagementScreen extends StatefulWidget {
  const ClothingManagementScreen({super.key});

  @override
  State<ClothingManagementScreen> createState() => _ClothingManagementScreenState();
}

class _ClothingManagementScreenState extends State<ClothingManagementScreen> {
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
                  'Clothing Items',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: AdminService.getClothingItems(),
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
                        Icon(Icons.checkroom, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No clothing items yet',
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
                    return _ClothingItemCard(
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
      builder: (context) => _AddEditClothingDialog(),
    );
  }
}

class _ClothingItemCard extends StatelessWidget {
  final String itemId;
  final Map<String, dynamic> itemData;

  const _ClothingItemCard({
    required this.itemId,
    required this.itemData,
  });

  Future<void> _deleteItem(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${itemData['title'] ?? 'this item'}"?'),
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
        await AdminService.deleteClothingItem(itemId);
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
      builder: (context) => _AddEditClothingDialog(
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
        leading: itemData['image_url'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  itemData['image_url'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image),
                ),
              )
            : const Icon(Icons.checkroom, size: 40),
        title: Text(itemData['title'] ?? 'Untitled'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Brand: ${itemData['brand'] ?? 'Unknown'}'),
            Text('Color: ${itemData['color'] ?? 'N/A'}'),
            Text('Price: ${itemData['price'] ?? 'N/A'}'),
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

class _AddEditClothingDialog extends StatefulWidget {
  final String? itemId;
  final Map<String, dynamic>? itemData;

  const _AddEditClothingDialog({this.itemId, this.itemData});

  @override
  State<_AddEditClothingDialog> createState() => _AddEditClothingDialogState();
}

class _AddEditClothingDialogState extends State<_AddEditClothingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _brandController = TextEditingController();
  final _colorController = TextEditingController();
  final _priceController = TextEditingController();
  final _urlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemData != null) {
      _titleController.text = widget.itemData!['title'] ?? '';
      _brandController.text = widget.itemData!['brand'] ?? '';
      _colorController.text = widget.itemData!['color'] ?? '';
      _priceController.text = widget.itemData!['price']?.toString() ?? '';
      _urlController.text = widget.itemData!['url'] ?? '';
      _imageUrlController.text = widget.itemData!['image_url'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final itemData = {
        'title': _titleController.text.trim(),
        'brand': _brandController.text.trim(),
        'color': _colorController.text.trim(),
        'price': _priceController.text.trim(),
        'url': _urlController.text.trim(),
        'image_url': _imageUrlController.text.trim(),
      };

      if (widget.itemId != null) {
        await AdminService.updateClothingItem(widget.itemId!, itemData);
      } else {
        await AdminService.addClothingItem(itemData);
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
      title: Text(widget.itemId != null ? 'Edit Item' : 'Add Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a brand';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Product URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                ),
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

