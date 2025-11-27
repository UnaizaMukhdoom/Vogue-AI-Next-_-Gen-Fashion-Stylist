// lib/screens/add_wardrobe_item_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/wardrobe_service.dart';

class AddWardrobeItemScreen extends StatefulWidget {
  const AddWardrobeItemScreen({super.key});

  @override
  State<AddWardrobeItemScreen> createState() => _AddWardrobeItemScreenState();
}

class _AddWardrobeItemScreenState extends State<AddWardrobeItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;
  bool _showCustomColor = false;

  // Form fields
  String _category = 'top';
  String _color = 'black';
  String _customColor = '';
  String _season = 'all-season';
  String _occasion = 'casual';
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();

  final List<String> _categories = [
    'top',
    'shirt',
    'blouse',
    'pants',
    'jeans',
    'skirt',
    'dress',
    'jacket',
    'shoes',
    'accessory',
  ];

  final List<String> _colors = [
    'black',
    'white',
    'gray',
    'blue',
    'red',
    'green',
    'yellow',
    'pink',
    'brown',
    'purple',
    'orange',
    'custom',
  ];

  @override
  void dispose() {
    _brandController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _uploadItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final color = _color == 'custom' && _customColor.isNotEmpty
          ? _customColor.trim().toLowerCase()
          : _color;

      await WardrobeService.uploadItem(
        imageFile: _selectedImage!,
        category: _category,
        color: color,
        season: _season,
        occasion: _occasion,
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        price: int.tryParse(_priceController.text) ?? 0,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text(
          'Add Item to Wardrobe',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Upload Section
              _buildImageUploadSection(),
              const SizedBox(height: 24),

              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _category = value ?? 'top');
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Color
              DropdownButtonFormField<String>(
                value: _color,
                decoration: InputDecoration(
                  labelText: 'Color *',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _colors.map((color) {
                  return DropdownMenuItem(
                    value: color,
                    child: Text(color.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _color = value ?? 'black';
                    _showCustomColor = value == 'custom';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a color';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Custom Color Input
              if (_showCustomColor)
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Custom Color *',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _customColor = value);
                  },
                  validator: _showCustomColor
                      ? (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a color';
                          }
                          return null;
                        }
                      : null,
                ),
              if (_showCustomColor) const SizedBox(height: 16),

              // Season and Occasion Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _season,
                      decoration: InputDecoration(
                        labelText: 'Season',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all-season', child: Text('All Season')),
                        DropdownMenuItem(value: 'spring', child: Text('Spring')),
                        DropdownMenuItem(value: 'summer', child: Text('Summer')),
                        DropdownMenuItem(value: 'fall', child: Text('Fall')),
                        DropdownMenuItem(value: 'winter', child: Text('Winter')),
                      ],
                      onChanged: (value) {
                        setState(() => _season = value ?? 'all-season');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _occasion,
                      decoration: InputDecoration(
                        labelText: 'Occasion',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'casual', child: Text('Casual')),
                        DropdownMenuItem(value: 'formal', child: Text('Formal')),
                        DropdownMenuItem(value: 'business', child: Text('Business')),
                        DropdownMenuItem(value: 'party', child: Text('Party')),
                      ],
                      onChanged: (value) {
                        setState(() => _occasion = value ?? 'casual');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Brand and Price Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: InputDecoration(
                        labelText: 'Brand (Optional)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price (Rs.)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Add to Wardrobe',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Image *',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showImageSourceDialog(),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select image',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedImage = null);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
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
}

