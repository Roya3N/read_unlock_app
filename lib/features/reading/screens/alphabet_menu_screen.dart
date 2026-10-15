import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:read_unlock_app/features/engagement/screens/letter_intro_screen.dart';

class AlphabetMenuScreen extends StatelessWidget {
  const AlphabetMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 رنگ‌های شاد با تم کهکشانی
    final List<Color> cardColors = [
      const Color(0xFF8B5CF6), // بنفش
      const Color(0xFFEF4444), // قرمز
      const Color(0xFF3B82F6), // آبی
      const Color(0xFF10B981), // سبز
      const Color(0xFFF59E0B), // زرد
      const Color(0xFFEC4899), // صورتی
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // پس‌زمینه دارک و مدرن
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "🔠 Alphabet Magic",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: 40,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: 26,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 20,
            childAspectRatio:
                0.75, // کارت‌ها کمی کشیده‌تر برای جا دادن ستاره‌ها
          ),
          itemBuilder: (context, index) {
            String letter = String.fromCharCode(65 + index);
            Color baseColor = cardColors[index % cardColors.length];

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                // ⭐️ آپگرید اصلی: هدایت به صفحه آموزش (Intro) به جای نقشه
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LetterIntroScreen(letter: letter),
                  ),
                );
              },
              child:
                  Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              baseColor.withOpacity(0.8),
                              baseColor.withOpacity(0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            // سایه برای ایجاد افکت 3D
                            BoxShadow(
                              color: baseColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: baseColor.withOpacity(0.6),
                              blurRadius: 0,
                              offset: const Offset(0, 5), // لبه پایینی دکمه
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              letter,
                              style: TextStyle(
                                fontSize: 50,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            // 🌟 نمایش ستاره‌های پیشرفت (فعلا نمایشی)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (starIndex) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.white.withOpacity(
                                      0.3,
                                    ), // ستاره‌های خاموش
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fade(duration: 400.ms, delay: (30 * index).ms)
                      .slideY(begin: 0.2, curve: Curves.easeOutBack),
            );
          },
        ),
      ),
    );
  }
}
