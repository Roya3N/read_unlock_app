import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:intl/intl.dart';
import 'package:read_unlock_app/core/utils/progress_service.dart';

class LetterHunterScreen extends StatefulWidget {
  const LetterHunterScreen({super.key});

  @override
  State<LetterHunterScreen> createState() => _LetterHunterScreenState();
}

class _LetterHunterScreenState extends State<LetterHunterScreen> {
  int score = 0;
  int timeLeft = 30;
  int level = 1;
  int poppedInCurrentLevel = 0;
  int combo = 0;
  int maxCombo = 0;
  int personalBestCombo = 0;
  String currentTarget = 'A';

  Timer? gameTimer;
  Timer? spawnTimer;

  final Random random = Random();
  final List<BalloonData> balloons = [];
  final List<FloatingPointData> floatingPoints = []; // 💬 اعداد معلق
  final List<String> alphabet = List.generate(
    26,
    (i) => String.fromCharCode(65 + i),
  );

  DateTime? _gameStartTime;

  @override
  void initState() {
    super.initState();
    _gameStartTime = DateTime.now();
    _fetchPersonalBest(); // 🌟 اضافه کردن این خط برای گرفتن رکورد به محض ورود
    _pickNewTarget();
    _startGame();
  }

  // 🌟 این تابع رو دقیقاً زیر initState اضافه کن:
  Future<void> _fetchPersonalBest() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && AppState.activeChildId.isNotEmpty) {
        final docSnap = await FirebaseFirestore.instance
            .collection('parents')
            .doc(user.uid)
            .collection('children')
            .doc(AppState.activeChildId)
            .get();

        if (docSnap.exists) {
          final data = docSnap.data();
          if (data != null &&
              data.containsKey('records') &&
              data['records']['hunter'] != null) {
            if (mounted) {
              setState(() {
                // رکورد رو از دیتابیس می‌کشیم بیرون
                personalBestCombo = data['records']['hunter']['maxCombo'] ?? 0;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching record: $e");
    }
  }

  void _pickNewTarget() {
    String newLetter = currentTarget;
    while (newLetter == currentTarget) {
      newLetter = alphabet[random.nextInt(alphabet.length)];
    }
    setState(() => currentTarget = newLetter);
  }

  void _startGame() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        _endGame();
      }
    });

    spawnTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      _spawnBalloon();
    });
  }

  void _spawnBalloon() {
    if (!mounted) return;
    balloons.removeWhere((b) => b.isFinished);
    floatingPoints.removeWhere((fp) => fp.isFinished); // پاکسازی اعداد قدیمی

    // 🌟 10% شانس برای اومدن بالون طلایی (زمان)
    bool isGolden = random.nextDouble() > 0.90;

    bool isTarget = random.nextDouble() > 0.4;
    String letter = isGolden
        ? "⏳"
        : (isTarget
              ? currentTarget
              : alphabet[random.nextInt(alphabet.length)]);
    if (!isTarget && letter == currentTarget) {
      letter = currentTarget == 'Z' ? 'A' : 'Z';
    }

    List<Color> colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
    ];
    int baseSpeed = max(3, 7 - (level ~/ 2));

    setState(() {
      balloons.add(
        BalloonData(
          id:
              DateTime.now().millisecondsSinceEpoch.toString() +
              random.nextInt(1000).toString(),
          letter: letter,
          color: isGolden
              ? Colors.amber
              : colors[random.nextInt(colors.length)],
          leftPosition: random.nextDouble() * 0.75 + 0.05,
          speed: random.nextInt(3) + baseSpeed,
          isGolden: isGolden,
        ),
      );
    });
  }

  void _popBalloon(BalloonData balloon) {
    if (balloon.isPopped) return;

    if (balloon.letter == currentTarget || balloon.isGolden) {
      // 🎯 درست زد!
      HapticFeedback.heavyImpact();

      setState(() {
        balloon.isPopped = true;

        if (balloon.isGolden) {
          timeLeft += 2; // 👈 جایزه بالن طلایی شد ۲ ثانیه (قبلاً ۵ بود)
          if (timeLeft > 30)
            timeLeft = 30; // 🛑 سقف زمان: نذار از ۳۰ ثانیه بیشتر بشه!
          _showFloatingText("+2s", balloon.leftPosition);
        } else {
          combo++;
          if (combo > maxCombo) maxCombo = combo;

          int pointsGained = 5 * min(combo, 5); // حداکثر ضریب کمبو 5 هست
          score += pointsGained;
          poppedInCurrentLevel++;
          _showFloatingText("+$pointsGained", balloon.leftPosition);

          // 🌟 Level Up
          if (poppedInCurrentLevel >= 5) {
            level++;
            timeLeft += 3; // 👈 جایزه لول آپ شد ۳ ثانیه (قبلاً ۸ بود)
            if (timeLeft > 30) timeLeft = 30; // 🛑 سقف زمان برای لول آپ

            poppedInCurrentLevel = 0;
            _pickNewTarget();
          }
        }
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => balloon.isFinished = true);
      });
    } else {
      // ❌ اشتباه زد (کمبو صفر میشه)
      HapticFeedback.vibrate();
      setState(() => combo = 0);
    }
  }

  // 💬 ساخت عدد معلق
  void _showFloatingText(String text, double xPosition) {
    String id =
        DateTime.now().millisecondsSinceEpoch.toString() +
        random.nextInt(100).toString();
    setState(() {
      floatingPoints.add(FloatingPointData(id: id, text: text, x: xPosition));
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(
          () => floatingPoints.firstWhere((e) => e.id == id).isFinished = true,
        );
      }
    });
  }

  void _endGame() {
    gameTimer?.cancel();
    spawnTimer?.cancel();

    int earnedXp = score ~/ 10;
    int actualSeconds = DateTime.now().difference(_gameStartTime!).inSeconds;
    int actualMinutes = (actualSeconds / 60)
        .ceil(); // رند کردن به بالا (مثلاً ۷۰ ثانیه میشه ۲ دقیقه)

    if (actualMinutes < 1) actualMinutes = 1; // حداقل ۱ دقیقه ثبت بشه

    ProgressService.logActivity(
      xpEarned: earnedXp,
      playedMinutes: actualMinutes,
      activityName: 'hunter',
      achievedCombo: maxCombo, // 👈 اسم بازی رو حتماً بنویس!
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text(
          "⏰ Time's Up!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // اگه رکورد خودش رو شکست، بهش بگو!
            if (maxCombo > personalBestCombo && personalBestCombo > 0)
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  "🎉 NEW RECORD! 🎉",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ).animate().scale().shake(),

            // 🌟 مشکل دقیقاً اینجا بود! کدی که شرط داشت رو کلاً پاک کردیم و فقط maxCombo رو گذاشتیم
            Text(
              "Max Combo: x$maxCombo 🔥",
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Score: $score 🎈",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.orangeAccent),
                    const SizedBox(width: 8),
                    Text(
                      "+$earnedXp XP!",
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
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
              "Collect Reward!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    spawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D17),
      body: Stack(
        children: [
          // پس‌زمینه پویا
          Positioned.fill(
            child: CustomPaint(painter: StarryBackgroundPainter()),
          ),

          // 🌌 هدر بازی
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // کمبو
                  if (combo > 1)
                    Text(
                          "x$combo 🔥",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent,
                          ),
                        )
                        .animate(key: ValueKey(combo))
                        .scale(curve: Curves.elasticOut)
                        .shake(),
                  if (combo <= 1) const SizedBox(width: 60),

                  // حرف هدف
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6),
                        width: 2,
                      ),
                    ),
                    child:
                        Text(
                              "Find: $currentTarget",
                              key: ValueKey(currentTarget),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            )
                            .animate()
                            .scale(curve: Curves.elasticOut)
                            .shimmer(color: Colors.amber),
                  ),

                  // زمان
                  Text(
                    "$timeLeft",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: timeLeft <= 10 ? Colors.redAccent : Colors.white,
                    ),
                  ).animate(target: timeLeft <= 10 ? 1 : 0).shake(),
                ],
              ),
            ),
          ),

          if (personalBestCombo > 0)
            Positioned(
              top: 85, // کمی پایین‌تر از هدر
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text("🏆", style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      "Best: x$personalBestCombo",
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ).animate().fade().slideX(begin: -0.5, end: 0, duration: 600.ms),
            ),

          // امتیاز پس زمینه
          Center(
            child: Text(
              "$score",
              style: TextStyle(
                fontSize: 150,
                fontWeight: FontWeight.w900,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // 🎈 بالون‌ها با حرکت سینوسی (زیگزاگ)
          ...balloons.map((balloon) {
            if (balloon.isFinished) return const SizedBox.shrink();

            return TweenAnimationBuilder<double>(
              key: ValueKey(balloon.id),
              tween: Tween(begin: size.height, end: -150.0),
              duration: Duration(seconds: balloon.speed),
              builder: (context, value, child) {
                // فرمول حرکت سینوسی برای چپ و راست شدن بالون تو هوا
                double sway = sin(value / 50) * 30;

                return Positioned(
                  left: (size.width * balloon.leftPosition) + sway,
                  top: value,
                  child: GestureDetector(
                    onTapDown: (_) => _popBalloon(balloon),
                    child: balloon.isPopped
                        ? const Text("💥", style: TextStyle(fontSize: 80))
                              .animate()
                              .scale(
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1.5, 1.5),
                                duration: 200.ms,
                              )
                              .fadeOut()
                        : _buildBalloonWidget(balloon),
                  ),
                );
              },
            );
          }),

          // 💬 رندر اعداد معلق (مثلاً +10 یا +5s)
          ...floatingPoints.map((fp) {
            if (fp.isFinished) return const SizedBox.shrink();
            return Positioned(
              left: size.width * fp.x,
              bottom: size.height * 0.4, // از وسط صفحه میان بالا
              child:
                  Text(
                        fp.text,
                        style: const TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 10),
                          ],
                        ),
                      )
                      .animate()
                      .moveY(
                        begin: 0,
                        end: -100,
                        duration: 800.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeOut(delay: 400.ms),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBalloonWidget(BalloonData balloon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 95,
          decoration: BoxDecoration(
            color: balloon.color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(50),
              bottom: Radius.circular(35),
            ),
            boxShadow: [
              BoxShadow(
                color: balloon.color.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            gradient: RadialGradient(
              colors: [Colors.white.withOpacity(0.3), balloon.color],
              center: const Alignment(-0.3, -0.3),
              radius: 0.8,
            ),
          ),
          child: Center(
            child: balloon.isGolden
                ? const Icon(
                    Icons.hourglass_bottom_rounded,
                    color: Colors.white,
                    size: 40,
                  )
                : Text(
                    balloon.letter,
                    style: const TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 5)],
                    ),
                  ),
          ),
        ),
        CustomPaint(
          size: const Size(15, 10),
          painter: TrianglePainter(color: balloon.color),
        ),
        Container(width: 2, height: 40, color: Colors.white38),
      ],
    ).animate().scale(
      begin: const Offset(0, 0),
      curve: Curves.elasticOut,
      duration: 600.ms,
    );
  }
}

class BalloonData {
  final String id;
  final String letter;
  final Color color;
  final double leftPosition;
  final int speed;
  final bool isGolden;
  bool isPopped;
  bool isFinished;
  BalloonData({
    required this.id,
    required this.letter,
    required this.color,
    required this.leftPosition,
    required this.speed,
    this.isGolden = false,
    this.isPopped = false,
    this.isFinished = false,
  });
}

class FloatingPointData {
  final String id;
  final String text;
  final double x;
  bool isFinished;
  FloatingPointData({
    required this.id,
    required this.text,
    required this.x,
    this.isFinished = false,
  });
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    var path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarryBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.1);
    final random = Random(42);
    for (int i = 0; i < 80; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() * 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
