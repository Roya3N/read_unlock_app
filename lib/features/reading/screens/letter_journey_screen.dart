import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:read_unlock_app/core/utils/progress_service.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:read_unlock_app/features/engagement/screens/letter_tracing_screen.dart';
import 'package:read_unlock_app/features/reading/screens/activity_screen.dart';

class LetterJourneyScreen extends StatefulWidget {
  final String letter;

  const LetterJourneyScreen({super.key, required this.letter});

  @override
  State<LetterJourneyScreen> createState() => _LetterJourneyScreenState();
}

class _LetterJourneyScreenState extends State<LetterJourneyScreen> {
  int currentLevel =
      0; // 0: Tracing, 1: Activity, 2: Poster Unlocked, 3: Poster Claimed
  bool isLoading = true;

  final String supabaseBaseUrl =
      "https://esruowjvnottjknrkubg.supabase.co/storage/v1/object/public/images";

  String get currentTracingUrl =>
      "$supabaseBaseUrl/academy/3-4-toddlers/alphabet/tracing/${widget.letter.toLowerCase()}.png";

  String get currentActivityUrl =>
      "$supabaseBaseUrl/academy/3-4-toddlers/alphabet/activities/${widget.letter.toLowerCase()}.png";

  String get currentPosterUrl =>
      "$supabaseBaseUrl/academy/3-4-toddlers/alphabet/posters/${widget.letter.toLowerCase()}.png";

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  // 📡 خواندن اطلاعات از دیتابیس
  Future<void> _loadUserProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && AppState.activeChildId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('parents')
            .doc(user.uid)
            .collection('children')
            .doc(AppState.activeChildId)
            .collection('letters')
            .doc(widget.letter.toUpperCase())
            .get();

        if (doc.exists && doc.data() != null) {
          setState(() {
            currentLevel = doc.data()!['level'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading progress: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 💾 ذخیره مرحله جدید در دیتابیس (برای مراحل ۱ و ۲)
  Future<void> _completeStage(int stageCompleted) async {
    if (currentLevel == stageCompleted) {
      setState(() {
        currentLevel++;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && AppState.activeChildId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('parents')
              .doc(user.uid)
              .collection('children')
              .doc(AppState.activeChildId)
              .collection('letters')
              .doc(widget.letter.toUpperCase())
              .set({
                'level': currentLevel,
                'lastUpdated': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint("Error saving progress: $e");
      }

      if (!mounted) return;

      // ⭐️ جادوی جدید: اگه Brain Activity (مرحله 1) تموم شد، بلافاصله پاپ‌آپ جایزه رو نشون بده!
      if (stageCompleted == 1) {
        _claimMegaReward();
      } else {
        // 🟢 برای مرحله Tracing همون پیغام سبز رنگ رو نشون میده که بره مرحله بعد
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.auto_awesome, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Level Up! Next stage unlocked!",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      }
    }
  }

  Future<void> _claimMegaReward() async {
    if (currentLevel >= 3) {
      _showFullPosterDialog(showCelebration: false);
      return;
    }

    int bigXp = 50;
    int bigTime = 10;
    int timeSpent =
        5; // ⏱️ فرض می‌کنیم کل پروسه نقاشی و بازی حدود ۵ دقیقه طول کشیده

    _showProRewardPopup(bigXp + 2, bigTime);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && AppState.activeChildId.isNotEmpty) {
        // ۱. آپدیت زمان (Time Balance) و باز کردن کارت توی آلبوم 🃏
        await FirebaseFirestore.instance
            .collection('parents')
            .doc(user.uid)
            .collection('children')
            .doc(AppState.activeChildId)
            .update({
              'timeBalance': FieldValue.increment(bigTime),
              'unlockedCards': FieldValue.arrayUnion([
                widget.letter.toUpperCase(),
              ]),
            });

        AppState.timeBalance += bigTime;
        await AppState.save();

        // ۲. 🌟 ارسال XP و زمان بازی به مرکز فرماندهی برای نمودار داشبورد
        ProgressService.logActivity(xpEarned: bigXp, playedMinutes: timeSpent);

        if (mounted) {
          setState(() => currentLevel = 3);
        }

        // ۳. آپدیت لول حرف تا دیگه جایزه تکراری نده
        await FirebaseFirestore.instance
            .collection('parents')
            .doc(user.uid)
            .collection('children')
            .doc(AppState.activeChildId)
            .collection('letters')
            .doc(widget.letter.toUpperCase())
            .set({
              'level': 3,
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error claiming mega reward: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
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
        title: Text(
          "Journey of '${widget.letter}'",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
            )
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // ⭐️ مرحله ۱: نقاشی
                    _buildJourneyCard(
                      title: "1. Magic Tracing",
                      subtitle: "Learn how to write!",
                      icon: "✏️",
                      color: const Color(0xFF3B82F6),
                      isLocked: false,
                      isCompleted:
                          currentLevel >
                          0, // اگر لول از 0 بیشتر باشه خط می‌خوره
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LetterTracingScreen(
                              letter: widget.letter,
                              tracingUrl: currentTracingUrl,
                              // ⭐️ جادوی Callback اینجاست! فقط وقتی انجام شد خط بکش
                              onComplete: () => _completeStage(0),
                            ),
                          ),
                        );
                      },
                    ).animate().fade(delay: 100.ms).slideX(begin: -0.2),

                    _buildConnectorText(currentLevel >= 1),

                    // ⭐️ مرحله ۲: کاربرگ فعالیت
                    _buildJourneyCard(
                      title: "2. Brain Activity",
                      subtitle: "Find the hidden letters!",
                      icon: "🧩",
                      color: const Color(0xFFF59E0B),
                      isLocked: currentLevel < 1,
                      isCompleted:
                          currentLevel >
                          1, // اگر لول از 1 بیشتر باشه خط می‌خوره
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActivityScreen(
                              letter: widget.letter,
                              imageUrl: currentActivityUrl,
                              // ⭐️ جادوی Callback
                              onComplete: () => _completeStage(1),
                            ),
                          ),
                        );
                      },
                    ).animate().fade(delay: 300.ms).slideX(begin: 0.2),

                    _buildConnectorText(currentLevel >= 2),

                    // ⭐️ مرحله ۳: پوستر جادویی نهایی
                    _buildRewardCard()
                        .animate()
                        .fade(delay: 500.ms)
                        .scale(curve: Curves.easeOutBack),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  // ==========================================
  // ویجت‌های کمکی
  // ==========================================

  Widget _buildConnectorText(bool isUnlocked) {
    return Container(
      height: 40,
      width: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFF4ADE80) : Colors.white12,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: const Color(0xFF4ADE80).withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard({
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required bool isLocked,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isLocked) {
          onTap();
        } else {
          HapticFeedback.vibrate();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFF1E1E24) : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF4ADE80)
                : (isLocked ? Colors.white10 : color.withOpacity(0.5)),
            width: isCompleted ? 3 : 2,
          ),
          boxShadow: [
            if (!isLocked && !isCompleted)
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 65,
              width: 65,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF4ADE80).withOpacity(0.2)
                    : (isLocked ? Colors.white10 : color.withOpacity(0.2)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF4ADE80),
                        size: 35,
                      )
                    : (isLocked
                          ? const Icon(
                              Icons.lock_rounded,
                              color: Colors.white38,
                              size: 28,
                            )
                          : Text(icon, style: const TextStyle(fontSize: 32))),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isLocked ? Colors.white38 : Colors.white,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: const Color(0xFF4ADE80),
                      decorationThickness: 2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isLocked ? Colors.white24 : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard() {
    bool isLocked = currentLevel < 2;

    return GestureDetector(
      onTap: () {
        if (!isLocked) {
          HapticFeedback.heavyImpact();
          _claimMegaReward(); // ⭐️ فراخوانی سیستم جایزه بزرگ
        } else {
          HapticFeedback.vibrate();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        height: 220,
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFF1E1E24) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isLocked ? Colors.white10 : const Color(0xFFFBBF24),
            width: isLocked ? 2 : 4,
          ),
          boxShadow: [
            if (!isLocked)
              BoxShadow(
                color: const Color(0xFFFBBF24).withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: isLocked
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.lock_rounded, color: Colors.white24, size: 60),
                    SizedBox(height: 15),
                    Text(
                      "Complete previous steps\nto unlock the poster!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: currentPosterUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.white12,
                        child: const Icon(
                          Icons.image_not_supported_rounded,
                          color: Colors.white54,
                          size: 50,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 25,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          const Text(
                                "🎉 UNLOCKED! 🎉",
                                style: TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .shimmer(duration: 2.seconds),
                          const SizedBox(height: 8),
                          Text(
                            currentLevel >= 3
                                ? "Tap to view Magic Poster"
                                : "Tap to Claim Big Reward! 🎁",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showFullPosterDialog({required bool showCelebration}) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      barrierDismissible: true,
      barrierLabel: "Poster",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showCelebration)
                  const Text(
                        "+50 XP & +10 Mins! 🏆",
                        style: TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                      .animate()
                      .slideY(begin: 1, end: 0)
                      .scale(delay: 200.ms, curve: Curves.elasticOut),

                const SizedBox(height: 20),

                Flexible(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: CachedNetworkImage(
                        imageUrl: currentPosterUrl,
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: MediaQuery.of(context).size.height * 0.7,
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(
                              color: Colors.orangeAccent,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProRewardPopup(int xp, int time) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, a1, a2, child) {
        return Transform.scale(
          scale: Curves.elasticOut.transform(a1.value),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "🎉",
                    style: TextStyle(fontSize: 40),
                  ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 10),
                  const Text(
                    "New Card Unlocked!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ⭐️ نمایش کارت جایزه که تازه باز شده
                  ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          height: 220,
                          width: 160,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: CachedNetworkImage(
                            imageUrl:
                                currentPosterUrl, // ⭐️ استفاده از متغیر کلاس
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                widget.letter,
                                style: const TextStyle(
                                  fontSize: 50,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .shimmer(duration: 2.seconds, color: Colors.white24)
                      .slideY(begin: 0.2),

                  const SizedBox(height: 20),
                  // ⭐️ نمایش جوایز (هم XP و هم زمان)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- بخش نمایش XP ---
                      const Icon(
                        Icons.stars_rounded,
                        color: Colors.orangeAccent,
                        size: 30,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "+$xp XP",
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 20), // فاصله بین سکه و زمان
                      // --- بخش نمایش زمان (دقیقه) ---
                      const Icon(
                        Icons.timer_rounded,
                        color: Colors.lightBlueAccent,
                        size: 30,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "+$time Mins",
                        style: const TextStyle(
                          color: Colors.lightBlueAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // بستن پاپ‌آپ
                        Navigator.pop(context); // برگشتن به منوی اصلی
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "Awesome!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
