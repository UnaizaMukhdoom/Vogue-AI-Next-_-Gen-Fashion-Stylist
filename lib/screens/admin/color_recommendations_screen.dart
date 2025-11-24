// lib/screens/admin/color_recommendations_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Color Recommendations Screen - Update color recommendations based on skin tone
class ColorRecommendationsScreen extends StatefulWidget {
  const ColorRecommendationsScreen({super.key});

  @override
  State<ColorRecommendationsScreen> createState() => _ColorRecommendationsScreenState();
}

class _ColorRecommendationsScreenState extends State<ColorRecommendationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('config')
            .doc('color_recommendations')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.palette, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No color recommendations configured',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _createDefaultConfig(),
                    child: const Text('Create Default Configuration'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Color Recommendations',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showEditDialog(data),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...data.entries.map((entry) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          if (entry.value is List)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (entry.value as List).map((color) {
                                return Chip(
                                  label: Text(color.toString()),
                                  backgroundColor: _getColorFromName(color.toString()),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    // Simple color mapping - can be enhanced
    final colors = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'brown': Colors.brown,
    };
    return colors[colorName.toLowerCase()]?.withOpacity(0.2) ?? Colors.grey[200]!;
  }

  Future<void> _createDefaultConfig() async {
    final defaultConfig = {
      'light_warm': ['Coral', 'Peach', 'Cream', 'Warm Pink'],
      'light_cool': ['Sky Blue', 'Lavender', 'Mint', 'Rose'],
      'medium_warm': ['Terracotta', 'Olive', 'Amber', 'Rust'],
      'medium_cool': ['Navy', 'Teal', 'Plum', 'Slate'],
      'dark_warm': ['Burgundy', 'Gold', 'Bronze', 'Deep Orange'],
      'dark_cool': ['Royal Blue', 'Emerald', 'Deep Purple', 'Charcoal'],
    };

    await FirebaseFirestore.instance
        .collection('config')
        .doc('color_recommendations')
        .set(defaultConfig);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default configuration created')),
    );
  }

  void _showEditDialog(Map<String, dynamic> currentData) {
    // Similar to questionnaire management - allow editing color recommendations
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Color Recommendations'),
        content: const Text('Feature coming soon - Edit color recommendations by skin tone'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

