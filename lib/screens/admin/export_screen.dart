// lib/screens/admin/export_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

/// Export Screen - Export user data and reports
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _exporting = false;
  String? _exportData;

  Future<void> _exportUsers() async {
    setState(() {
      _exporting = true;
      _exportData = null;
    });

    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final users = [];

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        
        // Get onboarding data
        final onboardingQuery = await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .collection('onboarding')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        // Get analysis data
        final analysisDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .collection('analysis')
            .doc('latest')
            .get();

        users.add({
          'uid': doc.id,
          'email': userData['email'] ?? 'N/A',
          'createdAt': userData['createdAt']?.toString() ?? 'N/A',
          'blocked': userData['blocked'] ?? false,
          'onboarding': onboardingQuery.docs.isNotEmpty
              ? onboardingQuery.docs.first.data()
              : null,
          'hasAnalysis': analysisDoc.exists,
        });
      }

      final jsonData = jsonEncode({
        'exportDate': DateTime.now().toIso8601String(),
        'totalUsers': users.length,
        'users': users,
      });

      setState(() {
        _exportData = jsonData;
        _exporting = false;
      });
    } catch (e) {
      setState(() {
        _exporting = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export error: $e')),
      );
    }
  }

  Future<void> _exportAnalytics() async {
    setState(() {
      _exporting = true;
      _exportData = null;
    });

    try {
      final analytics = await FirebaseFirestore.instance
          .collection('analytics')
          .orderBy('date', descending: true)
          .limit(30)
          .get();

      final analyticsData = analytics.docs.map((doc) => doc.data()).toList();

      final jsonData = jsonEncode({
        'exportDate': DateTime.now().toIso8601String(),
        'analytics': analyticsData,
      });

      setState(() {
        _exportData = jsonData;
        _exporting = false;
      });
    } catch (e) {
      setState(() {
        _exporting = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export error: $e')),
      );
    }
  }

  void _copyToClipboard() {
    if (_exportData != null) {
      // In web, we can use Clipboard API
      // For now, show in a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Data'),
          content: SingleChildScrollView(
            child: SelectableText(_exportData!),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Data',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Options',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _exporting ? null : _exportUsers,
                      icon: const Icon(Icons.people),
                      label: const Text('Export All Users Data'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _exporting ? null : _exportAnalytics,
                      icon: const Icon(Icons.analytics),
                      label: const Text('Export Analytics Data'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_exporting) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              const Center(child: Text('Exporting data...')),
            ],
            if (_exportData != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Export Result',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: _copyToClipboard,
                            tooltip: 'Copy to Clipboard',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _exportData!,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

