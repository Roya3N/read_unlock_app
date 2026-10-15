import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'dart:ui'; // برای افکت شیشه‌ای
import 'math_gameplay_screen.dart';

class MathLevel {
  final int levelId;
  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  final String ageGroup;
  final String difficulty;
  final List<String> operations;
  final int maxNumber;
  final int timeReward;
  final int xpReward;
  final int goal;

  MathLevel({
    required this.levelId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.ageGroup,
    required this.difficulty,
    required this.operations,
    required this.maxNumber,
    required this.timeReward,
    required this.xpReward,
    required this.goal,
  });
}

class MathQuestScreen extends StatefulWidget {
  const MathQuestScreen({super.key});

  @override
  State<MathQuestScreen> createState() => _MathQuestScreenState();
}

class _MathQuestScreenState extends State<MathQuestScreen> {
  late int childAge;
  late String selectedAgeGroup;

  // 🪄 لیست جدید رده‌های سنی برای سایدبار کناری (خلاصه‌تر + ایموجی)
  final List<Map<String, String>> sidebarCategories = [
    {'id': 'Toddlers (3-4 years)', 'short': '3-4 Yrs', 'icon': '🐣'},
    {'id': 'Kids (5-9 years)', 'short': '5-9 Yrs', 'icon': '🚀'},
    {'id': 'Pre-teens (10-12 years)', 'short': '10-12 Yrs', 'icon': '⚡'},
    {'id': 'Teens (13-17 years)', 'short': '13-17 Yrs', 'icon': '🔥'},
  ];

  final Map<String, int> unlockedLevels = {
    'Toddlers (3-4 years)': 3,
    'Kids (5-9 years)': 3,
    'Pre-teens (10-12 years)': 1,
    'Teens (13-17 years)': 1,
  };

  @override
  void initState() {
    super.initState();
    childAge = AppState.activeChildAge > 0 ? AppState.activeChildAge : 10;

    if (childAge >= 3 && childAge <= 4)
      selectedAgeGroup = 'Toddlers (3-4 years)';
    else if (childAge >= 5 && childAge <= 9)
      selectedAgeGroup = 'Kids (5-9 years)';
    else if (childAge >= 10 && childAge <= 12)
      selectedAgeGroup = 'Pre-teens (10-12 years)';
    else
      selectedAgeGroup = 'Teens (13-17 years)';
  }

  final List<MathLevel> allLevels = [
    MathLevel(
      levelId: 1,
      ageGroup: 'Toddlers (3-4 years)',
      title: "Count the Apples",
      subtitle: "Learn Numbers 1 to 5",
      icon: "🍎",
      color: const Color(0xFF4ADE80),
      difficulty: 'Easy',
      operations: ['count'],
      maxNumber: 5,
      timeReward: 5,
      xpReward: 10,
      goal: 5,
    ),
    MathLevel(
      levelId: 2,
      ageGroup: 'Toddlers (3-4 years)',
      title: "Number Fun",
      subtitle: "Learn Numbers up to 10",
      icon: "🎈",
      color: const Color(0xFFFBBF24),
      difficulty: 'Medium',
      operations: ['count'],
      maxNumber: 10,
      timeReward: 10,
      xpReward: 15,
      goal: 8,
    ),
    MathLevel(
      levelId: 3,
      ageGroup: 'Toddlers (3-4 years)',
      title: "Baby Addition",
      subtitle: "Simple Plus (up to 5)",
      icon: "🧸",
      color: const Color(0xFFEC4899),
      difficulty: 'Hard',
      operations: ['+'],
      maxNumber: 3,
      timeReward: 15,
      xpReward: 25,
      goal: 10,
    ),
    MathLevel(
      levelId: 1,
      ageGroup: 'Kids (5-9 years)',
      title: "Number Ninjas",
      subtitle: "Plus & Minus (up to 20)",
      icon: "🥷",
      color: const Color(0xFF4ADE80),
      difficulty: 'Easy',
      operations: ['+', '-'],
      maxNumber: 20,
      timeReward: 10,
      xpReward: 15,
      goal: 10,
    ),
    MathLevel(
      levelId: 2,
      ageGroup: 'Kids (5-9 years)',
      title: "Speed Addition",
      subtitle: "Double Digits (+)",
      icon: "⚡",
      color: const Color(0xFFFBBF24),
      difficulty: 'Medium',
      operations: ['+'],
      maxNumber: 50,
      timeReward: 15,
      xpReward: 25,
      goal: 15,
    ),
    MathLevel(
      levelId: 3,
      ageGroup: 'Kids (5-9 years)',
      title: "Intro to Times",
      subtitle: "Basic Multiplication (*)",
      icon: "✖️",
      color: const Color(0xFF8B5CF6),
      difficulty: 'Hard',
      operations: ['*'],
      maxNumber: 10,
      timeReward: 20,
      xpReward: 40,
      goal: 15,
    ),
    MathLevel(
      levelId: 1,
      ageGroup: 'Pre-teens (10-12 years)',
      title: "Multiplication Pro",
      subtitle: "Fast Times Tables (*)",
      icon: "🚀",
      color: const Color(0xFFF87171),
      difficulty: 'Medium',
      operations: ['*'],
      maxNumber: 15,
      timeReward: 15,
      xpReward: 30,
      goal: 15,
    ),
    MathLevel(
      levelId: 2,
      ageGroup: 'Pre-teens (10-12 years)',
      title: "Division Dash",
      subtitle: "Quick Division (/)",
      icon: "➗",
      color: const Color(0xFF3B82F6),
      difficulty: 'Hard',
      operations: ['/'],
      maxNumber: 144,
      timeReward: 20,
      xpReward: 45,
      goal: 20,
    ),
    MathLevel(
      levelId: 3,
      ageGroup: 'Pre-teens (10-12 years)',
      title: "Brain Boss",
      subtitle: "Mixed Math Problems",
      icon: "🧠",
      color: const Color(0xFF9333EA),
      difficulty: 'Expert',
      operations: ['+', '-', '*', '/'],
      maxNumber: 100,
      timeReward: 30,
      xpReward: 100,
      goal: 20,
    ),
    MathLevel(
      levelId: 1,
      ageGroup: 'Teens (13-17 years)',
      title: "Algebra Master",
      subtitle: "Advanced Mixed Math",
      icon: "📐",
      color: const Color(0xFF0D9488),
      difficulty: 'Expert',
      operations: ['+', '-', '*', '/'],
      maxNumber: 250,
      timeReward: 30,
      xpReward: 70,
      goal: 20,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLevels = allLevels
        .where((lvl) => lvl.ageGroup == selectedAgeGroup)
        .toList();
    currentLevels.sort((a, b) => a.levelId.compareTo(b.levelId));

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // 🌌 پس‌زمینه فضایی
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withOpacity(0.3),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.4),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withOpacity(0.4),
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
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        '➕ Math Quest',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // 👈 طراحی جدید: تقسیم صفحه به دو بخش (مراحل در چپ، منو در راست)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // بخش چپ: لیست مراحل (اسکرول می‌خوره)
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 10,
                            bottom: 40,
                          ),
                          itemCount: currentLevels.length,
                          itemBuilder: (context, index) {
                            final level = currentLevels[index];
                            final unlockedLevelForCategory =
                                unlockedLevels[selectedAgeGroup] ?? 1;
                            final isUnlocked =
                                level.levelId <= unlockedLevelForCategory;
                            return _buildProMathCard(
                              context,
                              level,
                              isUnlocked,
                            );
                          },
                        ),
                      ),

                      // بخش راست: سایدبار ثابت
                      _buildRightSidebar(),
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

  // 🌟 سایدبار ثابت و شیشه‌ای سمت راست
  Widget _buildRightSidebar() {
    return Container(
      width: 95, // عرض سایدبار
      margin: const EdgeInsets.only(right: 15, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2), // پس‌زمینه محو سایدبار
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: sidebarCategories
                .map((cat) => _buildVerticalFilterChip(cat))
                .toList(),
          ),
        ),
      ),
    );
  }

  // دکمه‌های داخل سایدبار
  Widget _buildVerticalFilterChip(Map<String, String> cat) {
    String id = cat['id']!;
    String range = cat['short']!.split(' ').first;
    String icon = cat['icon']!;
    bool isSelected = selectedAgeGroup == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => selectedAgeGroup = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12),
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEC4899)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF7EB3) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            // 👈 مشکل اینجا حل شد: اعداد ثابت موندن، فقط رنگ شفاف می‌شه
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFEC4899).withOpacity(0.4)
                  : Colors.transparent,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              range,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Yrs",
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withOpacity(0.6)
                    : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // کارت مراحل (بدون تغییر نسبت به قبل، فقط فضای چپ رو پر می‌کنه)
  Widget _buildProMathCard(
    BuildContext context,
    MathLevel level,
    bool isUnlocked,
  ) {
    List<String> pureAgeGroups = [
      'Toddlers (3-4 years)',
      'Kids (5-9 years)',
      'Pre-teens (10-12 years)',
      'Teens (13-17 years)',
    ];
    String userActualGroup;
    if (childAge >= 3 && childAge <= 4)
      userActualGroup = 'Toddlers (3-4 years)';
    else if (childAge >= 5 && childAge <= 9)
      userActualGroup = 'Kids (5-9 years)';
    else if (childAge >= 10 && childAge <= 12)
      userActualGroup = 'Pre-teens (10-12 years)';
    else
      userActualGroup = 'Teens (13-17 years)';

    int difference =
        pureAgeGroups.indexOf(userActualGroup) -
        pureAgeGroups.indexOf(level.ageGroup);
    bool isPracticeOnly = difference > 1;

    int finalTime = isPracticeOnly ? 0 : level.timeReward;
    int finalXp = isPracticeOnly ? 0 : level.xpReward;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (isUnlocked) {
          if (isPracticeOnly) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "🎮 Practice Mode! This level is too easy, no rewards given.",
                ),
                backgroundColor: Colors.blueGrey,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          final levelToPlay = MathLevel(
            levelId: level.levelId,
            title: level.title,
            subtitle: isPracticeOnly ? "Practice Mode" : level.subtitle,
            icon: level.icon,
            color: level.color,
            ageGroup: level.ageGroup,
            difficulty: level.difficulty,
            operations: level.operations,
            maxNumber: level.maxNumber,
            goal: level.goal,
            timeReward: finalTime,
            xpReward: finalXp,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MathGameplayScreen(level: levelToPlay),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🔒 Finish the previous level to unlock this one!"),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: level.color.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isUnlocked
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? level.color.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isUnlocked
                            ? level.color.withOpacity(0.5)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isUnlocked ? level.icon : "🔒",
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Level ${level.levelId}: ${level.title}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isUnlocked ? Colors.white : Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPracticeOnly ? "Practice Mode" : level.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.white54 : Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildProTag(
                              level.difficulty,
                              isUnlocked ? level.color : Colors.white12,
                              Icons.bar_chart_rounded,
                              isUnlocked,
                            ),
                            _buildProTag(
                              isPracticeOnly ? "0 Min" : "$finalTime Min",
                              isUnlocked && !isPracticeOnly
                                  ? const Color(0xFF3B82F6)
                                  : Colors.white12,
                              Icons.timer_rounded,
                              isUnlocked,
                            ),
                            _buildProTag(
                              isPracticeOnly ? "0 XP" : "$finalXp XP",
                              isUnlocked && !isPracticeOnly
                                  ? const Color(0xFFF59E0B)
                                  : Colors.white12,
                              Icons.stars_rounded,
                              isUnlocked,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProTag(
    String label,
    Color color,
    IconData icon,
    bool isUnlocked,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isUnlocked ? color : Colors.white38),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isUnlocked ? color : Colors.white38,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
