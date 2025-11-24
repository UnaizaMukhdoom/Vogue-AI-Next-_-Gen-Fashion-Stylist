// lib/screens/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_service.dart';

/// User Management Screen - View, search, and manage users
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by email or UID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: AdminService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No users found'),
                  );
                }

                var users = snapshot.data!.docs;
                
                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  users = users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final email = (data['email'] ?? '').toString().toLowerCase();
                    final uid = doc.id.toLowerCase();
                    return email.contains(_searchQuery) || uid.contains(_searchQuery);
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    return _UserCard(userId: userDoc.id, userData: userDoc.data() as Map<String, dynamic>);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const _UserCard({
    required this.userId,
    required this.userData,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _loading = false;
  Map<String, dynamic>? _detailedData;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    setState(() => _loading = true);
    try {
      final data = await AdminService.getUserData(widget.userId);
      setState(() {
        _detailedData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleBlock() async {
    final isBlocked = widget.userData['blocked'] == true;
    final action = isBlocked ? 'unblock' : 'block';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action User'),
        content: Text('Are you sure you want to $action this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      try {
        await AdminService.toggleUserBlock(widget.userId, !isBlocked);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${action}ed successfully')),
        );
        await _loadUserDetails();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _loading = false);
      }
    }
  }

  void _viewDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('UID', widget.userId),
              _DetailRow('Email', widget.userData['email'] ?? 'N/A'),
              if (_detailedData != null) ...[
                if (_detailedData!['onboarding'] != null) ...[
                  const Divider(),
                  const Text('Onboarding Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _DetailRow('Name', _detailedData!['onboarding']['name'] ?? 'N/A'),
                  _DetailRow('Body Type', _detailedData!['onboarding']['bodyType'] ?? 'N/A'),
                  _DetailRow('Size Range', _detailedData!['onboarding']['sizeRange'] ?? 'N/A'),
                ],
                if (_detailedData!['analysis'] != null) ...[
                  const Divider(),
                  const Text('Analysis Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _DetailRow('Has Analysis', 'Yes'),
                ],
              ],
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    final isBlocked = widget.userData['blocked'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBlocked ? Colors.red : Colors.green,
          child: Icon(
            isBlocked ? Icons.block : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          widget.userData['email'] ?? 'Unknown',
          style: TextStyle(
            decoration: isBlocked ? TextDecoration.lineThrough : null,
            color: isBlocked ? Colors.grey : null,
          ),
        ),
        subtitle: Text('UID: ${widget.userId.substring(0, 8)}...'),
        trailing: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: _viewDetails,
                    tooltip: 'View Details',
                  ),
                  IconButton(
                    icon: Icon(isBlocked ? Icons.lock_open : Icons.block),
                    onPressed: _toggleBlock,
                    tooltip: isBlocked ? 'Unblock' : 'Block',
                    color: isBlocked ? Colors.green : Colors.red,
                  ),
                ],
              ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

