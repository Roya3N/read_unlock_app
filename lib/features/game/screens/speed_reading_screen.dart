import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SpeedReadingScreen extends StatefulWidget {
  const SpeedReadingScreen({super.key});

  @override
  State<SpeedReadingScreen> createState() => _SpeedReadingScreenState();
}

class _SpeedReadingScreenState extends State<SpeedReadingScreen> {
  final Color bgDark = const Color(0xFF0B141A);
  final Color cardBackBg = const Color(0xFF152A38);
  final Color accentColor = const Color(0xFF8B5CF6);

  int _currentIndex = 0;
  int _score = 0;

  int _wpm = 250;
  bool _isPlaying = false;
  bool _showQuiz = false;
  int _wordIndex = 0;
  List<String> _words = [];
  Timer? _timer;
  bool _quizAnswered = false;
  int? _selectedOption;

  bool _isLoading = true;
  List<Map<String, dynamic>> _scenarios = [];

  @override
  void initState() {
    super.initState();
    _fetchDataFromDatabase();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 🚀 دریافت داستان‌ها از دیتابیس
  Future<void> _fetchDataFromDatabase() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('speed_reading').select();

      final List<Map<String, dynamic>> fetchedData = (response as List).map((
        data,
      ) {
        return {
          "title": data['title'] ?? "Untitled",
          "content": data['content'] ?? "",
          "question": data['question'] ?? "No question provided.",
          "options": List<String>.from(
            data['options'] ?? [],
          ), // تبدیل jsonb به List
          "correct_index": data['correct_index'] ?? 0,
          "xp": data['xp'] ?? 50,
          "difficulty": data['difficulty'] ?? "medium",
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
      debugPrint("❌ Error fetching speed reading data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startReading() {
    HapticFeedback.mediumImpact();
    String content = _scenarios[_currentIndex]['content'];
    _words = content.split(RegExp(r'\s+'));

    setState(() {
      _isPlaying = true;
      _showQuiz = false;
      _wordIndex = 0;
      _quizAnswered = false;
      _selectedOption = null;
    });

    _runTimer();
  }

  void _runTimer() {
    int msPerWord = (60000 / _wpm).round();
    _timer = Timer.periodic(Duration(milliseconds: msPerWord), (timer) {
      if (_wordIndex < _words.length - 1) {
        setState(() => _wordIndex++);
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _showQuiz = true;
            });
            HapticFeedback.heavyImpact();
          }
        });
      }
    });
  }

  void _checkAnswer(int index) {
    if (_quizAnswered) return;
    HapticFeedback.lightImpact();

    final bool isCorrect = index == _scenarios[_currentIndex]['correct_index'];
    final int earnedXp = _scenarios[_currentIndex]['xp'] as int;

    setState(() {
      _quizAnswered = true;
      _selectedOption = index;
      if (isCorrect) _score += earnedXp;
    });
  }

  void _nextScenario() {
    setState(() {
      if (_currentIndex < _scenarios.length - 1) {
        _currentIndex++;
        _showQuiz = false;
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
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
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: accentColor),
                        )
                      : _scenarios.isEmpty
                      ? const Center(
                          child: Text(
                            "No stories found!\nAdd some in Supabase.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _isPlaying
                              ? _buildRSVPReader()
                              : _showQuiz
                              ? _buildQuizSection()
                              : _buildIntroSection(),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.rocket_launch_rounded,
          color: accentColor,
          size: 60,
        ).animate().slideY(begin: -0.2).fade(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _scenarios[_currentIndex]['title'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Target: ${_scenarios[_currentIndex]['xp']} XP  |  ${_scenarios[_currentIndex]['difficulty'].toString().toUpperCase()}",
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 40),
        const Text(
          "Set your speed (WPM):",
          style: TextStyle(color: Colors.white70),
        ),
        Slider(
          value: _wpm.toDouble(),
          min: 150,
          max: 600,
          divisions: 9,
          activeColor: accentColor,
          label: "$_wpm WPM",
          onChanged: (val) => setState(() => _wpm = val.toInt()),
        ),
        Text(
          "$_wpm Words Per Minute",
          style: TextStyle(
            color: accentColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: _startReading,
          child: const Text(
            "Start Focus Mode",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRSVPReader() {
    double progress = (_wordIndex + 1) / _words.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: Text(
              _words[_wordIndex],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(30),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizSection() {
    final scenario = _scenarios[_currentIndex];
    final List options = scenario['options'];
    final int correctIndex = scenario['correct_index'];
    final int xpWon = scenario['xp'] as int;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Comprehension Check 🧠",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Text(
            scenario['question'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          ...List.generate(options.length, (index) {
            bool isSelected = _selectedOption == index;
            bool isCorrectOpt = index == correctIndex;

            Color btnColor = Colors.white.withOpacity(0.05);
            Color borderColor = Colors.white10;

            if (_quizAnswered) {
              if (isCorrectOpt) {
                btnColor = Colors.green.withOpacity(0.2);
                borderColor = Colors.green;
              } else if (isSelected && !isCorrectOpt) {
                btnColor = Colors.red.withOpacity(0.2);
                borderColor = Colors.red;
              }
            } else if (isSelected) {
              btnColor = accentColor.withOpacity(0.2);
              borderColor = accentColor;
            }

            return GestureDetector(
              onTap: () => _checkAnswer(index),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: btnColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Text(
                  options[index],
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            );
          }),
          if (_quizAnswered) ...[
            const SizedBox(height: 20),
            Text(
              _selectedOption == correctIndex
                  ? "Brilliant! (+$xpWon XP)"
                  : "Oops! Needs more focus.",
              style: TextStyle(
                color: _selectedOption == correctIndex
                    ? Colors.greenAccent
                    : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _nextScenario,
              child: const Text(
                "Continue",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate().scale(),
          ],
        ],
      ),
    ).animate().fadeIn();
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
                "Speed Reading",
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
