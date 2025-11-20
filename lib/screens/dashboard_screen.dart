import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/skin_analysis_service.dart';
import 'result_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = '';
  String _colorType = '';
  bool _loading = true;
  AnalysisResult? _savedAnalysis;
  String? _savedImagePath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _userName = 'Stylist';
        _colorType = '';
        _loading = false;
      });
      return;
    }

    try {
      // Fetch user's name from onboarding
      final onboardingQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('onboarding')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      String name = 'Stylist';
      if (onboardingQuery.docs.isNotEmpty) {
        final data = onboardingQuery.docs.first.data();
        name = data['name'] as String? ?? 'Stylist';
      }

      // Fetch color analysis to get color type and save for Color Analysis feature
      String colorType = '';
      AnalysisResult? savedAnalysis;
      String? savedImagePath;
      try {
        final analysisDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('analysis')
            .doc('latest')
            .get();

        if (analysisDoc.exists && analysisDoc.data() != null) {
          final analysisData = analysisDoc.data()!;
          final analysisJson = analysisData['analysis'] as Map<String, dynamic>;
          final analysis = AnalysisResult.fromJson(analysisJson);
          
          // Map skin tone to seasonal color type
          colorType = _getSeasonalColorType(analysis.skinTone.category, analysis.skinTone.undertone);
          
          // Save analysis for Color Analysis feature
          savedAnalysis = analysis;
          savedImagePath = analysisData['imagePath'] as String?;
        }
      } catch (e) {
        // If analysis fetch fails (including permission errors), just use empty string
        // Don't show error - silently fail
      }

      setState(() {
        _userName = name;
        _colorType = colorType;
        _savedAnalysis = savedAnalysis;
        _savedImagePath = savedImagePath;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _userName = 'Stylist';
        _colorType = '';
        _loading = false;
      });
    }
  }

  Future<void> _openColorAnalysis(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to view your color analysis')),
      );
      return;
    }

    // First, check if we have saved analysis in state (already loaded)
    if (_savedAnalysis != null && _savedImagePath != null) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              results: {
                'path': _savedImagePath!,
                'analysis': _savedAnalysis!,
              },
            ),
          ),
        );
      }
      return;
    }

    // If not in state, try to fetch from Firebase
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('analysis')
          .doc('latest')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final analysisJson = data['analysis'] as Map<String, dynamic>;
        final imagePath = data['imagePath'] as String? ?? '';

        // Convert back to AnalysisResult
        final analysis = AnalysisResult.fromJson(analysisJson);

        // Update state for future use
        setState(() {
          _savedAnalysis = analysis;
          _savedImagePath = imagePath;
        });

        // Navigate to result screen with saved data (shows all 4 result screens)
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                results: {
                  'path': imagePath,
                  'analysis': analysis,
                },
              ),
            ),
          );
        }
      } else {
        // No saved analysis - show message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No color analysis found. Please complete skin tone analysis first.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Handle permission errors and other errors gracefully
      // Don't show error message for permission issues - just show no analysis message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No color analysis found. Please complete skin tone analysis first.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6B5CE7),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // Header with Logo and Greeting
            _buildHeader(_userName, _colorType),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Color Analysis Card (Large)
                    _ColorAnalysisCard(
                      onTap: () => _openColorAnalysis(context),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // AI Stylist and Fit Check Cards (Side by Side)
                    Row(
                      children: [
                        Expanded(
                          child: _AIStylistCard(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('AI Stylist coming soon!')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FitCheckCard(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fit Check coming soon!')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Complete Your Style Profile Banner
                    _StyleProfileBanner(),
                    
                    const SizedBox(height: 20),
                    
                    // Checked Items Section
                    const Text(
                      'Checked items',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _CheckedItemCard(
                      onScan: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Scan feature coming soon!')),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Personal Stylist Section
                    const Text(
                      'Personal stylist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PersonalStylistCard(
                      question: 'What are the current fashion trends?',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('AI Stylist feature coming soon!')),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _PersonalStylistCard(
                      question: 'What can I add to a basic tee and jeans to dress it up?',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('AI Stylist feature coming soon!')),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _PersonalStylistCard(
                      question: 'What accessories well with this outfit?',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('AI Stylist feature coming soon!')),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Map skin tone category and undertone to seasonal color type
  String _getSeasonalColorType(String category, String undertone) {
    // Map based on skin tone category and undertone
    final categoryLower = category.toLowerCase();
    final undertoneLower = undertone.toLowerCase();
    
    if (categoryLower.contains('very fair') || categoryLower.contains('fair')) {
      if (undertoneLower.contains('warm')) {
        return 'Light Spring 🌸';
      } else if (undertoneLower.contains('cool')) {
        return 'Light Summer 🌊';
      } else {
        return 'Light Spring 🌸';
      }
    } else if (categoryLower.contains('medium')) {
      if (undertoneLower.contains('warm')) {
        return 'Deep Autumn 🍁';
      } else if (undertoneLower.contains('cool')) {
        return 'Deep Winter ❄️';
      } else {
        return 'Deep Autumn 🍁';
      }
    } else if (categoryLower.contains('tan') || categoryLower.contains('olive')) {
      if (undertoneLower.contains('warm')) {
        return 'Warm Autumn 🍂';
      } else {
        return 'Deep Autumn 🍁';
      }
    } else if (categoryLower.contains('deep') || categoryLower.contains('dark')) {
      if (undertoneLower.contains('warm')) {
        return 'Deep Autumn 🍁';
      } else {
        return 'Deep Winter ❄️';
      }
    } else {
      // Default based on undertone
      if (undertoneLower.contains('warm')) {
        return 'Deep Autumn 🍁';
      } else if (undertoneLower.contains('cool')) {
        return 'Deep Winter ❄️';
      } else {
        return 'Deep Autumn 🍁';
      }
    }
  }

  Widget _buildHeader(String userName, String colorType) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Logo - Pink square with face
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB6C1), // Pink
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Center(
              child: Text(
                '😊',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello $userName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (colorType.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    colorType,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home, label: 'Home', isActive: true),
              _NavItem(icon: Icons.checkroom, label: 'My Closet'),
              _NavItem(icon: Icons.camera_alt, label: 'Scan', isCenter: true),
              _NavItem(icon: Icons.explore, label: 'Discover'),
              _NavItem(icon: Icons.person, label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

// Color Analysis Card - Large Purple Card with Color Wheel
class _ColorAnalysisCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ColorAnalysisCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B5CE7), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Color Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find what color to wear\nbase off your skin tone',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  child: const Text(
                    "Let's find out!",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Color Wheel with Face
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.indigo,
                  Colors.purple,
                  Colors.pink,
                  Colors.red,
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFF000000),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '👩',
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ),
                // Checkmarks
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// AI Stylist Card - Purple with Clothing Items
class _AIStylistCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AIStylistCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF6B5CE7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Stylist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Clothing items placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.checkroom,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Fit Check Card - Yellow with Photo
class _FitCheckCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FitCheckCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFC857),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.arrow_upward,
                    color: Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Fit Check',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Photo placeholder with badge
                  Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            color: Colors.black,
                            size: 30,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            'A+',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Style Profile Banner
class _StyleProfileBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2C31),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.checkroom,
              color: Color(0xFFFFC857),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete Your Style Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This will help us to build the best experience for you',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white70,
            size: 16,
          ),
        ],
      ),
    );
  }
}

// Checked Item Card
class _CheckedItemCard extends StatelessWidget {
  final VoidCallback onScan;

  const _CheckedItemCard({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Check if item suit you,\nstyle it and find similar.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: onScan,
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Scan Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '100% suits you',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // T-shirt image placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2C31),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.checkroom,
                color: Colors.white70,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Personal Stylist Question Card
class _PersonalStylistCard extends StatelessWidget {
  final String question;
  final VoidCallback onTap;

  const _PersonalStylistCard({
    required this.question,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bottom Navigation Item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isCenter;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCenter) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC857),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.black,
              size: 24,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? Colors.white : Colors.white70,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
