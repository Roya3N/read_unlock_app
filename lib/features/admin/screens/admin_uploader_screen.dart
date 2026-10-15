import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:read_unlock_app/core/utils/safe_action.dart';

class AdminBookUploader extends StatefulWidget {
  const AdminBookUploader({super.key});

  @override
  State<AdminBookUploader> createState() => _AdminBookUploaderState();
}

class _AdminBookUploaderState extends State<AdminBookUploader> {
  final TextEditingController _jsonController = TextEditingController();
  bool _isLoading = false;

  final Color darkGalaxy = const Color(0xFF1A1A2E);
  final Color primaryNeon = const Color(0xFF8B5CF6);
  final Color matrixGreen = const Color(0xFF10B981);

  final List<String> _validCategories = [
    'Toddlers (3-4 years)',
    'Kids (5-9 years)',
    'Pre-teens (10-12 years)',
    'Teens (13-17 years)',
  ];
  // ==========================================
  // 🚀 متد تزریق به دیتابیس (Pro Upgrade + JSON Cleaner)
  // ==========================================
  Future<void> _uploadBook() async {
    HapticFeedback.mediumImpact();
    String jsonString = _jsonController.text.trim();

    if (jsonString.isEmpty) {
      _showProSnackBar("Please paste the JSON code first! 📜", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // 🛠️ Pro Upgrade 1: پاکسازی خودکارِ کوتیشن‌های نامعتبر که موقع کپی‌پیست ایجاد میشن
    jsonString = jsonString
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");

    try {
      final Map<String, dynamic> bookData = jsonDecode(jsonString);

      final String? category = bookData['category'];
      if (category == null || !_validCategories.contains(category)) {
        _showProSnackBar(
          "❌ Invalid Category! Check exact name.",
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }

      // بررسی وجود و عدد بودنِ پاداش‌ها
      if (bookData['timeReward'] == null || bookData['xpReward'] == null) {
        _showProSnackBar(
          "❌ Missing Rewards! Need 'timeReward' & 'xpReward'.",
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }

      if (bookData['timeReward'] is! num || bookData['xpReward'] is! num) {
        _showProSnackBar(
          "❌ Rewards must be NUMBERS (e.g., 10), not text!",
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }

      if (bookData['vocabulary'] == null) {
        bookData['vocabulary'] = [];
      }

      // اضافه کردن مهر زمانِ اتوماتیک سرور
      bookData['createdAt'] = FieldValue.serverTimestamp();

      // ارسال به دیتابیس
      await FirebaseFirestore.instance.collection('books').add(bookData);

      HapticFeedback.heavyImpact();
      _showProSnackBar("🎉 Magic! Book injected into '$category'!");
      _jsonController.clear();
    } on FormatException catch (e) {
      // 🛠️ Pro Upgrade 2: پیدا کردن و نمایش دقیقِ محل خطای JSON
      debugPrint("❌ JSON Format Error: ${e.message}");

      // اگر خطای اضافه بودن کاراکتر بود، پیام ساده‌تر نشون میده
      if (e.message.contains('Unexpected character')) {
        _showProSnackBar(
          "❌ Error: You have extra characters at the end (like letters or numbers)!",
          isError: true,
        );
      } else {
        _showProSnackBar("JSON Error: ${e.message}", isError: true);
      }
    } catch (e) {
      debugPrint("❌ Unknown Error: $e");
      _showProSnackBar("Error: Something went wrong! ❌", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // 🎨 اسنک‌بار شیشه‌ای
  // ==========================================
  void _showProSnackBar(String message, {bool isError = false}) {
    final color = isError ? const Color(0xFFEF4444) : matrixGreen;
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
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const hintJson = '''{
  "title": "Timo the Tree",
  "level": "Easy",
  "minAge": 5,
  "xpReward": 20,
  "timeReward": 10,
  "category": "Kids (5-9 years)",
  "coverImage": "https://link.jpg",
  "pages": ["link1.jpg"],
  "pageTexts": ["Once upon a time..."],
  "vocabulary": ["tree"],
  "quiz": [ { "page": 1, "question": "Happy?", "answer": "Yes", "options": ["Yes", "No"] } ]
}''';

    return Scaffold(
      backgroundColor: darkGalaxy,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: _buildGlowOrb(primaryNeon, 300),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _buildGlowOrb(matrixGreen, 250),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        // 🛡️ استفاده از SafeAction برای دکمه بازگشت
                        onTap: () {
                          SafeAction.execute(() {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          });
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
                        'Secret Injector 🪄',
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
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: primaryNeon.withOpacity(0.5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryNeon.withOpacity(0.1),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: primaryNeon,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "EXACT Categories Allowed:",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    "• Toddlers (3-4 years)\n• Kids (5-9 years)\n• Pre-teens (10-12 years)\n• Teens (13-17 years)",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fade(duration: 400.ms).slideY(begin: -0.2),
                        const SizedBox(height: 20),

                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: _jsonController,
                                  maxLines: null,
                                  expands: true,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    color: Colors.greenAccent,
                                    fontSize: 14,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: hintJson,
                                    hintStyle: TextStyle(
                                      color: Colors.white24,
                                      fontFamily: 'monospace',
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(20),
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fade(delay: 200.ms).slideY(),
                        ),
                        const SizedBox(height: 20),

                        _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF10B981),
                                ),
                              )
                            : GestureDetector(
                                    // 🛡️ استفاده از SafeAction برای جلوگیری از دابل کلیک روی سرور
                                    onTap: () {
                                      SafeAction.execute(() {
                                        _uploadBook();
                                      });
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            matrixGreen,
                                            const Color(0xFF047857),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: matrixGreen.withOpacity(0.4),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "Inject to Firebase 🚀",
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
                                  .fade(delay: 400.ms)
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
