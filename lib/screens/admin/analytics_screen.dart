// lib/screens/admin/analytics_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

/// Analytics Screen - View detailed statistics and charts
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _analytics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    try {
      final analytics = await AdminService.getAnalytics();
      setState(() {
        _analytics = analytics;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? const Center(child: Text('No analytics data available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Analytics Dashboard',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadAnalytics,
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _AnalyticsCard(
                            title: 'Total Users',
                            value: '${_analytics!['totalUsers']}',
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                          _AnalyticsCard(
                            title: 'Completed Onboarding',
                            value: '${_analytics!['usersWithOnboarding']}',
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          _AnalyticsCard(
                            title: 'Skin Analysis Done',
                            value: '${_analytics!['usersWithAnalysis']}',
                            icon: Icons.face,
                            color: Colors.orange,
                          ),
                          _AnalyticsCard(
                            title: 'Completion Rate',
                            value: '${_analytics!['completionRate']}%',
                            icon: Icons.trending_up,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Additional Analytics Section
                      Text(
                        'User Engagement',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _StatRow(
                                'Users with Onboarding',
                                '${_analytics!['usersWithOnboarding']}',
                                '${_analytics!['totalUsers']}',
                              ),
                              const Divider(),
                              _StatRow(
                                'Users with Analysis',
                                '${_analytics!['usersWithAnalysis']}',
                                '${_analytics!['totalUsers']}',
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

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String total;

  const _StatRow(this.label, this.value, this.total);

  @override
  Widget build(BuildContext context) {
    final percentage = total != '0' && total.isNotEmpty
        ? ((int.tryParse(value) ?? 0) / (int.tryParse(total) ?? 1) * 100).toStringAsFixed(1)
        : '0.0';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          '$value / $total ($percentage%)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

