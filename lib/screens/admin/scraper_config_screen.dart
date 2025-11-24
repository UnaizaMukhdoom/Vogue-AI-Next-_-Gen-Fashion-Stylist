// lib/screens/admin/scraper_config_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Scraper Config Screen - Configure web scraping settings
class ScraperConfigScreen extends StatefulWidget {
  const ScraperConfigScreen({super.key});

  @override
  State<ScraperConfigScreen> createState() => _ScraperConfigScreenState();
}

class _ScraperConfigScreenState extends State<ScraperConfigScreen> {
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
      final doc = await FirebaseFirestore.instance
          .collection('scraper_config')
          .doc('settings')
          .get();

      if (doc.exists) {
        setState(() {
          _config = doc.data();
          _loading = false;
        });
      } else {
        // Create default config
        final defaultConfig = {
          'enabled': true,
          'maxItemsPerBrand': 10,
          'timeout': 30,
          'brands': ['Zara', 'H&M', 'Forever 21', 'ASOS', 'Shein'],
          'retryAttempts': 3,
        };
        await FirebaseFirestore.instance
            .collection('scraper_config')
            .doc('settings')
            .set(defaultConfig);
        setState(() {
          _config = defaultConfig;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('scraper_config')
          .doc('settings')
          .set({
        ..._config!,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _config == null
              ? const Center(child: Text('Error loading configuration'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Scraper Configuration',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _saveConfig,
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                title: const Text('Scraper Enabled'),
                                subtitle: const Text('Enable/disable web scraping'),
                                value: _config!['enabled'] ?? true,
                                onChanged: (value) {
                                  setState(() {
                                    _config!['enabled'] = value;
                                  });
                                },
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text('Max Items Per Brand'),
                                subtitle: Text('${_config!['maxItemsPerBrand'] ?? 10}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        setState(() {
                                          final current = _config!['maxItemsPerBrand'] ?? 10;
                                          if (current > 1) {
                                            _config!['maxItemsPerBrand'] = current - 1;
                                          }
                                        });
                                      },
                                    ),
                                    Text('${_config!['maxItemsPerBrand'] ?? 10}'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        setState(() {
                                          final current = _config!['maxItemsPerBrand'] ?? 10;
                                          _config!['maxItemsPerBrand'] = current + 1;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text('Timeout (seconds)'),
                                subtitle: Text('${_config!['timeout'] ?? 30}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        setState(() {
                                          final current = _config!['timeout'] ?? 30;
                                          if (current > 5) {
                                            _config!['timeout'] = current - 5;
                                          }
                                        });
                                      },
                                    ),
                                    Text('${_config!['timeout'] ?? 30}'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        setState(() {
                                          final current = _config!['timeout'] ?? 30;
                                          _config!['timeout'] = current + 5;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text('Retry Attempts'),
                                subtitle: Text('${_config!['retryAttempts'] ?? 3}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        setState(() {
                                          final current = _config!['retryAttempts'] ?? 3;
                                          if (current > 1) {
                                            _config!['retryAttempts'] = current - 1;
                                          }
                                        });
                                      },
                                    ),
                                    Text('${_config!['retryAttempts'] ?? 3}'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        setState(() {
                                          final current = _config!['retryAttempts'] ?? 3;
                                          _config!['retryAttempts'] = current + 1;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text('Brands'),
                                subtitle: Text(
                                  (_config!['brands'] as List?)?.join(', ') ?? 'None',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    // Show edit brands dialog
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Edit Brands'),
                                        content: const Text('Feature coming soon'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

