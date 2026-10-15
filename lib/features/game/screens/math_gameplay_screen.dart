import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:read_unlock_app/core/services/audio_service.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'math_quest_screen.dart';
import 'package:read_unlock_app/core/utils/progress_service.dart';

class MathGameplayScreen extends StatefulWidget {
  final MathLevel level;
  const MathGameplayScreen({super.key, required this.level});

  @override
  State<MathGameplayScreen> createState() => _MathGameplayScreenState();
}

class _MathGameplayScreenState extends State<MathGameplayScreen>
    with SingleTickerProviderStateMixin {
  int num1 = 0;
  int num2 = 0;
  int correctAnswer = 0;
  int currentScore = 0;
  String currentInput = "";
  String operation = '+';
  bool isWrong = false;
  bool isCorrect = false;

  final List<String> countingIcons = [
    "🍎",
    "🎈",
    "🌟",
    "🐶",
    "🚗",
    "🍓",
    "🦋",
    "🍩",
  ];
  String currentCountingIcon = "🍎";

  Color get _glowColor {
    if (isCorrect) return const Color(0xFF4ADE80);
    if (isWrong) return const Color(0xFFF87171);
    return widget.level.color;
  }

  DateTime? _gameStartTime;

  @override
  void initState() {
    super.initState();
    _gameStartTime = DateTime.now();
    _generateQuestion();
  }

  void _generateQuestion() {
    final random = Random();
    String currentOp =
        widget.level.operations[random.nextInt(widget.level.operations.length)];
    currentCountingIcon = countingIcons[random.nextInt(countingIcons.length)];

    if (currentOp == 'count') {
      correctAnswer = random.nextInt(widget.level.maxNumber) + 1;
      num1 = correctAnswer;
      num2 = 0;
    } else {
      num1 = random.nextInt(widget.level.maxNumber) + 1;
      num2 = random.nextInt(widget.level.maxNumber) + 1;
      switch (currentOp) {
        case '+':
          correctAnswer = num1 + num2;
          break;
        case '-':
          if (num1 < num2) {
            int temp = num1;
            num1 = num2;
            num2 = temp;
          }
          correctAnswer = num1 - num2;
          break;
        case '*':
          int limit = widget.level.difficulty == 'Very Hard' ? 12 : 10;
          num1 = random.nextInt(limit) + 1;
          num2 = random.nextInt(limit) + 1;
          correctAnswer = num1 * num2;
          break;
        case '/':
          int limit = widget.level.difficulty == 'Very Hard' ? 12 : 10;
          int temp1 = random.nextInt(limit) + 1;
          int temp2 = random.nextInt(limit) + 1;
          num1 = temp1 * temp2;
          num2 = temp1;
          correctAnswer = temp2;
          break;
      }
    }
    setState(() {
      operation = currentOp;
      currentInput = "";
      isWrong = false;
      isCorrect = false;
    });
  }

  void _onNumPadTap(String value) {
    HapticFeedback.lightImpact();
    if (value == "DEL") {
      if (currentInput.isNotEmpty)
        setState(
          () =>
              currentInput = currentInput.substring(0, currentInput.length - 1),
        );
    } else if (value == "OK") {
      _checkAnswer();
    } else {
      if (currentInput.length < 3) setState(() => currentInput += value);
    }
  }

  Future<void> _checkAnswer() async {
    if (currentInput.isEmpty) return;
    if (int.parse(currentInput) == correctAnswer) {
      AudioService.playCorrect();
      setState(() {
        isCorrect = true;
        currentScore++;
      });
      if (currentScore >= widget.level.goal) {
        await Future.delayed(const Duration(milliseconds: 500));
        _finishGame();
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
        _generateQuestion();
      }
    } else {
      AudioService.playWrong();
      HapticFeedback.vibrate();
      setState(() {
        isWrong = true;
        currentInput = "";
      });
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => isWrong = false);
    }
  }

  Future<void> _finishGame() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      int earnedXp = widget.level.xpReward;
      int earnedTime = widget.level.timeReward;

      // ⏱️ محاسبه زمان واقعی بازی ریاضی
      int actualSeconds = DateTime.now().difference(_gameStartTime!).inSeconds;
      int actualMinutes = (actualSeconds / 60).ceil();
      if (actualMinutes < 1) actualMinutes = 1;

      if (AppState.activeChildId.isNotEmpty) {
        await FirebaseFirestore.instance;
        // ... (کدهای آپدیت timeBalance همون قبلی باشه) ...

        // 🌟 ثبت زمان واقعی با اسم math
        ProgressService.logActivity(
          xpEarned: earnedXp,
          playedMinutes: actualMinutes,
          activityName: 'math',
        );
      }

      AudioService.playReward();

      if (mounted) {
        Navigator.pop(context); // بستن لودینگ
        _showProRewardPopup(earnedXp, earnedTime);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("Error: $e");
    }
  }

  void _showProRewardPopup(int xp, int time) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, a1, a2, child) {
        return Transform.scale(
          scale: Curves.elasticOut.transform(a1.value),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: widget.level.color.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.level.color.withOpacity(0.3),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("🏆", style: TextStyle(fontSize: 70)),
                      const SizedBox(height: 10),
                      Text(
                        "Quest Complete!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.level.color,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "You did an amazing job! You earned:",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 25),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  color: Colors.orangeAccent,
                                  size: 35,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "+$xp XP",
                                  style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white24,
                            ),
                            Column(
                              children: [
                                const Icon(
                                  Icons.timer_rounded,
                                  color: Colors.lightBlueAccent,
                                  size: 35,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "+$time Min",
                                  style: const TextStyle(
                                    color: Colors.lightBlueAccent,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.level.color,
                                widget.level.color.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: widget.level.color.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Awesome!",
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            top: -50,
            left: isCorrect ? 0 : -50,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: _glowColor.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _glowColor.withOpacity(0.3),
                    blurRadius: 120,
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            bottom: -50,
            right: isWrong ? 0 : -50,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: _glowColor.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _glowColor.withOpacity(0.3),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // هدر
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.level.title,
                          style: TextStyle(
                            color: widget.level.color,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // نوار پیشرفت
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Container(
                                height: 12,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                height: 12,
                                width:
                                    MediaQuery.of(context).size.width *
                                    (currentScore / widget.level.goal),
                                decoration: BoxDecoration(
                                  color: widget.level.color,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.level.color.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "$currentScore / ${widget.level.goal}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // 👈 راه‌حل اصلی: باکس سوال داخل Expanded و Scroll قرار گرفت تا ارور Overflow نده
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            isCorrect || isWrong ? 0.15 : 0.05,
                          ),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: _glowColor.withOpacity(0.5),
                            width: isCorrect || isWrong ? 4 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _glowColor.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: operation == 'count'
                                ? _buildProVisualQuestion()
                                : _buildProEquationQuestion(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // کیبورد فضایی بهینه‌شده
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24).withOpacity(0.8),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (var row in [
                        ['1', '2', '3'],
                        ['4', '5', '6'],
                        ['7', '8', '9'],
                        ['DEL', '0', 'OK'],
                      ])
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: row
                              .map((btn) => _buildProNumButton(btn))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProVisualQuestion() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "How many?",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(
            correctAnswer,
            (index) =>
                Text(currentCountingIcon, style: const TextStyle(fontSize: 45)),
          ).toList(),
        ),
        const SizedBox(height: 25),
        _buildAnswerBox(),
      ],
    );
  }

  Widget _buildProEquationQuestion() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "$num1 $operation $num2 = ",
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        _buildAnswerBox(),
      ],
    );
  }

  Widget _buildAnswerBox() {
    return Container(
      width: 80,
      height: 65,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white38, width: 2),
      ),
      child: Text(
        currentInput.isEmpty ? "?" : currentInput,
        style: TextStyle(
          fontSize: 35,
          fontWeight: FontWeight.w900,
          color: currentInput.isEmpty ? Colors.white38 : _glowColor,
        ),
      ),
    );
  }

  // 👈 دکمه‌ها کمی کوچک‌تر شدن تا روی مرورگر و موبایل‌های کوچک بیرون نزنن
  Widget _buildProNumButton(String text) {
    bool isAction = text == 'DEL' || text == 'OK';
    Color btnColor = Colors.white.withOpacity(0.1);
    Color textColor = Colors.white;

    if (text == 'OK') {
      btnColor = widget.level.color;
      textColor = Colors.white;
    } else if (text == 'DEL') {
      btnColor = Colors.redAccent.withOpacity(0.2);
      textColor = Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10), // فاصله کمتر شد
      child: GestureDetector(
        onTap: () => _onNumPadTap(text),
        child: Container(
          width: 75,
          height: 60, // سایز کوچک‌تر شد
          decoration: BoxDecoration(
            color: btnColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAction && text != 'OK'
                  ? Colors.transparent
                  : Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: text == 'OK'
                ? [
                    BoxShadow(
                      color: widget.level.color.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isAction ? 18 : 26,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
