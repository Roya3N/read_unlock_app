import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 👈 اضافه شدن کش حرفه‌ای
import 'package:read_unlock_app/core/services/audio_service.dart';
import 'package:read_unlock_app/core/services/database_service.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:read_unlock_app/features/game/screens/quiz_screen.dart';
import '../controllers/reading_controller.dart'; // 👈 ایمپورت کنترلر
import 'package:read_unlock_app/core/utils/progress_service.dart';

class ReadingScreen extends StatefulWidget {
  final List<String> pages;
  final List<String> pageTexts;
  final String title;
  final String level;
  final List<Map<String, dynamic>> quiz;
  final int xpReward;
  final int timeReward;
  final List<String> vocabulary;

  const ReadingScreen({
    super.key,
    required this.pages,
    required this.pageTexts,
    required this.title,
    required this.level,
    required this.quiz,
    required this.xpReward,
    required this.timeReward,
    this.vocabulary = const [],
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final ReadingController _readingController = ReadingController();
  final PageController _pageController =
      PageController(); // 👈 کنترلر انیمیشن ورق زدن

  bool isButtonEnabled = false;
  int currentPageIndex = 0;

  Timer? _readingTimer;
  int _remainingSeconds =
      1; // 👈 زمان انتظار رو اینجا تنظیم می‌کنیم (مثلاً ۱۰ ثانیه)

  List<dynamic> _voices = [];
  Map? _currentVoice;

  late FlutterTts flutterTts;
  Set<int> answeredQuizIndices = {};
  bool isTextVisible = false;

  double _ttsRate = 0.45;
  double _ttsPitch = 1.2;

  // 🎨 رنگ‌های تم Pro
  final Color primaryGlow = const Color(0xFF8B5CF6);
  final Color accentNeon = const Color(0xFF4ADE80);
  final Color darkGlass = const Color(0xFF1E1E24).withOpacity(0.85);

  DateTime? _gameStartTime;

  @override
  void initState() {
    super.initState();
    _gameStartTime = DateTime.now();
    flutterTts = FlutterTts();
    _initTts(); // 👈 این متد رو الان پایین درست می‌کنیم
    startReadingDelay();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");

    try {
      // تلاش اول: دریافت صداها (به صورت متغیر عمومی)
      var result = await flutterTts.getVoices;

      // ترفند مخصوص وب: اگر مرورگر لیست رو خالی داد، ۱ ثانیه صبر می‌کنیم
      if (result == null || (result is List && result.isEmpty)) {
        debugPrint("⏳ Web browser is slow... waiting 1 second to fetch voices");
        await Future.delayed(const Duration(seconds: 1));
        result = await flutterTts.getVoices;
      }

      // چک می‌کنیم که حتماً یک لیست پر بهمون داده باشه
      if (result is List && result.isNotEmpty) {
        setState(() {
          // تبدیل ایمن و بدون ارور به لیست
          _voices = List<dynamic>.from(result);
          _currentVoice = _voices.first;
        });
        debugPrint("✅ Voices loaded successfully! Count: ${_voices.length}");
      } else {
        debugPrint("❌ Still empty. The browser might not support TTS voices.");
      }
    } catch (e) {
      debugPrint("❌ Error fetching voices: $e");
    }

    await flutterTts.setSpeechRate(_ttsRate);
    await flutterTts.setPitch(_ttsPitch);
  }

  // ۲. این متد برای وقتیه که کاربر اسلایدرها رو تغییر میده
  void _applyTtsSettings() {
    setState(() {
      flutterTts.setSpeechRate(_ttsRate);
      flutterTts.setPitch(_ttsPitch);
    });
  }

  @override
  void dispose() {
    _readingTimer?.cancel(); // 👈 این خط اضافه شد تا تایمر رو بکُشه
    flutterTts.stop();
    _pageController.dispose();
    super.dispose();
  }

  void startReadingDelay() {
    _readingTimer?.cancel(); // اگر تایمر قبلی فعاله، قطعش کن

    setState(() {
      isButtonEnabled = false;
      _remainingSeconds = 1; // هر بار که میره صفحه جدید، دوباره میشه ۱۰ ثانیه
    });

    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 1) {
          _remainingSeconds--; // هر یه ثانیه یکی کم کن
        } else {
          isButtonEnabled = true; // وقت تموم شد، دکمه رو روشن کن!
          timer.cancel();
        }
      });
    });
  }

  // ==========================================
  // 🎛️ دیالوگ تنظیمات صدا (نسخه کامل و متصل)
  // ==========================================
  void _showVoiceSettingsDialog() {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'VoiceSettings',
      barrierColor: Colors.black.withOpacity(0.6),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, a1, a2, child) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 👈 بخش منطقی (پیدا کردن ایندکس) دقیقاً اینجاست (قبل از ساختن UI)
            int? currentIndex;
            if (_currentVoice != null && _voices.isNotEmpty) {
              currentIndex = _voices.indexWhere(
                (v) =>
                    v['name'] == _currentVoice!['name'] &&
                    v['locale'] == _currentVoice!['locale'],
              );
              if (currentIndex == -1) currentIndex = null;
            }

            return Transform.scale(
              scale: Curves.easeOutBack.transform(a1.value),
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Voice Settings 🎙️",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 25),

                          // --- انتخاب کاراکتر (صدا) [نسخه Pro 💎] ---
                          Row(
                            children: [
                              Icon(
                                Icons.record_voice_over_rounded,
                                color: Colors.white.withOpacity(0.8),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Choose Character",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: currentIndex,
                                dropdownColor: const Color(0xFF2A2A35),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white54,
                                ),
                                isExpanded: true,
                                hint: const Text(
                                  "Loading Magic Voices...",
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                items: _voices.isEmpty
                                    ? null
                                    : List.generate(_voices.length, (index) {
                                        return DropdownMenuItem<int>(
                                          value: index,
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF8B5CF6,
                                                  ).withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.person_rounded,
                                                  size: 14,
                                                  color: Color(0xFF8B5CF6),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                "Magic Voice ${index + 1}",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                onChanged: (int? selectedIndex) {
                                  if (selectedIndex != null) {
                                    var selectedVoice = _voices[selectedIndex];
                                    setDialogState(
                                      () => _currentVoice = selectedVoice,
                                    );
                                    setState(
                                      () => _currentVoice = selectedVoice,
                                    );
                                    flutterTts.setVoice({
                                      "name": selectedVoice['name'],
                                      "locale": selectedVoice['locale'],
                                    });
                                    Future.delayed(
                                      const Duration(milliseconds: 150),
                                      () => flutterTts.speak("Voice activated"),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // --- اسلایدرها ---
                          Text(
                            "Reading Speed: ${(_ttsRate * 10).toStringAsFixed(0)}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Slider(
                            value: _ttsRate,
                            min: 0.1,
                            max: 1.0,
                            divisions: 9,
                            label: (_ttsRate * 10).toStringAsFixed(0),
                            activeColor: const Color(0xFF8B5CF6),
                            onChanged: (val) {
                              setDialogState(() => _ttsRate = val);
                              setState(() => _ttsRate = val);
                              _applyTtsSettings();
                            },
                          ),

                          Text(
                            "Voice Pitch: ${_ttsPitch.toStringAsFixed(1)}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Slider(
                            value: _ttsPitch,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            label: _ttsPitch.toStringAsFixed(1),
                            activeColor: const Color(0xFF4ADE80),
                            onChanged: (val) {
                              setDialogState(() => _ttsPitch = val);
                              setState(() => _ttsPitch = val);
                              _applyTtsSettings();
                            },
                          ),

                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                            ),
                            onPressed: () => flutterTts.speak(
                              "Hello! I am your magic narrator.",
                            ),
                            child: const Text(
                              "Test Voice",
                              style: TextStyle(color: Colors.white),
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
      },
    );
  }

  // ==========================================
  // ورق زدن با سیستم «آزمون هوشمند حین خواندن» 🧠
  // ==========================================
  void goNext() {
    flutterTts.stop();
    HapticFeedback.lightImpact();

    // 🔍 بررسی اینکه آیا برای صفحه فعلی سوالی تنظیم شده که جواب نداده باشه؟
    int? pendingQuizIndex;
    for (int i = 0; i < widget.quiz.length; i++) {
      // در دیتابیس باید برای هر سوال کلید 'page' داشته باشی (مثلاً page: 3 یعنی این سوال بعد از خوندن صفحه ۳ بیاد)
      final qPage = widget.quiz[i]['page'] ?? (currentPageIndex + 1);

      if (qPage == (currentPageIndex + 1) && !answeredQuizIndices.contains(i)) {
        pendingQuizIndex = i;
        break; // اولین سوالِ جواب داده نشده رو پیدا کردیم
      }
    }

    bool isLastPage = currentPageIndex == widget.pages.length - 1;

    if (pendingQuizIndex != null) {
      // 🛑 ایست! قبل از رفتن به صفحه بعد، باید سوال رو جواب بدی
      _showInlineQuizPopup(pendingQuizIndex, isFinish: isLastPage);
    } else {
      // ✅ مسیر آزاده! میریم صفحه بعد یا کتاب تموم می‌شه
      if (!isLastPage) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
        setState(() => isTextVisible = false);
        startReadingDelay();
      } else {
        _finishBookAndReward(); // همه سوالات رو جواب داده و رسیده به آخر
      }
    }
  }

  void goPrevious() {
    flutterTts.stop();
    HapticFeedback.lightImpact();
    if (currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      setState(() => isTextVisible = false);
      startReadingDelay();
    }
  }

  // ==========================================
  // 🧩 پاپ‌آپ شیشه‌ای کوییز در حین خواندن
  // ==========================================
  void _showInlineQuizPopup(int quizIndex, {required bool isFinish}) {
    final currentQuiz = widget.quiz[quizIndex];
    final question = currentQuiz['question'] ?? 'Question?';
    final correctAnswer = currentQuiz['answer'].toString().trim();
    final optionsRaw = currentQuiz['options'] as List<dynamic>? ?? [];
    final options = optionsRaw.map((e) => e.toString().trim()).toList();

    // صفحه‌ای که جواب سوال توش بوده (اگر غلط جواب داد برش می‌گردونیم اینجا)
    // فرض می‌کنیم صفحات از 1 شروع می‌شن، ولی ایندکس‌ها از 0 هستن
    final int targetPageToReread = (currentQuiz['page'] ?? 1) - 1;

    HapticFeedback.heavyImpact();

    showGeneralDialog(
      context: context,
      barrierDismissible: false, // کاربر نمی‌تونه با کلیک بیرون، فرار کنه!
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, a1, a2, child) {
        // متغیرهای وضعیت داخل پاپ‌آپ
        bool isProcessing = false;
        String? selectedOption;
        bool isCorrect = false;

        return StatefulBuilder(
          builder: (context, setPopupState) {
            return Transform.scale(
              scale: Curves.easeOutBack.transform(a1.value),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: primaryGlow.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGlow.withOpacity(0.2),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Pop Quiz! 🧠",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            question,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // نمایش گزینه‌ها با حروف A, B, C...
                          ...List.generate(options.length, (index) {
                            final option = options[index];
                            final letter = String.fromCharCode(
                              65 + index,
                            ); // A, B, C

                            bool isThisSelected = selectedOption == option;
                            Color btnColor = Colors.white.withOpacity(0.05);
                            Color borderColor = Colors.white.withOpacity(0.1);

                            if (selectedOption != null) {
                              if (isThisSelected) {
                                btnColor = isCorrect
                                    ? const Color(0xFF10B981).withOpacity(0.2)
                                    : const Color(0xFFEF4444).withOpacity(0.2);
                                borderColor = isCorrect
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444);
                              } else {
                                btnColor = Colors.transparent;
                                borderColor = Colors.white.withOpacity(0.02);
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: GestureDetector(
                                onTap: () {
                                  if (isProcessing || selectedOption != null)
                                    return;

                                  setPopupState(() {
                                    isProcessing = true;
                                    selectedOption = option;
                                    isCorrect = (option == correctAnswer);
                                  });

                                  if (isCorrect) {
                                    AudioService.playCorrect();
                                    answeredQuizIndices.add(
                                      quizIndex,
                                    ); // 👈 ثبت جواب درست

                                    Future.delayed(
                                      const Duration(milliseconds: 1200),
                                      () {
                                        if (context.mounted)
                                          Navigator.pop(context); // بستن پاپ‌آپ

                                        if (isFinish) {
                                          _finishBookAndReward();
                                        } else {
                                          // رفتن به صفحه بعدی با انیمیشن
                                          _pageController.nextPage(
                                            duration: const Duration(
                                              milliseconds: 500,
                                            ),
                                            curve: Curves.easeInOutCubic,
                                          );
                                          setState(() {
                                            currentPageIndex++;
                                            isTextVisible = false;
                                          });
                                          startReadingDelay();
                                        }
                                      },
                                    );
                                  } else {
                                    AudioService.playWrong();

                                    Future.delayed(
                                      const Duration(milliseconds: 1500),
                                      () {
                                        if (context.mounted)
                                          Navigator.pop(context);

                                        // 🚨 تنبیه مهربون: برگردوندن کاربر به صفحه‌ای که جواب توش بوده
                                        if (currentPageIndex !=
                                                targetPageToReread &&
                                            targetPageToReread >= 0) {
                                          _pageController.animateToPage(
                                            targetPageToReread,
                                            duration: const Duration(
                                              milliseconds: 800,
                                            ),
                                            curve: Curves.easeOutBack,
                                          );
                                          setState(() {
                                            currentPageIndex =
                                                targetPageToReread;
                                            isTextVisible = false;
                                          });

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Oops! Let's read this part again carefully. 🕵️‍♂️",
                                              ),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        }
                                        startReadingDelay();
                                      },
                                    );
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: btnColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: borderColor.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            letter,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  borderColor ==
                                                      Colors.white.withOpacity(
                                                        0.1,
                                                      )
                                                  ? Colors.white70
                                                  : borderColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: selectedOption == null
                                                ? Colors.white
                                                : (isThisSelected
                                                      ? borderColor
                                                      : Colors.white38),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 🎁 جایزه نهایی بعد از اتمام تمام صفحات و کوییزها
  // ==========================================
  Future<void> _finishBookAndReward() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
      ),
    );

    await _readingController.finalizeBookAndClaimRewards(
      correctQuizAnswers: answeredQuizIndices.length,
      totalQuizQuestions: widget.quiz.length,
    );

    if (mounted) Navigator.pop(context);

    try {
      // ۱. آپدیت زمانِ جایزه (Screen Time)
      await DatabaseService.addDailyTime(
        AppState.activeChildId,
        widget.timeReward,
      );

      // ۲. ذخیره کلمات جدید
      if (widget.vocabulary.isNotEmpty) {
        await DatabaseService.saveLearnedWords(
          AppState.activeChildId,
          widget.vocabulary,
        );
      }

      // ⏱️ محاسبه زمان واقعی خوندن کتاب
      int actualSeconds = DateTime.now().difference(_gameStartTime!).inSeconds;
      int actualMinutes = (actualSeconds / 60).ceil();
      if (actualMinutes < 1) actualMinutes = 1;

      // ۳. 🌟 جادوی مرکز فرماندهی: ثبت XP و پر کردن نمودار فعالیت امروز
      // فرض می‌کنیم خوندن هر کتاب به اندازه همون Time Reward دقیقه طول کشیده
      ProgressService.logActivity(
        xpEarned: widget.xpReward,
        playedMinutes: actualMinutes,
        activityName: 'reading',
      );
    } catch (_) {}

    await AudioService.playReward();
    HapticFeedback.heavyImpact();

    if (mounted) {
      _showQuestCompletePopup(xp: widget.xpReward, minutes: widget.timeReward);
    }
  }

  void _showQuestCompletePopup({required int xp, required int minutes}) {
    AudioService.playReward(); // پخش صدای جایزه
    HapticFeedback.heavyImpact(); // لرزش قوی گوشی

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, a1, a2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(a1.value),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2329), // تم تیره مشابه عکس
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.green.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🏆 آیکون جام
                  const Text("🏆", style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),

                  // متن تبریک
                  const Text(
                    "Quest Complete!",
                    style: TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "You did an amazing job! You earned:",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // 📊 باکس نمایش XP و Min
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // بخش XP
                        Column(
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: Colors.orangeAccent,
                              size: 35,
                            ),
                            const SizedBox(height: 8),
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
                        // خط جداکننده
                        Container(width: 1, height: 40, color: Colors.white24),
                        // بخش Minutes
                        Column(
                          children: [
                            const Icon(
                              Icons.timer_rounded,
                              color: Colors.lightBlueAccent,
                              size: 35,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "+$minutes Min",
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
                  const SizedBox(height: 32),

                  // دکمه Awesome
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // بستن پاپ‌آپ
                      Navigator.pop(context); // بازگشت به صفحه قبل
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "Awesome!",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
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

  @override
  Widget build(BuildContext context) {
    final totalPages = widget.pages.length;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // 🌌 پس‌زمینه فضایی/نئونی
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: primaryGlow.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryGlow.withOpacity(0.2),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: accentNeon.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentNeon.withOpacity(0.15),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 🛸 AppBar اختصاصی
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.settings_voice_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _showVoiceSettingsDialog,
                      ),
                    ],
                  ),
                ),

                // 📊 کنترل‌های بالای تصویر
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Page ${currentPageIndex + 1} of $totalPages',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      if (widget.pageTexts.isNotEmpty &&
                          currentPageIndex < widget.pageTexts.length)
                        // 👈 بخش دکمه Read Text
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              isTextVisible =
                                  !isTextVisible; // تغییر وضعیت نمایش
                            });
                            print(
                              "Text Visibility: $isTextVisible",
                            ); // برای تست توی کنسول
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isTextVisible
                                  ? primaryGlow.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isTextVisible
                                    ? primaryGlow
                                    : Colors.white24,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isTextVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isTextVisible ? "Hide Text" : "Read Text",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 🖼️ تصویر کتاب (با قابلیت ورق زدن و کش فوق‌سریع)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 15,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: PageView.builder(
                          controller: _pageController,
                          physics:
                              const NeverScrollableScrollPhysics(), // غیرفعال کردن سوایپ دستی تا کاربر نتونه تقلب کنه
                          onPageChanged: (index) {
                            setState(() => currentPageIndex = index);
                          },
                          itemCount: totalPages,
                          itemBuilder: (context, index) {
                            // 👈 استفاده از جادوی CachedNetworkImage برای لود سریع از Supabase
                            return CachedNetworkImage(
                              imageUrl: widget.pages[index],
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.white54,
                                      size: 50,
                                    ),
                                  ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // 📝 باکس کلمات (متد InteractiveText رو اینجا بذار)
                if (isTextVisible)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                    ).copyWith(bottom: 15),
                    child:
                        _buildInteractiveText(), // مطمئن شو این متد توی کدها هست
                  ),

                // 🚢 داک شناور پایین صفحه
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: darkGlass,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: LinearProgressIndicator(
                          value: (currentPageIndex + 1) / totalPages,
                          backgroundColor: Colors.white12,
                          color: primaryGlow,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: currentPageIndex > 0 ? goPrevious : null,
                            icon: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: currentPageIndex > 0
                                  ? Colors.white70
                                  : Colors.white24,
                            ),
                          ),
                          GestureDetector(
                            onTap: isButtonEnabled ? goNext : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isButtonEnabled
                                    ? accentNeon
                                    : Colors.white12,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isButtonEnabled
                                    ? [
                                        BoxShadow(
                                          color: accentNeon.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Text(
                                isButtonEnabled
                                    ? (currentPageIndex == totalPages - 1
                                          ? 'Finish 🎉'
                                          : 'Next ➡️')
                                    : 'Wait $_remainingSeconds s ⏳',
                                style: TextStyle(
                                  color: isButtonEnabled
                                      ? Colors.black87
                                      : Colors.white38,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildInteractiveText() {
    if (widget.pageTexts.isEmpty ||
        currentPageIndex >= widget.pageTexts.length) {
      return const SizedBox.shrink();
    }

    String currentText = widget.pageTexts[currentPageIndex];
    List<String> words = currentText.split(RegExp(r'\s+'));

    return ClipRRect(
      // 👈 برای اینکه بلر از لبه‌ها بیرون نزنه
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        // 👈 ویجت اصلی برای ایجاد حالت شیشه‌ای
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08), // رنگ سفید بسیار شفاف
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 5.0,
            runSpacing: 10.0,
            children: words.map((word) {
              String cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');

              return GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await flutterTts.speak(cleanWord);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    word,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
