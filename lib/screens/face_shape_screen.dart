// lib/screens/face_shape_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/face_shape_service.dart';
import '../utils/image_compressor.dart';

class FaceShapeScreen extends StatefulWidget {
  static const route = '/face-shape';
  
  const FaceShapeScreen({super.key});

  @override
  State<FaceShapeScreen> createState() => _FaceShapeScreenState();
}

class _FaceShapeScreenState extends State<FaceShapeScreen> {
  final _picker = ImagePicker();
  XFile? _picked;
  bool _analyzing = false;
  FaceShapeResult? _result;

  Future<void> _pickImage(ImageSource source) async {
    final x = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 92,
    );
    
    if (x != null) {
      setState(() {
        _picked = x;
        _result = null;
      });
    }
  }

  Future<void> _analyzeFaceShape() async {
    if (_picked == null) return;

    setState(() => _analyzing = true);

    try {
      // Compress image
      final compressedPath = await ImageCompressor.compressImage(_picked!.path);
      final imagePath = compressedPath ?? _picked!.path;
      
      // Analyze
      final result = await FaceShapeService.analyzeFaceShape(imagePath);

      if (!mounted) return;

      setState(() {
        _result = result;
        _analyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _analyzing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFE5DCD8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFA1BC98)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFA1BC98)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DCD8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5DCD8),
        elevation: 0,
        title: const Text(
          'Face Shape Analysis',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image picker section
            if (_picked == null)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.face, size: 80, color: Color(0xFFA1BC98)),
                    const SizedBox(height: 16),
                    const Text(
                      'Take a clear face photo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showImageSourceDialog,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA1BC98),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_picked!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_analyzing && _result == null)
                    ElevatedButton(
                      onPressed: _analyzeFaceShape,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA1BC98),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Analyze Face Shape',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (!_analyzing && _result == null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _picked = null;
                          _result = null;
                        });
                      },
                      child: const Text('Choose Different Photo'),
                    ),
                ],
              ),

            // Loading indicator
            if (_analyzing)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),

            // Results section
            if (_result != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA1BC98).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.face,
                            color: Color(0xFFA1BC98),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Face Shape',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _result!.faceShape,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5DCD8).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _result!.jewelryRecommendations['description'] ?? '',
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Earrings recommendations
                    _buildRecommendationSection(
                      'Earrings',
                      _result!.jewelryRecommendations['earrings'] ?? [],
                      Icons.earbuds,
                    ),
                    const SizedBox(height: 16),
                    
                    // Necklaces recommendations
                    _buildRecommendationSection(
                      'Necklaces',
                      _result!.jewelryRecommendations['necklaces'] ?? [],
                      Icons.diamond,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationSection(String title, List<dynamic> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFA1BC98), size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFA1BC98),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.toString(),
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

