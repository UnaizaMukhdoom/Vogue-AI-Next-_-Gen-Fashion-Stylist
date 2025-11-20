import 'package:flutter/material.dart';

class AIStylistScreen extends StatefulWidget {
  static const route = '/ai-stylist';
  const AIStylistScreen({super.key});

  @override
  State<AIStylistScreen> createState() => _AIStylistScreenState();
}

class _AIStylistScreenState extends State<AIStylistScreen> {
  String _occasion = 'Work';
  final occasions = const ['Work', 'Casual', 'Party'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121316),
      appBar: AppBar(title: const Text("AI Stylist")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Choose occasion", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: occasions.map((o) => ChoiceChip(
                label: Text(o),
                selectedColor: const Color(0xFFFFC857),
                selected: _occasion == o,
                onSelected: (_) => setState(() => _occasion = o),
              )).toList(),
            ),
            const SizedBox(height: 16),
            _outfitCard("Look 1", "Leather jacket + wide jeans + sneakers"),
            _outfitCard("Look 2", "Camel coat + black tee + chinos"),
            const Spacer(),
            ElevatedButton(onPressed: () {}, child: const Text("Save outfits")),
          ],
        ),
      ),
    );
  }

  Widget _outfitCard(String title, String desc) {
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
            child: const Icon(Icons.checkroom_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: Colors.white70)),
            ],
          )),
          IconButton(onPressed: () {}, icon: const Icon(Icons.bookmark_add_outlined))
        ],
      ),
    );
  }
}
