import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FactVsFakeScreen extends StatefulWidget {
  const FactVsFakeScreen({super.key});

  @override
  State<FactVsFakeScreen> createState() => _FactVsFakeScreenState();
}

class _FactVsFakeScreenState extends State<FactVsFakeScreen> {
  final Color bgDark = const Color(0xFF0B141A);
  final Color cardBackBg = const Color(0xFF152A38);
  final Color factColor = const Color(0xFF10B981);
  final Color fakeColor = const Color(0xFFEF4444);

  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  bool? _userGuessedFact;

  bool _isLoading = true;
  List<Map<String, dynamic>> _scenarios = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestionsFromDatabase();
  }

  // 🚀 استخراج دیتای کامل شامل Difficulty و XP
  Future<void> _fetchQuestionsFromDatabase() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('fact_vs_fake').select();

      final List<Map<String, dynamic>> fetchedData = (response as List).map((
        data,
      ) {
        return {
          "statement": data['statement'] ?? "No Statement",
          "isFact": data['is_fact'] ?? false,
          "explanation": data['explanation'] ?? "No explanation provided.",
          "category": data['category'] ?? "General",
          "difficulty": data['difficulty'] ?? "easy", // 🔥 پرو: دریافت سختی
          "xp": data['xp'] ?? 10, // 🌟 پرو: دریافت امتیاز متغیر
        };
      }).toList();

      fetchedData.shuffle();

      if (mounted) {
        setState(() {
          _scenarios = fetchedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching questions: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🧠 بررسی جواب و محاسبه امتیاز داینامیک
  void _checkAnswer(bool userGuessFact) {
    HapticFeedback.mediumImpact();
    final bool isActuallyFact = _scenarios[_currentIndex]['isFact'];

    // گرفتن مقدار xp دقیق همین سوال از دیتابیس
    final int earnedXp = _scenarios[_currentIndex]['xp'] as int;

    setState(() {
      _isAnswered = true;
      _userGuessedFact = userGuessFact;

      if (userGuessFact == isActuallyFact) {
        _score += earnedXp; // ✨ واریز هوشمند امتیاز
      }
    });
  }

  void _nextScenario() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_currentIndex < _scenarios.length - 1) {
        _currentIndex++;
        _isAnswered = false;
        _userGuessedFact = null;
      } else {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    )
                  : _scenarios.isEmpty
                  ? const Center(
                      child: Text(
                        "No scenarios found!\nAdd some in Supabase.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 18),
                      ),
                    )
                  : _buildGameCard(),
            ),

            if (!_isLoading && _scenarios.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
                child: _isAnswered
                    ? _buildNextButton()
                    : _buildFactFakeButtons(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: Container(
          key: ValueKey(_currentIndex),
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: cardBackBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🏷️ هدر حرفه‌ای کارت: کتگوری (چپ) + درجه سختی (راست)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _scenarios[_currentIndex]['category']
                          .toString()
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 🔥 تگ درجه سختی داینامیک
                  Builder(
                    builder: (context) {
                      final diff = _scenarios[_currentIndex]['difficulty']
                          .toString()
                          .toLowerCase();
                      Color diffColor = Colors.greenAccent;
                      IconData diffIcon = Icons.spa_rounded;

                      if (diff == 'medium') {
                        diffColor = Colors.orangeAccent;
                        diffIcon = Icons.speed_rounded;
                      } else if (diff == 'hard') {
                        diffColor = Colors.redAccent;
                        diffIcon = Icons.local_fire_department_rounded;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: diffColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: diffColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(diffIcon, color: diffColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              diff.toUpperCase(),
                              style: TextStyle(
                                color: diffColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Spacer(),
              Text(
                _scenarios[_currentIndex]['statement'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  height: 1.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isAnswered)
                _buildExplanationBox().animate().fadeIn().slideY(
                  begin: 0.2,
                  end: 0,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFactFakeButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _checkAnswer(false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: fakeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: fakeColor.withOpacity(0.5), width: 2),
              ),
              child: Column(
                children: [
                  Icon(Icons.close_rounded, color: fakeColor, size: 32),
                  const SizedBox(height: 5),
                  Text(
                    "FAKE",
                    style: TextStyle(
                      color: fakeColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: GestureDetector(
            onTap: () => _checkAnswer(true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: factColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: factColor.withOpacity(0.5), width: 2),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_rounded, color: factColor, size: 32),
                  const SizedBox(height: 5),
                  Text(
                    "FACT",
                    style: TextStyle(
                      color: factColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _nextScenario,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            "Next Scenario",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildExplanationBox() {
    final bool isActuallyFact = _scenarios[_currentIndex]['isFact'];
    final bool isCorrect = _userGuessedFact == isActuallyFact;
    final int xpWon =
        _scenarios[_currentIndex]['xp'] as int; // دریافت مقدار پاداش این مرحله

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isCorrect ? factColor : fakeColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isCorrect ? factColor : fakeColor).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCorrect
                    ? Icons.sentiment_very_satisfied_rounded
                    : Icons.sentiment_dissatisfied_rounded,
                color: isCorrect ? factColor : fakeColor,
              ),
              const SizedBox(width: 8),
              // 🌟 پرو: نمایش مقدار XP برنده شده در صورت جواب درست
              Text(
                isCorrect
                    ? "You Got It! (+$xpWon XP)"
                    : "Nope! It's actually a ${isActuallyFact ? 'FACT' : 'FAKE'}",
                style: TextStyle(
                  color: isCorrect ? factColor : fakeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          Text(
            _scenarios[_currentIndex]['explanation'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Fact vs Fake",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Colors.amberAccent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  "$_score XP",
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
    );
  }
}
