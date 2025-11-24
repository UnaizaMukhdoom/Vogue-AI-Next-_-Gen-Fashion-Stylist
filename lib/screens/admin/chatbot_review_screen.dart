// lib/screens/admin/chatbot_review_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Chatbot Review Screen - Review chatbot conversations
class ChatbotReviewScreen extends StatefulWidget {
  const ChatbotReviewScreen({super.key});

  @override
  State<ChatbotReviewScreen> createState() => _ChatbotReviewScreenState();
}

class _ChatbotReviewScreenState extends State<ChatbotReviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chatbot_conversations')
            .orderBy('timestamp', descending: true)
            .limit(100)
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
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No chatbot conversations yet',
                    style: TextStyle(color: Colors.grey[600]),
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
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text('User: ${data['userId'] ?? 'Unknown'}'),
                  subtitle: Text('Messages: ${(data['messages'] as List?)?.length ?? 0}'),
                  children: [
                    if (data['messages'] != null)
                      ...(data['messages'] as List).map((msg) {
                        return ListTile(
                          leading: Icon(
                            msg['role'] == 'user' ? Icons.person : Icons.smart_toy,
                            color: msg['role'] == 'user' ? Colors.blue : Colors.green,
                          ),
                          title: Text(msg['content'] ?? ''),
                          subtitle: Text(msg['timestamp']?.toString() ?? ''),
                        );
                      }).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

