import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

// آدرس این ایمپورت‌ها رو بر اساس پوشه‌بندی جدیدت آپدیت کن
import 'package:read_unlock_app/core/services/audio_service.dart';
import 'package:read_unlock_app/core/services/database_service.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';

class QuizScreen extends StatefulWidget {
  final List<Map<String, dynamic>> quiz;
  final String level;
  final List<dynamic> vocabulary;

  const QuizScreen({
    super.key,
    required this.quiz,
    required this.level,
    this.vocabulary = const [],
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  String? selectedOption;
  bool isCorrect = false;
  bool isSavingReward = false;
  bool _isProcessing = false; // برای جلوگیری از کلیک‌های پشت سر هم

  // 🎨 رنگ‌های تم Pro
  final Color darkGalaxy = const Color(0xFF1A1A2E);
  final Color accentNeon = const Color(0xFF8B5CF6);
  final Color correctColor = const Color(0xFF10B981); // سبز زنده
  final Color wrongColor = const Color(0xFFEF4444); // قرمز زنده

  int getRewardTime() {
    switch (widget.level.toLowerCase()) {
      case 'hard':
        return 15;
      case 'medium':
        return 10;
      case 'easy':
      default:
        return 5;
    }
  }

  void checkAnswer(String option) {
    if (_isProcessing || selectedOption != null) return;

    // ۱. حذف فاصله‌های اضافی احتمالی (برای جلوگیری از باگ‌های عجیب)
    final correctAnswer = widget.quiz[currentQuestionIndex]['answer']
        .toString()
        .trim();
    final selected = option.trim();

    debugPrint("🎯 User clicked: [$selected]");
    debugPrint("✅ Real Answer is: [$correctAnswer]");

    setState(() {
      _isProcessing = true;
      selectedOption = option;
      isCorrect = (selected == correctAnswer);
    });

    if (isCorrect) {
      debugPrint("🔊 Trying to play CORRECT sound...");
      AudioService.playCorrect();

      // موقتاً ویبره رو خاموش می‌کنیم تا روی وب کرش نکنه
      // HapticFeedback.heavyImpact();

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        if (currentQuestionIndex < widget.quiz.length - 1) {
          setState(() {
            currentQuestionIndex++;
            selectedOption = null;
            isCorrect = false;
            _isProcessing = false;
          });
        } else {
          giveReward();
        }
      });
    } else {
      debugPrint("🔇 Trying to play WRONG sound...");
      AudioService.playWrong();

      // HapticFeedback.vibrate();

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        setState(() {
          selectedOption = null;
          _isProcessing = false;
        });
      });
    }
  }

  Future<void> giveReward() async {
    setState(() => isSavingReward = true);
    final reward = getRewardTime();
    final childId = AppState.activeChildId;

    try {
      await AudioService.playReward();
      await DatabaseService.addDailyTime(childId, reward);
      if (widget.vocabulary.isNotEmpty) {
        await DatabaseService.saveLearnedWords(childId, widget.vocabulary);
      }
    } catch (e) {
      debugPrint("Reward Error: $e");
    }

    if (mounted) {
      setState(() => isSavingReward = false);
      _showProRewardPopup(reward);
    }
  }

  // 🏆 پاپ‌آپ جایزه فوق‌حرفه‌ای
  void _showProRewardPopup(int reward) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, a1, a2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(a1.value),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: correctColor.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: correctColor.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("🎉", style: TextStyle(fontSize: 80)),
                      const SizedBox(height: 16),
                      Text(
                        "BRILLIANT!",
                        style: TextStyle(
                          color: correctColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "You earned\n$reward minutes\nof play time!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 35),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // بستن دیالوگ
                          Navigator.pop(context); // بازگشت به صفحه قبل
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [correctColor, const Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: correctColor.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Claim Reward 🎁",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quiz.isEmpty) {
      return Scaffold(
        backgroundColor: darkGalaxy,
        body: const Center(
          child: Text(
            "No quiz available! 🎈",
            style: TextStyle(color: Colors.white54, fontSize: 20),
          ),
        ),
      );
    }

    final currentQ = widget.quiz[currentQuestionIndex];
    final question = currentQ['question'] ?? 'Question?';
    final options = (currentQ['options'] as List<dynamic>)
        .map((e) => e.toString())
        .toList();

    return Scaffold(
      backgroundColor: darkGalaxy,
      body: Stack(
        children: [
          // 🌌 افکت‌های پس‌زمینه کهکشانی
          Positioned(
            top: -100,
            right: -50,
            child: _buildGlowOrb(accentNeon, 300),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _buildGlowOrb(Colors.blue, 350),
          ),

          SafeArea(
            child: isSavingReward
                ? _buildLoading()
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      children: [
                        // 🟢 هدر و دکمه خروج
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Quiz Time 🎯",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white70,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // 🟢 نوار پیشرفت انیمیشنی (Smooth Progress Bar)
                        Stack(
                          children: [
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                              height: 12,
                              width:
                                  MediaQuery.of(context).size.width *
                                  ((currentQuestionIndex + 1) /
                                      widget.quiz.length),
                              decoration: BoxDecoration(
                                color: accentNeon,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentNeon.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // 🟢 باکس سوال شیشه‌ای
                        _buildGlassQuestion(question),

                        const Spacer(),

                        // 🟢 گزینه‌ها با حروف A, B, C, D
                        ...List.generate(options.length, (index) {
                          return _buildOptionButton(options[index], index);
                        }),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassQuestion(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option, int index) {
    bool isThisSelected = selectedOption == option;
    Color btnColor = Colors.white.withOpacity(0.05);
    Color borderColor = Colors.white.withOpacity(0.1);
    Color textColor = Colors.white70;

    if (selectedOption != null) {
      if (isThisSelected) {
        btnColor = isCorrect
            ? correctColor.withOpacity(0.15)
            : wrongColor.withOpacity(0.15);
        borderColor = isCorrect ? correctColor : wrongColor;
        textColor = isCorrect ? correctColor : wrongColor;
      } else {
        // کمرنگ کردن گزینه‌های دیگر وقتی یکی انتخاب شده
        btnColor = Colors.transparent;
        borderColor = Colors.white.withOpacity(0.05);
        textColor = Colors.white30;
      }
    }

    // تولید حروف A, B, C, D
    String letter = String.fromCharCode(65 + index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () => checkAnswer(option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: btnColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isThisSelected
                ? [
                    BoxShadow(
                      color: borderColor.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // دایره حرف (A, B, C...)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isThisSelected
                      ? borderColor.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isThisSelected ? borderColor : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // متن گزینه
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),

              // آیکون وضعیت (تیک یا ضربدر)
              if (isThisSelected)
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: borderColor,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: accentNeon,
              strokeWidth: 4,
              backgroundColor: Colors.white10,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Saving your magic reward... ✨",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
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
