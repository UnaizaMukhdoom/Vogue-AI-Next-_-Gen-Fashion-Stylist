import 'package:flutter/material.dart';

class ClosetScreen extends StatelessWidget {
  static const route = '/closet';
  const ClosetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121316),
      appBar: AppBar(title: const Text("Closet")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text("Scan / Upload"),
        icon: const Icon(Icons.camera_alt_outlined),
        backgroundColor: const Color(0xFFFFD54F),
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _item("Grey Tee", "100% suits you", Colors.green.shade400),
          _item("Black Jeans", "86% suits you", Colors.green.shade300),
          _item("Cool Grey Hoodie", "Low match", Colors.redAccent.shade100),
        ],
      ),
    );
  }

  Widget _item(String name, String badge, Color badgeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFF1E1F22), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
                color: const Color(0xFF2A2C31), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.emoji_people_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
            child: Text(badge, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
          )
        ],
      ),
    );
  }
}
