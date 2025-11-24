// lib/screens/create_outfit_screen.dart
import 'package:flutter/material.dart';

/// Create Your Outfit Screen - Professional outfit creation interface
class CreateOutfitScreen extends StatefulWidget {
  const CreateOutfitScreen({super.key});

  @override
  State<CreateOutfitScreen> createState() => _CreateOutfitScreenState();
}

class _CreateOutfitScreenState extends State<CreateOutfitScreen> {
  final List<OutfitItem> _items = [];
  bool _canUndo = false;
  bool _canRedo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121316),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _CustomHeader(
              onClose: () => Navigator.pop(context),
              canProceed: _items.isNotEmpty,
            ),
            // Main Content Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  children: [
                    // Grid Pattern Background
                    _GridPattern(),
                    // Outfit Items
                    if (_items.isNotEmpty)
                      ..._items.map((item) => _OutfitItemWidget(item: item)),
                    // Empty State
                    if (_items.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.checkroom_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Add items to create your outfit',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Undo/Redo Controls
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ControlButton(
                            icon: Icons.undo,
                            enabled: _canUndo,
                            onTap: _canUndo ? _undo : null,
                          ),
                          const SizedBox(width: 16),
                          _ControlButton(
                            icon: Icons.redo,
                            enabled: _canRedo,
                            onTap: _canRedo ? _redo : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer with Add Items Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF121316),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showAddItemsDialog,
                  icon: const Icon(Icons.add, size: 24),
                  label: const Text(
                    'Add items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1F22),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1F22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddItemsBottomSheet(
        onItemAdded: (item) {
          setState(() {
            _items.add(item);
            _canUndo = true;
            _canRedo = false;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _undo() {
    if (_items.isNotEmpty) {
      setState(() {
        _items.removeLast();
        _canRedo = true;
        if (_items.isEmpty) {
          _canUndo = false;
        }
      });
    }
  }

  void _redo() {
    // Implement redo logic if needed
    setState(() {
      _canRedo = false;
    });
  }
}

// Custom Header
class _CustomHeader extends StatelessWidget {
  final VoidCallback onClose;
  final bool canProceed;

  const _CustomHeader({
    required this.onClose,
    required this.canProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close Button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          // Title
          const Text(
            'Create your outfit',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Next Button
          TextButton(
            onPressed: canProceed
                ? () {
                    // Navigate to next step or save outfit
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Outfit saved!')),
                    );
                  }
                : null,
            child: Text(
              'Next',
              style: TextStyle(
                color: canProceed ? Colors.blue : Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Grid Pattern Background
class _GridPattern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(),
      child: Container(),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;

    const spacing = 20.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Outfit Item Model
class OutfitItem {
  final String id;
  final String name;
  final String type;
  final Color color;
  final Offset position;

  OutfitItem({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.position,
  });
}

class _OutfitItemWidget extends StatelessWidget {
  final OutfitItem item;

  const _OutfitItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          // Handle drag to reposition
        },
        child: Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.checkroom,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Control Button (Undo/Redo)
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? Colors.grey[100] : Colors.grey[50],
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.grey[700] : Colors.grey[300],
          size: 20,
        ),
      ),
    );
  }
}

// Add Items Bottom Sheet
class _AddItemsBottomSheet extends StatelessWidget {
  final Function(OutfitItem) onItemAdded;

  const _AddItemsBottomSheet({required this.onItemAdded});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'name': 'T-Shirt', 'type': 'Top', 'color': Colors.blue},
      {'name': 'Jeans', 'type': 'Bottom', 'color': Colors.indigo},
      {'name': 'Dress', 'type': 'Dress', 'color': Colors.red},
      {'name': 'Jacket', 'type': 'Outerwear', 'color': Colors.brown},
      {'name': 'Shoes', 'type': 'Footwear', 'color': Colors.black},
      {'name': 'Bag', 'type': 'Accessory', 'color': Colors.purple},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select an item',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  onItemAdded(
                    OutfitItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: item['name'] as String,
                      type: item['type'] as String,
                      color: item['color'] as Color,
                      position: Offset(
                        50.0 + (index % 3) * 100.0,
                        100.0 + (index ~/ 3) * 120.0,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.checkroom,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

