import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:read_unlock_app/core/utils/progress_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WordScrambleScreen extends StatefulWidget {
  const WordScrambleScreen({super.key});

  @override
  State<WordScrambleScreen> createState() => _WordScrambleScreenState();
}

class _WordScrambleScreenState extends State<WordScrambleScreen> {
  // 📚 بانک کلمات جادویی به همراه راهنما (Hint)
  List<Map<String, String>> _wordBank = [];
  bool isLoading = true; // ⏳ برای نشون دادن لودینگ

  late String targetWord;
  late String targetHint; // 🌟 متغیر جدید برای نگه داشتن راهنما

  // گرید بازی: ۶ ردیف و هر ردیف ۵ ستون
  List<List<String>> guesses = List.generate(6, (_) => List.filled(5, ''));
  List<List<Color>> cellColors = List.generate(
    6,
    (_) => List.filled(5, Colors.transparent),
  );

  int currentRow = 0;
  int currentCol = 0;

  Map<String, Color> keyboardColors = {};

  int score = 0;
  int combo = 0;
  int totalSeconds = 0;
  Timer? _timer;

  final Color greenColor = const Color(0xFF4ADE80);
  final Color yellowColor = const Color(0xFFFBBF24);
  final Color redColor = const Color(0xFFEF4444).withOpacity(0.8);

  @override
  void initState() {
    super.initState();
    _startTimer();
    _fetchWordsFromFirebase(); // 🌟 اول کلمات رو دانلود می‌کنیم
  }

  // 📥 متد جدید برای دریافت از فایربیس
  Future<void> _fetchWordsFromFirebase() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('game_settings')
          .doc('scramble_words')
          .get();

      if (doc.exists && doc.data() != null) {
        List<dynamic> fetchedWords = doc.data()!['words'];
        if (mounted) {
          setState(() {
            // کلمات رو می‌گیریم و مطمئن میشیم همه حروف بزرگ هستن
            _wordBank = List<Map<String, String>>.from(
              fetchedWords.map(
                (e) => {
                  'word': e['word'].toString().toUpperCase(),
                  'hint': e['hint'].toString(),
                },
              ),
            );
            _wordBank.shuffle();
            isLoading = false;
          });
          _startNewWord(); // 🌟 حالا که دانلود شد، بازی رو شروع کن
        }
      } else {
        _useFallbackWords(); // اگه فایربیس خالی بود
      }
    } catch (e) {
      _useFallbackWords(); // اگه اینترنت قطع بود
    }
  }

  // 🛡️ لیست زاپاس (برای وقتایی که اینترنت نیست)
  void _useFallbackWords() {
    if (mounted) {
      setState(() {
        _wordBank = [
          {
            'word': 'MAGIC',
            'hint': 'Supernatural power to make impossible things happen 🎩',
          },
          {'word': 'SPELL', 'hint': 'Words used to make magic work 📜'},
          {'word': 'GHOST', 'hint': 'A spooky spirit that says Boo! 👻'},
        ];
        _wordBank.shuffle();
        isLoading = false;
      });
      _startNewWord();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // فقط در صورتی زمان رو ببر بالا که لودینگ تموم شده باشه
      if (mounted && !isLoading) setState(() => totalSeconds++);
    });
  }

  void _startNewWord() {
    if (_wordBank.isEmpty) return; // 🛑 جلوگیری از ارور اگه لیست خالی بود

    setState(() {
      var currentItem = _wordBank.first;
      targetWord = currentItem['word']!;
      targetHint = currentItem['hint']!; // 🌟 استخراج راهنما

      _wordBank.removeAt(0);
      _wordBank.add(currentItem);

      guesses = List.generate(6, (_) => List.filled(5, ''));
      cellColors = List.generate(6, (_) => List.filled(5, Colors.transparent));
      keyboardColors.clear();
      currentRow = 0;
      currentCol = 0;
    });
  }

  void _onKeyTapped(String letter) {
    if (currentRow > 5) return;

    if (letter == 'DEL') {
      if (currentCol > 0) {
        HapticFeedback.lightImpact();
        setState(() {
          currentCol--;
          guesses[currentRow][currentCol] = '';
        });
      }
    } else if (letter == 'ENTER') {
      if (currentCol == 5) {
        _checkGuess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough letters!'),
            duration: Duration(milliseconds: 1000),
          ),
        );
      }
    } else {
      if (currentCol < 5) {
        HapticFeedback.selectionClick();
        setState(() {
          guesses[currentRow][currentCol] = letter;
          currentCol++;
        });
      }
    }
  }

  void _checkGuess() {
    String guess = guesses[currentRow].join('');
    List<Color> rowColors = List.filled(5, redColor);
    List<bool> targetUsed = List.filled(5, false);

    for (int i = 0; i < 5; i++) {
      if (guess[i] == targetWord[i]) {
        rowColors[i] = greenColor;
        keyboardColors[guess[i]] = greenColor;
        targetUsed[i] = true;
      }
    }

    for (int i = 0; i < 5; i++) {
      if (rowColors[i] == greenColor) continue;

      bool foundYellow = false;
      for (int j = 0; j < 5; j++) {
        if (!targetUsed[j] && guess[i] == targetWord[j]) {
          rowColors[i] = yellowColor;
          if (keyboardColors[guess[i]] != greenColor) {
            keyboardColors[guess[i]] = yellowColor;
          }
          targetUsed[j] = true;
          foundYellow = true;
          break;
        }
      }

      if (!foundYellow &&
          keyboardColors[guess[i]] != greenColor &&
          keyboardColors[guess[i]] != yellowColor) {
        keyboardColors[guess[i]] = redColor;
      }
    }

    setState(() {
      cellColors[currentRow] = rowColors;
    });

    if (guess == targetWord) {
      _handleWin();
    } else if (currentRow == 5) {
      _handleLoss();
    } else {
      setState(() {
        currentRow++;
        currentCol = 0;
      });
    }
  }

  void _handleWin() {
    HapticFeedback.heavyImpact();
    setState(() {
      combo++;
      score += (6 - currentRow) * 10;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "🎉 GENIUS!",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: greenColor,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          "You found '$targetWord' in ${currentRow + 1} tries!",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: () {
              Navigator.pop(context);
              _startNewWord();
            },
            child: const Text(
              "Next Word",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ).animate().scale(),
    );
  }

  void _handleLoss() {
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "💔 OOPS!",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          "The magic word was: $targetWord",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: () {
              Navigator.pop(context);
              _startNewWord();
            },
            child: const Text(
              "Try Another",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ).animate().shake(),
    );
  }

  void _endGameAndClaim() {
    _timer?.cancel();

    int actualMinutes = (totalSeconds / 60).ceil();
    if (actualMinutes < 1) actualMinutes = 1;

    int earnedXp = score ~/ 2;
    if (earnedXp > 50) earnedXp = 50;

    ProgressService.logActivity(
      xpEarned: earnedXp,
      playedMinutes: actualMinutes,
      activityName: 'scramble',
      achievedCombo: combo,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text(
          "🎓 Session Complete!",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Words Solved: $combo 🧠",
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Time: ${totalSeconds ~/ 60}m ${totalSeconds % 60}s ⏱️",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 15),
            if (earnedXp > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  "+$earnedXp XP!",
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ).animate().shimmer(),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              "Claim Reward!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ).animate().scale(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formatTime =
        "${(totalSeconds ~/ 60).toString().padLeft(2, '0')}:${(totalSeconds % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
          onPressed: _endGameAndClaim,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
            const SizedBox(width: 5),
            Text(
              formatTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                "Score: $score",
                style: const TextStyle(
                  color: Color(0xFF4ADE80),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              )
            : Column(
                children: [
                  // 🌟 بخش جدید: نمایش راهنمای کلمه (Hint)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("💡", style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              targetHint,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: -0.2),
                  ),

                  const SizedBox(height: 10),

                  // 🔲 گریدِ ۶x۵ بازی
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (row) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (col) {
                            String letter = guesses[row][col];
                            Color color = cellColors[row][col];
                            bool isActiveRow = row == currentRow;
                            bool hasLetter = letter.isNotEmpty;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.all(4),
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: color == Colors.transparent
                                    ? (hasLetter
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.transparent)
                                    : color,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: color != Colors.transparent
                                      ? color
                                      : (isActiveRow
                                            ? Colors.white54
                                            : Colors.white12),
                                  width: 2,
                                ),
                                boxShadow:
                                    isActiveRow && color == Colors.transparent
                                    ? [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.05),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  letter,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  ),

                  // ⌨️ کیبورد مجازی
                  _buildKeyboard(),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  // ساخت کیبوردِ QWERTY
  Widget _buildKeyboard() {
    List<List<String>> keys = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'DEL'],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((letter) {
                bool isSpecial = letter == 'ENTER' || letter == 'DEL';
                Color keyColor =
                    keyboardColors[letter] ?? Colors.white.withOpacity(0.15);
                bool isDeactivated = keyColor == redColor;

                return GestureDetector(
                  onTap: isDeactivated ? null : () => _onKeyTapped(letter),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isSpecial ? 65 : 32,
                    height: 45,
                    decoration: BoxDecoration(
                      color: keyColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: TextStyle(
                          color: isDeactivated ? Colors.white38 : Colors.white,
                          fontSize: isSpecial ? 12 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
