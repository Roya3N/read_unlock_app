import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // برای افکت‌های Glassmorphism

class ChildInsightsScreen extends StatefulWidget {
  final String childId;
  final Map<String, dynamic> childData;

  const ChildInsightsScreen({
    super.key,
    required this.childId,
    required this.childData,
  });

  @override
  State<ChildInsightsScreen> createState() => _ChildInsightsScreenState();
}

class _ChildInsightsScreenState extends State<ChildInsightsScreen> {
  List<Map<String, dynamic>> weekActivity = [];
  bool isLoadingChart = true;
  double maxChartValue = 60.0;
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // 🎨 رنگ‌های تم Pro و کودکانه
  final Color primaryNeon = const Color(0xFF8B5CF6);
  final Color accentPink = const Color(0xFFEC4899);
  final Color darkGalaxy = const Color(0xFF0F0F13);
  final Color glassCard = const Color(0xFF1E1E24).withOpacity(0.7);

  @override
  void initState() {
    super.initState();
    _fetchWeeklyActivity();
  }

  Future<void> _fetchWeeklyActivity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    List<Map<String, dynamic>> tempData = [];
    List<String> dateStrings = [];

    for (int i = 6; i >= 0; i--) {
      DateTime d = now.subtract(Duration(days: i));
      String dateStr = DateFormat('yyyy-MM-dd').format(d);
      String dayName = DateFormat('E').format(d).substring(0, 3);
      dateStrings.add(dateStr);
      // 🌟 اضافه کردن یه جیبِ خالی برای breakdown هر روز
      tempData.add({
        'day': dayName,
        'date': dateStr,
        'val': 0.0,
        'breakdown': <String, double>{},
      });
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .collection('children')
          .doc(widget.childId)
          .collection('daily_activity')
          .where('date', whereIn: dateStrings)
          .get();

      double maxVal = 0;

      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        String dDate = data['date'];
        int mins = data['minutes'] ?? 0;

        int index = tempData.indexWhere((element) => element['date'] == dDate);
        if (index != -1) {
          tempData[index]['val'] = mins.toDouble();
          if (mins > maxVal) maxVal = mins.toDouble();

          // 🌟 ذخیره ریزِ فعالیت‌ها فقط برای همین روز
          if (data.containsKey('breakdown')) {
            Map<String, dynamic> bd = data['breakdown'];
            Map<String, double> dayBd = {};
            bd.forEach((key, val) {
              dayBd[key] = (val as num).toDouble();
            });
            tempData[index]['breakdown'] = dayBd;
          }
        }
      }

      if (mounted) {
        setState(() {
          weekActivity = tempData;
          maxChartValue = maxVal > 60.0 ? maxVal : 60.0;
          isLoadingChart = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingChart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.childData['name'] ?? 'Explorer';
    final int xp = widget.childData['xp'] ?? 0;
    final int level = (xp ~/ 100) + 1;
    final int xpProgress = xp % 100;
    final int savedTime = widget.childData['timeBalance'] ?? 0;
    final List<dynamic> learnedWords = widget.childData['learnedWords'] ?? [];

    return Scaffold(
      backgroundColor: darkGalaxy, // تم کهکشان تاریک
      body: Stack(
        children: [
          // 🌌 هاله‌های نورانی کهکشان (فضای کودکانه)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: accentPink.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentPink.withOpacity(0.3),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
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
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          "$name's Journey 🚀",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // حفظ تعادل هدر
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ۱. کارت پیشرفت فضایی (Glassmorphism)
                        _buildProLevelCard(level, xpProgress, xp, savedTime),
                        const SizedBox(height: 35),

                        // ۲. نمودار فعالیت هفتگی
                        const Text(
                          "Activity This Week 📊",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 15),
                        isLoadingChart
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF8B5CF6),
                                ),
                              )
                            : _buildProActivityChart(),

                        const SizedBox(height: 30),

                        // بخش فوکوس (دیتای روز انتخاب شده)
                        if (!isLoadingChart) _buildActivityBreakdown(),

                        const SizedBox(height: 35),

                        // ۳. گنجینه کلمات یادگرفته شده
                        const Text(
                          "Vocabulary Gems 💎",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 15),
                        learnedWords.isEmpty
                            ? _buildProEmptyWordsState()
                            : _buildProWordsGrid(learnedWords),
                        const SizedBox(height: 40),
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

  // --- 🌟 بخش 1: کارت پیشرفت (شیشه‌ای و پفکی) ---
  Widget _buildProLevelCard(
    int level,
    int xpProgress,
    int totalXp,
    int savedTime,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: glassCard,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // حلقه لول (Level Ring)
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: xpProgress / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryNeon),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "LEVEL",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white54,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        "$level",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Container(
                width: 1.5,
                height: 80,
                color: Colors.white.withOpacity(0.1),
              ),

              // آمارها (Stats)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProMiniStat(
                    "Total XP",
                    "$totalXp",
                    Icons.stars_rounded,
                    const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 20),
                  _buildProMiniStat(
                    "Saved Time",
                    "$savedTime min",
                    Icons.timer_rounded,
                    const Color(0xFF4ADE80),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProMiniStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 📈 نمودار با قابلیت کلیک ---
  Widget _buildProActivityChart() {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      decoration: BoxDecoration(
        color: glassCard,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: weekActivity.map((data) {
          double rawPercent = data['val'] / maxChartValue;
          final double heightPercent = rawPercent.clamp(0.0, 1.0);
          final bool hasData = data['val'] > 0;
          final bool isSelected =
              data['date'] == selectedDate; // 🌟 آیا این روز انتخاب شده؟

          return GestureDetector(
            onTap: () {
              // 🌟 وقتی روی میله کلیک میشه، تاریخ انتخاب‌شده عوض میشه
              HapticFeedback.selectionClick();
              setState(() {
                selectedDate = data['date'];
              });
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasData)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      "${data['val'].toInt()}m",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? const Color(0xFF4ADE80)
                            : Colors.white70,
                      ),
                    ).animate().fade().slideY(begin: 0.5, end: 0),
                  ),

                Expanded(
                  child: Container(
                    width: 16,
                    alignment: Alignment.bottomCenter,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      width: 16,
                      height: hasData
                          ? (140 * heightPercent).clamp(10.0, 140.0)
                          : 0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSelected
                              ? [
                                  const Color(0xFF4ADE80),
                                  const Color(0xFF22C55E),
                                ]
                              : [
                                  const Color(0xFF3B82F6),
                                  const Color(0xFF2563EB),
                                ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: hasData && isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4ADE80,
                                  ).withOpacity(0.4),
                                  blurRadius: 10,
                                ),
                              ]
                            : [],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data['day'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.white38,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- 🎯 بخش کارت‌های تفکیک فعالیت ---
  Widget _buildActivityBreakdown() {
    // پیدا کردن دیتایِ روزِ انتخاب شده
    final selectedData = weekActivity.firstWhere(
      (e) => e['date'] == selectedDate,
      orElse: () => {'breakdown': <String, double>{}},
    );
    final Map<String, double> dayBreakdown = selectedData['breakdown'] ?? {};

    // تنظیمات ظاهر هر بازی
    final Map<String, Map<String, dynamic>> activityStyles = {
      'hunter': {
        'icon': '🎈',
        'name': 'Letter Hunter',
        'color': const Color(0xFF3B82F6),
      },
      'math': {
        'icon': '🧮',
        'name': 'Math Quest',
        'color': const Color(0xFF10B981),
      },
      'reading': {
        'icon': '📖',
        'name': 'Magic Reading',
        'color': const Color(0xFF8B5CF6),
      },
      'tracing': {
        'icon': '✏️',
        'name': 'Tracing',
        'color': const Color(0xFFF59E0B),
      },
      'memory': {
        'icon': '🧩',
        'name': 'Memory',
        'color': const Color(0xFFEC4899),
      },
      'homework': {
        'icon': '📝',
        'name': 'Homework',
        'color': const Color(0xFFF97316),
      },
    };

    String formattedDate = DateFormat(
      'EEEE, MMM d',
    ).format(DateTime.parse(selectedDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Focus Areas 🎯",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // 🌟 اگر اون روز بازی نکرده باشه، یه پیام قشنگ نشون میده
        if (dayBreakdown.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                "No activity recorded on this day. 🌱",
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: dayBreakdown.entries.map((entry) {
              var style =
                  activityStyles[entry.key] ??
                  {'icon': '🎮', 'name': entry.key, 'color': Colors.grey};

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: (style['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (style['color'] as Color).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(style['icon'], style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          style['name'],
                          style: TextStyle(
                            color: style['color'],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${entry.value.toInt()} min",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // --- 📖 بخش 3: کلمات (سنگ‌های کریستالی) ---
  Widget _buildProWordsGrid(List<dynamic> words) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: words.map((word) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A35).withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFFBBF24),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                word.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProEmptyWordsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: glassCard,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Text("🌱", style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 20),
          const Text(
            "The journey has just begun!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "No magic words collected yet.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
