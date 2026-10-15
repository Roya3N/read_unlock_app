import 'dart:async';
import 'dart:ui'; // برای Glassmorphism
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:read_unlock_app/core/services/audio_service.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'memory_hub_screen.dart';
import 'package:read_unlock_app/core/utils/progress_service.dart';

class MemoryGameScreen extends StatefulWidget {
  final MemoryLevel level;
  const MemoryGameScreen({super.key, required this.level});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  late List<String> items;
  late FlutterTts flutterTts;
  DateTime? _gameStartTime;

  List<bool> revealed = [];
  List<bool> matched = [];
  List<int> selectedIndexes = [];
  bool isProcessing = false;
  int moves = 0;

  @override
  void initState() {
    super.initState();
    _gameStartTime = DateTime.now();
    _initTts();
    _setupGame();
  }

  void _initTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setSpeechRate(0.45);
    flutterTts.setPitch(1.2);
  }

  void _setupGame() {
    List<String> pool = List.from(widget.level.itemSet)..shuffle();
    List<String> selectedItems = pool.take(widget.level.pairs).toList();
    items = [...selectedItems, ...selectedItems];
    items.shuffle();
    revealed = List.generate(items.length, (_) => false);
    matched = List.generate(items.length, (_) => false);
    moves = 0;
  }

  void onCardTap(int index) {
    if (isProcessing || revealed[index] || matched[index]) return;

    HapticFeedback.lightImpact();
    setState(() {
      revealed[index] = true;
      selectedIndexes.add(index);
    });

    if (RegExp(r'[a-zA-Z]').hasMatch(items[index]))
      flutterTts.speak(items[index]);

    if (selectedIndexes.length == 2) {
      setState(() => moves++);
      isProcessing = true;
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        checkMatch();
      });
    }
  }

  void checkMatch() {
    final first = selectedIndexes[0];
    final second = selectedIndexes[1];

    if (items[first] == items[second]) {
      AudioService.playCorrect();
      setState(() {
        matched[first] = true;
        matched[second] = true;
      });
      _checkGameOver();
    } else {
      AudioService.playWrong();
      HapticFeedback.vibrate();
      setState(() {
        revealed[first] = false;
        revealed[second] = false;
      });
    }

    selectedIndexes.clear();
    isProcessing = false;
  }

  void _checkGameOver() {
    if (!matched.contains(false)) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _finishGameAndReward();
      });
    }
  }

  Future<void> _finishGameAndReward() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      int earnedXp = widget.level.xpReward;
      int earnedTime = widget.level.timeReward;

      // ⏱️ محاسبه زمان واقعی بازی
      int actualSeconds = DateTime.now().difference(_gameStartTime!).inSeconds;
      int actualMinutes = (actualSeconds / 60).ceil();
      if (actualMinutes < 1) actualMinutes = 1; // حداقل ۱ دقیقه ثبت بشه

      if (AppState.activeChildId.isNotEmpty) {
        // آپدیت تایم بالانس (جایزه)
        await FirebaseFirestore.instance
            .collection('parents')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('children')
            .doc(AppState.activeChildId)
            .update({'timeBalance': FieldValue.increment(earnedTime)});
        AppState.timeBalance += earnedTime;

        // 🌟 ارسال زمان واقعی و اسم بازی به داشبورد
        ProgressService.logActivity(
          xpEarned: earnedXp,
          playedMinutes: actualMinutes,
          activityName: 'memory', // 👈 حتماً memory باشه
        );
      }

      AudioService.playReward();

      if (!mounted) return;
      Navigator.pop(context);
      _showProRewardPopup(earnedXp, earnedTime);
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  // 🏆 پاپ‌آپ جایزه نئونی
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
                      const Text("🎉", style: TextStyle(fontSize: 70)),
                      const SizedBox(height: 10),
                      Text(
                        "Memory Master!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.level.color,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Solved in $moves moves",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
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
      backgroundColor: const Color(0xFF1A1A2E), // 🌌 کهکشان تیره
      body: Stack(
        children: [
          // هاله‌های نورانی زنده
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: widget.level.color.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.level.color.withOpacity(0.3),
                    blurRadius: 120,
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

                // داشبورد امتیازات فضایی
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildProStatBox(
                        "Pairs",
                        "${matched.where((m) => m).length ~/ 2} / ${widget.level.pairs}",
                        widget.level.color,
                      ),
                      _buildProStatBox(
                        "Moves",
                        "$moves",
                        const Color(0xFFFBBF24),
                      ),
                    ],
                  ),
                ),

                // 🧮 شبکه کارت‌های نئونی شیشه‌ای
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          int totalCards = items.length;
                          bool isLandscape =
                              constraints.maxWidth > constraints.maxHeight;
                          int cols = isLandscape
                              ? (totalCards > 16
                                    ? 6
                                    : (totalCards > 12 ? 5 : 4))
                              : (totalCards > 16 ? 4 : 3);
                          int rows = (totalCards / cols).ceil();
                          double spacing = 12.0;

                          double itemWidth =
                              (constraints.maxWidth - (spacing * (cols - 1))) /
                              cols;
                          double itemHeight =
                              (constraints.maxHeight - (spacing * (rows - 1))) /
                              rows;
                          double aspectRatio = itemWidth / itemHeight;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: totalCards,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: spacing,
                                  mainAxisSpacing: spacing,
                                  childAspectRatio: aspectRatio,
                                ),
                            itemBuilder: (context, index) {
                              bool isVisible =
                                  revealed[index] || matched[index];
                              bool isWord = items[index].length > 2;

                              return GestureDetector(
                                onTap: () => onCardTap(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOutBack,
                                  decoration: BoxDecoration(
                                    color: matched[index]
                                        ? const Color(
                                            0xFF10B981,
                                          ).withOpacity(0.2)
                                        : (isVisible
                                              ? Colors.white.withOpacity(0.1)
                                              : widget.level.color.withOpacity(
                                                  0.2,
                                                )),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: matched[index]
                                          ? const Color(0xFF10B981)
                                          : (isVisible
                                                ? Colors.white.withOpacity(0.3)
                                                : widget.level.color
                                                      .withOpacity(0.5)),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      // 👈 FIX: No empty arrays. Keep radius constant, fade color.
                                      BoxShadow(
                                        color: matched[index]
                                            ? const Color(
                                                0xFF10B981,
                                              ).withOpacity(0.4)
                                            : Colors.transparent,
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: isVisible
                                      ? Text(
                                          items[index],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: isWord ? 18 : 38,
                                            fontWeight: FontWeight.w900,
                                            color: matched[index]
                                                ? const Color(0xFF34D399)
                                                : Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          '?',
                                          style: TextStyle(
                                            fontSize: 35,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white38,
                                          ),
                                        ),
                                ),
                              );
                            },
                          );
                        },
                      ),
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

  Widget _buildProStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
