import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _nameController = TextEditingController();
  String _selectedAgeGroup = 'Kids (5-9 years)';
  bool _isLoading = false;

  // 🎨 رنگ‌های تم Pro
  final Color darkGalaxy = const Color(0xFF1A1A2E);
  final Color primaryNeon = const Color(0xFF8B5CF6);
  final Color accentBlue = const Color(0xFF3B82F6);

  final List<Map<String, String>> _ageGroups = [
    {'title': 'Toddlers (3-4 years)', 'emoji': '👶', 'short': 'Toddler'},
    {'title': 'Kids (5-9 years)', 'emoji': '🧒', 'short': 'Kid'},
    {'title': 'Pre-teens (10-12 years)', 'emoji': '🧑', 'short': 'Pre-teen'},
    {'title': 'Teens (13-17 years)', 'emoji': '👨', 'short': 'Teen'},
  ];

  // متد ذخیره کودک در فایربیس
  Future<void> _saveChildToDatabase() async {
    HapticFeedback.mediumImpact();
    if (_nameController.text.trim().isEmpty) {
      _showProSnackBar("Please enter the explorer's name 🚀", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String? parentId = FirebaseAuth.instance.currentUser?.uid;

      if (parentId != null) {
        await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .add({
              'name': _nameController.text.trim(),
              'ageGroup': _selectedAgeGroup,
              'timeBalance': 0,
              'avatarUrl': 'default_avatar.png',
              'createdAt': FieldValue.serverTimestamp(),
            });

        if (!mounted) return;
        HapticFeedback.heavyImpact();
        _showProSnackBar("Explorer added successfully! 🎉");
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      _showProSnackBar("Error saving profile. Try again. 📡", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showProSnackBar(String message, {bool isError = false}) {
    final color = isError ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGalaxy,
      body: Stack(
        children: [
          // 🌌 هاله‌های نورانی
          Positioned(
            top: -50,
            right: -50,
            child: _buildGlowOrb(primaryNeon, 300),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _buildGlowOrb(accentBlue, 250),
          ),

          SafeArea(
            child: Column(
              children: [
                // هدر
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        'Add Explorer 🚀',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // آواتار درخشان
                        Center(
                          child:
                              Container(
                                padding: const EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  color: primaryNeon.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryNeon.withOpacity(0.5),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryNeon.withOpacity(0.3),
                                      blurRadius: 40,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.face_retouching_natural_rounded,
                                  size: 70,
                                  color: Colors.white,
                                ),
                              ).animate().scale(
                                curve: Curves.easeOutBack,
                                duration: 600.ms,
                              ),
                        ),
                        const SizedBox(height: 40),

                        // فیلد نام
                        const Text(
                          "Explorer's Name",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ).animate().fade(delay: 200.ms),
                        const SizedBox(height: 10),
                        _buildGlassInput()
                            .animate()
                            .fade(delay: 300.ms)
                            .slideX(begin: -0.1),

                        const SizedBox(height: 30),

                        // انتخاب گروه سنی (کارت‌های مدرن)
                        const Text(
                          "Age Group",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ).animate().fade(delay: 400.ms),
                        const SizedBox(height: 15),
                        _buildAgeGroupSelector()
                            .animate()
                            .fade(delay: 500.ms)
                            .slideY(begin: 0.1),

                        const SizedBox(height: 50),

                        // دکمه تایید
                        _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF8B5CF6),
                                ),
                              )
                            : GestureDetector(
                                    onTap: _saveChildToDatabase,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            primaryNeon,
                                            const Color(0xFF6D28D9),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryNeon.withOpacity(0.4),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "Create Profile ✨",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fade(delay: 600.ms)
                                  .scale(curve: Curves.easeOutBack),
                      ],
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

  Widget _buildGlassInput() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextField(
          controller: _nameController,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            hintText: "e.g. Leo or Mia",
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white54,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: primaryNeon, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeGroupSelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 2.5,
      ),
      itemCount: _ageGroups.length,
      itemBuilder: (context, index) {
        final age = _ageGroups[index];
        final isSelected = _selectedAgeGroup == age['title'];

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedAgeGroup = age['title']!);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentBlue.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? accentBlue : Colors.white.withOpacity(0.1),
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentBlue.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(age['emoji']!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  age['short']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 150)],
      ),
    );
  }
}
