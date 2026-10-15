import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminWordsScreen extends StatefulWidget {
  const AdminWordsScreen({super.key});

  @override
  State<AdminWordsScreen> createState() => _AdminWordsScreenState();
}

class _AdminWordsScreenState extends State<AdminWordsScreen> {
  final TextEditingController _jsonController = TextEditingController();
  bool _isLoading = false;

  final Color darkGalaxy = const Color(0xFF0F0F13);
  final Color primaryNeon = const Color(0xFF8B5CF6);

  // 🚀 تابع جادویی ارسال گروهی به فایربیس
  Future<void> _addWordsToFirebase() async {
    String jsonString = _jsonController.text.trim();

    if (jsonString.isEmpty) {
      _showSnackBar("⚠️ Please paste the JSON list first!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    // 🛠️ تمیز کردن خودکار کوتیشن‌های کج و کوله
    jsonString = jsonString
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");

    try {
      // تبدیل متن به لیست
      List<dynamic> parsedList = jsonDecode(jsonString);
      List<Map<String, dynamic>> validWords = [];

      // فیلتر کردن و اعتبارسنجی کلمات (حتما ۵ حرفی باشن)
      for (var item in parsedList) {
        if (item is Map) {
          String word = item['word']?.toString().trim().toUpperCase() ?? '';
          String hint = item['hint']?.toString().trim() ?? '';

          if (word.length == 5 && hint.isNotEmpty) {
            validWords.add({'word': word, 'hint': hint});
          } else {
            debugPrint("⚠️ Skipped invalid word: $word");
          }
        }
      }

      if (validWords.isEmpty) {
        _showSnackBar("❌ No valid 5-letter words found!", Colors.redAccent);
        setState(() => _isLoading = false);
        return;
      }

      // ارسال همه با هم به فایربیس!
      await FirebaseFirestore.instance
          .collection('game_settings')
          .doc('scramble_words')
          .set({
            'words': FieldValue.arrayUnion(validWords),
          }, SetOptions(merge: true));

      _showSnackBar(
        "✅ ${validWords.length} words added successfully!",
        const Color(0xFF4ADE80),
      );

      // پاک کردن کادر برای لیست بعدی
      _jsonController.clear();
    } on FormatException catch (e) {
      debugPrint("❌ JSON Format Error: ${e.message}");
      _showSnackBar(
        "❌ JSON Error: Check your brackets and quotes!",
        Colors.redAccent,
      );
    } catch (e) {
      _showSnackBar("❌ Error: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
    const hintJson = '''[
  {"word": "MAGIC", "hint": "Supernatural power 🎩"},
  {"word": "GHOST", "hint": "A spooky spirit 👻"},
  {"word": "FLAME", "hint": "Hot fire 🔥"}
]''';

    return Scaffold(
      backgroundColor: darkGalaxy,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: _buildGlowOrb(primaryNeon, 300),
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
                        'Bulk Word Injector 🧙‍♂️',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
                        const Text(
                          "Paste a JSON list of 5-letter words.",
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                        const SizedBox(height: 15),

                        // 🔤 باکس بزرگ دریافت کد JSON
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
                                    color: Colors.purpleAccent,
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

                        // 🚀 دکمه ثبت
                        _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF8B5CF6),
                                ),
                              )
                            : GestureDetector(
                                    onTap: _addWordsToFirebase,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5CF6),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF8B5CF6,
                                            ).withOpacity(0.4),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "Upload Array to Cloud ☁️",
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
