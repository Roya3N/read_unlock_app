import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:read_unlock_app/core/services/screen_time_service.dart';
import 'package:read_unlock_app/core/utils/screen_time_rules.dart';
import 'dart:ui';
import 'timer_screen.dart';

class TimeWalletScreen extends StatefulWidget {
  const TimeWalletScreen({super.key});

  @override
  State<TimeWalletScreen> createState() => _TimeWalletScreenState();
}

class _TimeWalletScreenState extends State<TimeWalletScreen> {
  double selectedMinutes = 15;
  bool isProcessing = false;

  // متغیرهای داینامیک بر اساس سن
  late int childAge;
  late Color primaryColor;
  late Color secondaryColor;
  late String titleText;
  late double maxTime;

  // Real usage today and the parent's daily limit (0 = no limit).
  int timeSpentToday = 0;
  int dailyLimit = 0;
  bool _loadingToday = true;

  int get _availableNow => ScreenTimeRules.availableNow(
    balance: AppState.timeBalance,
    dailyLimit: dailyLimit,
    usedToday: timeSpentToday,
  );

  Future<void> _loadToday() async {
    final today = await ScreenTimeService.loadToday();
    if (!mounted) return;
    setState(() {
      timeSpentToday = today.usedToday;
      dailyLimit = today.dailyLimit;
      _loadingToday = false;
      final cap = _availableNow < maxTime ? _availableNow : maxTime.toInt();
      if (selectedMinutes > cap) selectedMinutes = cap.toDouble();
    });
  }

  @override
  void initState() {
    super.initState();
    childAge = AppState.activeChildAge > 0 ? AppState.activeChildAge : 8;

    // تم‌های ظریف بر اساس سن
    if (childAge <= 4) {
      maxTime = 20;
      selectedMinutes = 5;
      primaryColor = const Color(0xFFF472B6);
      secondaryColor = const Color(0xFFFDA4AF);
      titleText = "Magic Playtime";
    } else if (childAge >= 10) {
      maxTime = 90;
      selectedMinutes = 20;
      primaryColor = const Color(0xFF10B981);
      secondaryColor = const Color(0xFF34D399);
      titleText = "System Access";
    } else {
      maxTime = 60;
      selectedMinutes = 15;
      primaryColor = const Color(0xFF3B82F6);
      secondaryColor = const Color(0xFF8B5CF6);
      titleText = "Time Wallet";
    }
    _loadToday();
  }

  Future<void> _startTimer() async {
    int minutes = selectedMinutes.toInt();
    if (_loadingToday || minutes <= 0 || minutes > _availableNow) return;

    setState(() => isProcessing = true);
    HapticFeedback.heavyImpact();

    // The server checks the balance and daily limit and takes the minutes.
    final result = await ScreenTimeService.start(minutes);

    if (!mounted) return;

    if (result.ok && result.sessionId != null && result.endsAt != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TimerScreen(
            minutes: minutes,
            sessionId: result.sessionId!,
            endsAt: result.endsAt!,
          ),
        ),
      );
    } else {
      setState(() => isProcessing = false);
      _showStartError(result);
      _loadToday();
    }
  }

  void _showStartError(ScreenSessionStart result) {
    final String message;
    switch (result.reason) {
      case 'daily_limit':
        final left = result.leftToday ?? 0;
        message = left > 0
            ? "Daily limit reached. Only $left min left today."
            : "Daily limit reached. No more screen time today.";
        break;
      case 'not_enough_minutes':
        message = "Not enough minutes. Read a book to earn more!";
        break;
      case 'session_running':
        message = "A playtime session is already running.";
        break;
      default:
        message = "Couldn't start the timer. Please try again.";
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int currentBalance = AppState.timeBalance;
    final bool hasEnoughTime =
        !_loadingToday &&
        selectedMinutes > 0 &&
        selectedMinutes.toInt() <= _availableNow;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B14), // تم بی‌نهایت تاریک و شیک
      body: Stack(
        children: [
          // 🌌 نورپردازی ملایم پس‌زمینه
          Positioned(
            top: -150,
            left: -100,
            child: _buildGlow(primaryColor, 400),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: _buildGlow(secondaryColor, 400),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 📊 کارت آمار روزانه (Daily Usage)
                        const Text(
                          "DAILY USAGE",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDailyUsageCard(currentBalance),

                        const SizedBox(height: 40),

                        // 🎚️ تنظیم زمان (Time Selector)
                        const Text(
                          "ALLOCATE TIME",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTimeSelectorCard(),

                        const SizedBox(height: 50),

                        // 🚀 دکمه تایید
                        _buildUnlockButton(hasEnoughTime),
                        const SizedBox(height: 30),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              titleText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // 📊 طراحی ظریف کارت آمار روزانه
  Widget _buildDailyUsageCard(int balance) {
    // With a daily limit, the ring shows used vs limit; otherwise used vs
    // what was available today (used + balance).
    final int ringTotal = dailyLimit > 0
        ? dailyLimit
        : balance + timeSpentToday;
    double progress = ringTotal > 0 ? timeSpentToday / ringTotal : 0;
    if (progress > 1) progress = 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Row(
            children: [
              // حلقه پیشرفت
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 6,
                      color: Colors.white.withOpacity(0.05),
                    ),
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        "${(progress * 100).toInt()}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // جزئیات آمار
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow("Available", "$balance min", primaryColor),
                    const SizedBox(height: 12),
                    _buildStatRow(
                      "Spent Today",
                      "$timeSpentToday min",
                      Colors.white54,
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow(
                      dailyLimit > 0 ? "Left Today" : "Daily Limit",
                      dailyLimit > 0 ? "$_availableNow min" : "None",
                      Colors.white38,
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

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // 🎚️ طراحی بسیار ظریف کارت تنظیم زمان
  Widget _buildTimeSelectorCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Column(
            children: [
              // عدد بزرگ زمان
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "${selectedMinutes.toInt()}",
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w300, // فونت نازک‌تر برای ظرافت
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "MIN",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // اسلایدر مینیمال
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4, // ترکِ بسیار نازک
                  activeTrackColor: primaryColor,
                  inactiveTrackColor: Colors.white.withOpacity(0.05),
                  thumbColor: Colors.white,
                  overlayColor: primaryColor.withOpacity(0.1),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                    elevation: 5,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 24,
                  ),
                ),
                child: Slider(
                  value: selectedMinutes,
                  min: 0,
                  max: maxTime,
                  divisions: maxTime.toInt() ~/ 5, // پرش‌های ۵ دقیقه‌ای
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => selectedMinutes = value);
                  },
                ),
              ),

              // لیبل‌های زیر اسلایدر
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "0",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "${maxTime.toInt()}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 12,
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

  String _blockedLabel() {
    if (_loadingToday) return "LOADING...";
    final limitLeft = dailyLimit > 0 ? dailyLimit - timeSpentToday : null;
    if (limitLeft != null && limitLeft <= 0) return "DAILY LIMIT REACHED";
    if (limitLeft != null && selectedMinutes.toInt() > limitLeft) {
      return "ONLY $limitLeft MIN LEFT TODAY";
    }
    return "INSUFFICIENT BALANCE";
  }

  // 🚀 دکمه تایید حرفه‌ای
  Widget _buildUnlockButton(bool hasEnoughTime) {
    return GestureDetector(
      onTap: hasEnoughTime && !isProcessing ? _startTimer : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: hasEnoughTime
              ? LinearGradient(colors: [primaryColor, secondaryColor])
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasEnoughTime
                ? Colors.transparent
                : Colors.white.withOpacity(0.1),
          ),
          boxShadow: hasEnoughTime
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  hasEnoughTime ? "CONFIRM" : _blockedLabel(),
                  style: TextStyle(
                    color: hasEnoughTime ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), // شفافیت بسیار کم برای ظرافت
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 150)],
      ),
    );
  }
}
