import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:read_unlock_app/models/word_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VocabMasterScreen extends StatefulWidget {
  const VocabMasterScreen({super.key});

  @override
  State<VocabMasterScreen> createState() => _VocabMasterScreenState();
}

class _VocabMasterScreenState extends State<VocabMasterScreen> {
  final Color bgDark = const Color(0xFF0B141A);
  final Color cardBackBg = const Color(0xFF152A38);
  final Color accentOrange = const Color(0xFFF59E0B);
  final Color accentBlue = const Color(0xFF3B82F6);

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _bookmarkedWords = {};

  List<WordModel> _vocabList = [];
  final List<WordModel> _learnedWords = [];
  final List<WordModel> _forgottenWords = [];

  List<String> _savedLearnedIds = [];
  List<String> _savedForgottenIds = [];

  bool _isLoading = true;
  int _currentIndex = 0;

  int _sessionScore = 0;
  int _globalWallet = 0;
  int _streak = 0;

  bool _isFlipped = false;
  bool _isFinished = false;

  // 🧠 1. متغیر کش برای ذخیره کلمات مرتبط (جلوگیری از لگ)
  Map<String, WordModel> _cache = {};

  @override
  void initState() {
    super.initState();
    _initGameData();
  }

  Future<void> _initGameData() async {
    final prefs = await SharedPreferences.getInstance();

    _savedLearnedIds = prefs.getStringList('learned_words_list') ?? [];
    _savedForgottenIds = prefs.getStringList('forgotten_words_list') ?? [];

    String? lastDateStr = prefs.getString('last_active_date');
    int savedStreak = prefs.getInt('streak_count') ?? 0;

    _globalWallet = prefs.getInt('total_score') ?? 0;
    _sessionScore = 0;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    if (lastDateStr != null) {
      DateTime lastDate = DateTime.parse(lastDateStr);
      int diff = today.difference(lastDate).inDays;
      if (diff == 1) {
        savedStreak++;
      } else if (diff > 1) {
        savedStreak = 1;
      }
    } else {
      savedStreak = 1;
    }

    await prefs.setString('last_active_date', today.toIso8601String());
    await prefs.setInt('streak_count', savedStreak);

    setState(() {
      _streak = savedStreak;
    });

    _fetchWordsFromDatabase();
  }

  Future<void> _fetchWordsFromDatabase() async {
    try {
      final supabase = Supabase.instance.client;
      // 🚀 دریافت دیتا از جدول کلمات
      final response = await supabase.from('words').select();

      // استفاده از fromJson برای پارس کردن تمیز کلمات (از جمله Synonyms و Antonyms)
      final List<WordModel> fetchedWords = (response as List)
          .map((data) => WordModel.fromJson(data as Map<String, dynamic>))
          .toList();

      fetchedWords.shuffle();

      if (mounted) {
        setState(() {
          _vocabList = fetchedWords;

          _learnedWords.clear();
          _forgottenWords.clear();
          for (var w in _vocabList) {
            if (_savedLearnedIds.contains(w.word)) {
              _learnedWords.add(w);
            } else if (_savedForgottenIds.contains(w.word)) {
              _forgottenWords.add(w);
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ خطا در دریافت کلمات: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // 🧠 2. تابع Preload برای بارگذاری از پیشِ کلمات مرتبط
  Future<void> _preloadWords(List<String> words) async {
    final supabase = Supabase.instance.client;

    for (var word in words) {
      final key = word.toLowerCase();
      if (_cache.containsKey(key)) continue;

      try {
        final res = await supabase
            .from('words')
            .select()
            .ilike('word', word)
            .maybeSingle();

        if (res != null) {
          _cache[key] = WordModel.fromJson(res);
        }
      } catch (_) {}
    }
  }

  // 🧠 منطق Tap برای جابجایی بین کلمات (Learning Graph)
  Future<void> _onRelationTap(String word) async {
    HapticFeedback.selectionClick();

    final key = word.toLowerCase();

    // ۱. اگر داخل لیست فعلی هست همون رو نشون بده
    final existingIndex = _vocabList.indexWhere(
      (w) => w.word.toLowerCase() == key,
    );

    if (existingIndex != -1) {
      setState(() {
        _currentIndex = existingIndex;
        _isFlipped = false;
      });
      return;
    }

    // ۲. اگر تو cache (حافظه موقت) بود، فورا اضافه‌اش کن
    if (_cache.containsKey(key)) {
      setState(() {
        _vocabList.insert(_currentIndex + 1, _cache[key]!);
        _currentIndex++;
        _isFlipped = false;
      });
      return;
    }

    // ۳. اگر هیچ‌جا نبود، برو از دیتابیس بگیرش
    try {
      final supabase = Supabase.instance.client;

      final res = await supabase
          .from('words')
          .select()
          .ilike('word', key) // جستجوی بدون حساسیت به حروف بزرگ/کوچک
          .maybeSingle();

      if (res != null) {
        final newWord = WordModel.fromJson(res);

        setState(() {
          _vocabList.insert(_currentIndex + 1, newWord);
          _currentIndex++;
          _isFlipped = false;
        });
      } else {
        // 🚨 اگر کلمه تو دیتابیس نبود، این پیام رو نشون بده به جای اینکه هیچ کاری نکنه!
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("'$word' is not in your database yet! 📥"),
              backgroundColor: const Color(0xFFF59E0B), // نارنجی
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Error jumping to word: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Connection error. Try again! 🌐"),
            backgroundColor: const Color(0xFFEF4444), // قرمز
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_sessionScore == 0) return true;

    bool? shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBackBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.pause_circle_filled_rounded,
                color: Colors.amber,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                "Pause Session?",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            "You earned +$_sessionScore XP so far!\nDo you want to collect your reward and take a break?",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                "Keep Going",
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "Collect & Exit",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Awesome! +$_sessionScore XP saved to your wallet! 💰",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      }
      return true;
    }
    return false;
  }

  void _jumpToWord(WordModel word) {
    int index = _vocabList.indexOf(word);
    if (index != -1) {
      setState(() {
        _currentIndex = index;
        _isFlipped = false;
      });
      Navigator.pop(context);
    }
  }

  void _nextCard(bool knewIt) async {
    HapticFeedback.lightImpact();
    final currentWord = _vocabList[_currentIndex];

    setState(() {
      bool isAlreadyLearned = _learnedWords.any(
        (w) => w.word == currentWord.word,
      );

      if (knewIt) {
        if (!isAlreadyLearned) {
          _learnedWords.add(currentWord);

          int earnedXP = 50 + (_streak * 10);
          _sessionScore += earnedXP;
          _globalWallet += earnedXP;
        }
        _forgottenWords.removeWhere((w) => w.word == currentWord.word);
      } else {
        bool isAlreadyForgotten = _forgottenWords.any(
          (w) => w.word == currentWord.word,
        );
        if (!isAlreadyForgotten) {
          _forgottenWords.add(currentWord);
        }
        _learnedWords.removeWhere((w) => w.word == currentWord.word);
      }

      _isFlipped = false;
      if (_currentIndex < _vocabList.length - 1) {
        _currentIndex++;
      } else {
        _isFinished = true;
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'learned_words_list',
      _learnedWords.map((w) => w.word).toList(),
    );
    await prefs.setStringList(
      'forgotten_words_list',
      _forgottenWords.map((w) => w.word).toList(),
    );
    await prefs.setInt('total_score', _globalWallet);
  }

  // 🕵️‍♂️ منوی مخفی توسعه‌دهنده برای استخراج کلمات ناموجود
  void _showMissingWordsDevMenu() {
    HapticFeedback.heavyImpact(); // یه ویبره محکم برای ورود به منوی مخفی!

    // ۱. پیدا کردن کلمات موجود
    Set<String> existingWords = _vocabList
        .map((w) => w.word.toLowerCase())
        .toSet();
    Set<String> missingWords = {};

    // ۲. گشتن تو دل مترادف‌ها و متضادها و شکار کلمات ناموجود
    for (var word in _vocabList) {
      for (var syn in word.synonyms) {
        if (!existingWords.contains(syn.toLowerCase()))
          missingWords.add(syn.toLowerCase());
      }
      for (var ant in word.antonyms) {
        if (!existingWords.contains(ant.toLowerCase()))
          missingWords.add(ant.toLowerCase());
      }
    }

    List<String> missingList = missingWords.toList()..sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBackBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "🕵️‍♂️ Dev Menu: Missing Words",
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Found ${missingList.length} words to add to DB",
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 15),

              Expanded(
                child: missingList.isEmpty
                    ? const Center(
                        child: Text(
                          "Database is perfectly linked! ✨",
                          style: TextStyle(color: Colors.green),
                        ),
                      )
                    : ListView.builder(
                        itemCount: missingList.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "- ${missingList[index]}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 10),
              // 📋 دکمه کپی کل لیست
              if (missingList.isNotEmpty)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.copy_all_rounded),
                  label: const Text(
                    "Copy List to Clipboard",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: () {
                    String textToCopy = missingList.join("\n");
                    Clipboard.setData(ClipboardData(text: textToCopy)).then((
                      _,
                    ) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            "List copied! Paste it in your Seed file. 📝",
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      );
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // 📚 متد جادویی و یکپارچه دیکشنری با فیلترهای کپسولی درلحظه
  void _showLibraryMenu({
    String filterType = 'all',
    String filterValue = 'All',
  }) {
    HapticFeedback.selectionClick();

    // مرتب‌سازی الفبایی
    List<WordModel> sortedList = List.from(_vocabList);
    sortedList.sort(
      (a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()),
    );

    // اگر کاربر از روی کارت، روی یک Level کلیک کرده بود، همون سطح پیش‌فرض انتخاب بشه
    String selectedLevel = filterType == 'level'
        ? filterValue.toUpperCase()
        : 'All';
    TextEditingController searchController = TextEditingController();

    // سطوح استاندارد که زیر سرچ‌باکس نمایش داده می‌شن
    List<String> availableLevels = ['All', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

    // 🚀 موتور فیلتر هوشمند
    List<WordModel> applyFilters(String query, String level) {
      return sortedList.where((w) {
        bool matchSearch = w.word.toLowerCase().contains(query.toLowerCase());
        bool matchLevel = level == 'All' || w.level.toUpperCase() == level;

        // اگر کاربر از روی تگ Category کلیک کرده باشه، لیست فقط به همون کتگوری محدود می‌شه
        bool matchCategory = filterType == 'category'
            ? w.category.toLowerCase() == filterValue.toLowerCase()
            : true;

        return matchSearch && matchLevel && matchCategory;
      }).toList();
    }

    List<WordModel> displayedList = applyFilters('', selectedLevel);

    String modalTitle = filterType == 'category'
        ? "Category: ${filterValue.toUpperCase()}"
        : "Dictionary 📚";

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBackBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    modalTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${displayedList.length} words found",
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 15),

                  // 🔍 نوار جستجو
                  TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search a word...",
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.tealAccent,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: Colors.white54,
                              ),
                              onPressed: () {
                                searchController.clear();
                                setModalState(() {
                                  displayedList = applyFilters(
                                    '',
                                    selectedLevel,
                                  );
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (query) {
                      setModalState(() {
                        displayedList = applyFilters(query, selectedLevel);
                      });
                    },
                  ),
                  const SizedBox(height: 15),

                  // 🎛️ نوار انتخاب سطح (Level Chips) زیرِ سرچ
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: availableLevels.map((lvl) {
                        bool isSelected = selectedLevel == lvl;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setModalState(() {
                              selectedLevel = lvl;
                              displayedList = applyFilters(
                                searchController.text,
                                selectedLevel,
                              );
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF59E0B)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFF59E0B)
                                    : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              lvl,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // لیست کلمات
                  Expanded(
                    child: _buildWordList(displayedList, Colors.blueAccent),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showWordStats({int initialIndex = 0}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBackBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DefaultTabController(
          length: 2,
          initialIndex: initialIndex,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const TabBar(
                  indicatorColor: Color(0xFFF59E0B),
                  labelColor: Color(0xFFF59E0B),
                  unselectedLabelColor: Colors.white54,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.check_circle_rounded),
                      text: "Got It!",
                    ),
                    Tab(icon: Icon(Icons.cancel_rounded), text: "Forgot"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildWordList(_learnedWords, Colors.green),
                      _buildWordList(_forgottenWords, Colors.redAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWordList(List<WordModel> list, Color defaultIconColor) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          "Empty!",
          style: TextStyle(color: Colors.white.withOpacity(0.3)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final word = list[index];

        bool isLearned = _learnedWords.any((w) => w.word == word.word);
        bool isForgotten = _forgottenWords.any((w) => w.word == word.word);

        Color statusColor = defaultIconColor;
        IconData statusIcon = Icons.circle;

        if (isLearned) {
          statusColor = const Color(0xFF10B981);
          statusIcon = Icons.check_circle_rounded;
        } else if (isForgotten) {
          statusColor = const Color(0xFFEF4444);
          statusIcon = Icons.cancel_rounded;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border(
              left: BorderSide(color: statusColor.withOpacity(0.5), width: 4),
            ),
          ),
          child: ListTile(
            onTap: () => _jumpToWord(word),
            leading: Icon(statusIcon, color: statusColor, size: 20),
            title: Text(
              word.word,
              style: TextStyle(
                color: isLearned || isForgotten ? statusColor : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              isLearned
                  ? "Mastered! ✨"
                  : isForgotten
                  ? "Needs Review 🔄"
                  : "New Word 🆕",
              style: TextStyle(
                color: (isLearned || isForgotten ? statusColor : Colors.white)
                    .withOpacity(0.5),
                fontSize: 11,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (word.level.isNotEmpty)
                  _buildMiniListBadge(word.level, const Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                if (word.category.isNotEmpty)
                  _buildMiniListBadge(word.category, const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white24,
                  size: 14,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniListBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: bgDark,
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                )
              : _vocabList.isEmpty
              ? _buildEmptyScreen()
              : _isFinished
              ? _buildVictoryScreen()
              : _buildGameScreen(),
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_rounded, size: 80, color: Colors.white54),
          const SizedBox(height: 20),
          const Text(
            "No Words Found!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Please add some words to the database first.",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Go Back",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final isNewWord = child.key == ValueKey(_currentIndex);
                final offset = isNewWord
                    ? Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation)
                    : Tween<Offset>(
                        begin: const Offset(-1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: Container(
                key: ValueKey(_currentIndex),
                child: GestureDetector(
                  onTap: () => setState(() => _isFlipped = !_isFlipped),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          final rotateAnim = Tween(begin: math.pi, end: 0.0)
                              .animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                ),
                              );
                          return AnimatedBuilder(
                            animation: rotateAnim,
                            child: child,
                            builder: (context, widget) {
                              final isUnder =
                                  (ValueKey(_isFlipped) != widget?.key);
                              final value = isUnder
                                  ? math.min(rotateAnim.value, math.pi / 2)
                                  : rotateAnim.value;
                              return Transform(
                                transform: Matrix4.rotationY(value),
                                alignment: Alignment.center,
                                child: widget,
                              );
                            },
                          );
                        },
                    child: _isFlipped ? _buildCardBack() : _buildCardFront(),
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildProgressDots(),
        AnimatedOpacity(
          opacity: _isFlipped ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButtons(
                  icon: Icons.close_rounded,
                  color: const Color(0xFFEF4444),
                  label: "Forgot",
                  count: _forgottenWords.length,
                  onAction: () => _isFlipped ? _nextCard(false) : null,
                  onList: () => _showWordStats(initialIndex: 1),
                ),
                _buildActionButtons(
                  icon: Icons.check_rounded,
                  color: const Color(0xFF10B981),
                  label: "Got It!",
                  count: _learnedWords.length,
                  onAction: () => _isFlipped ? _nextCard(true) : null,
                  onList: () => _showWordStats(initialIndex: 0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
    required VoidCallback onAction,
    required VoidCallback onList,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 30, color: color.withOpacity(0.2)),
          GestureDetector(
            onTap: onList,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Text(
                "$count",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
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
                onTap: () async {
                  bool canLeave = await _onWillPop();
                  if (canLeave && mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 10),
              // 🕵️‍♂️ اضافه شدن امکان Long Press به عنوان برنامه
              GestureDetector(
                onLongPress: _showMissingWordsDevMenu,
                child: const Text(
                  "Vocab Master",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showLibraryMenu(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.tealAccent,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showWordStats,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFF59E0B),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$_streak",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.blueAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$_sessionScore",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront() {
    final currentWord = _vocabList[_currentIndex];
    return Container(
      key: const ValueKey(false),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: DecorationImage(
          image: NetworkImage(currentWord.imageUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.transparent,
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(
                    currentWord.word,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainBadges(WordModel word) {
    return Wrap(
      spacing: 10,
      alignment: WrapAlignment.center,
      children: [
        if (word.level.isNotEmpty)
          _buildBadge(
            word.level,
            const Color(0xFFF59E0B),
            Icons.bar_chart_rounded,
            // 🚀 فراخوانی متد جدید برای Level
            () =>
                _showLibraryMenu(filterType: 'level', filterValue: word.level),
          ),
        if (word.category.isNotEmpty)
          _buildBadge(
            word.category,
            const Color(0xFF3B82F6),
            Icons.category_rounded,
            // 🚀 فراخوانی متد جدید برای Category
            () => _showLibraryMenu(
              filterType: 'category',
              filterValue: word.category,
            ),
          ),
      ],
    );
  }

  Widget _buildBadge(
    String text,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              text.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtleTags(List<String> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();
    String tagsText = tags.map((t) => "#${t.toLowerCase()}").join("  •  ");
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      child: Text(
        tagsText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white30,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    final currentWord = _vocabList[_currentIndex];
    final isBookmarked = _bookmarkedWords.contains(currentWord.word);

    _preloadWords([...currentWord.synonyms, ...currentWord.antonyms]);

    return Container(
      key: const ValueKey(true),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBackBg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      // 🚀 استفاده از Stack برای آزاد گذاشتن جایگاه دکمه‌ها
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 📝 لایه زیرین: محتوای اصلی کارت
          Column(
            children: [
              const SizedBox(height: 5),

              // 📝 کلمه اصلی (حالا با خیال راحت و بدون مزاحم در مرکز می‌درخشه)
              Text(
                currentWord.word,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 2),

              // 🗣️ تلفظ
              Text(
                currentWord.phonetic,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 12),

              // 🏷️ تگ‌های سطح و دسته‌بندی
              _buildMainBadges(currentWord),

              const SizedBox(height: 15),

              // 📦 محتوای اصلی (جمع‌وجور شده)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // 1️⃣ باکس ترکیبی تعریف و مثال
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: "${currentWord.type}  ",
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  TextSpan(
                                    text: currentWord.definition,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            if (currentWord.example.isNotEmpty) ...[
                              const Divider(color: Colors.white10, height: 16),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: "Ex: ",
                                      style: TextStyle(
                                        color: Colors.tealAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: currentWord.example),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 2️⃣ باکس ترکیبی مترادف و متضاد
                      if (currentWord.synonyms.isNotEmpty ||
                          currentWord.antonyms.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (currentWord.synonyms.isNotEmpty)
                                Expanded(
                                  child: _buildWordRelations(
                                    currentWord.synonyms,
                                    "Synonyms",
                                    Colors.greenAccent,
                                  ),
                                ),

                              if (currentWord.synonyms.isNotEmpty &&
                                  currentWord.antonyms.isNotEmpty)
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white10,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),

                              if (currentWord.antonyms.isNotEmpty)
                                Expanded(
                                  child: _buildWordRelations(
                                    currentWord.antonyms,
                                    "Antonyms",
                                    Colors.redAccent,
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // 3️⃣ پیشنهاد هوشمند
                      _buildSuggestion(currentWord),

                      // 4️⃣ تگ‌های کمرنگ
                      _buildSubtleTags(currentWord.tags),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ⚡ دکمه‌های فوتر
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _openDictionary(currentWord.word),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.transparent,
                      child: Row(
                        children: const [
                          Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white54,
                            size: 20,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Dictionary",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _toggleBookmark(currentWord.word),
                    child: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isBookmarked ? accentOrange : Colors.white54,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () =>
                        _shareWord(currentWord.word, currentWord.definition),
                    child: const Icon(
                      Icons.ios_share_rounded,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 🔊 لایه رویی: دکمه صدا دقیقا در گوشه بالا سمت چپ
          Positioned(
            top: 0,
            left: 0,
            child: GestureDetector(
              onTap: () => _playRealAudio(currentWord.audioUrl),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF1E3A4C,
                  ).withOpacity(0.8), // کمی شفاف‌تر برای زیبایی بیشتر
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 ۲. نسخه فشرده‌ی مترادف و متضاد
  Widget _buildWordRelations(List<String> items, String title, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.map((item) {
            return GestureDetector(
              onTap: () => _onRelationTap(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Text(item, style: TextStyle(color: color, fontSize: 11)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 💡 ۳. نسخه هوشمند + نمایش کلمات ناموجود (با استایل کمرنگ)
  Widget _buildSuggestion(WordModel word) {
    // گرفتن تمام مترادف‌ها و متضادها
    final relatedWords = [...word.synonyms, ...word.antonyms];

    // اگر کلا هیچ کلمه مرتبطی نداشت، هیچی نشون نده
    if (relatedWords.isEmpty) return const SizedBox.shrink();

    // 🎲 بُر زدن کل کلمات برای پیشنهادهای متنوع
    relatedWords.shuffle();
    final next = relatedWords.first;

    // 🔍 بررسی اینکه آیا این کلمه در دیتابیس (_vocabList) وجود داره یا نه؟
    bool existsInDb = _vocabList.any(
      (v) => v.word.toLowerCase() == next.toLowerCase(),
    );

    return GestureDetector(
      onTap: () => _onRelationTap(next),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          // 🎨 تغییر رنگ بک‌گراند و حاشیه بر اساس موجود بودن در دیتابیس
          color: existsInDb
              ? Colors.blueAccent.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: existsInDb
                ? Colors.blueAccent.withOpacity(0.3)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              existsInDb ? Icons.explore_rounded : Icons.explore_off_rounded,
              color: existsInDb ? Colors.blueAccent : Colors.white38,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              "Explore: $next",
              style: TextStyle(
                color: existsInDb ? Colors.blueAccent : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            // 👻 اضافه کردن متن راهنمای کمرنگ اگر کلمه در دیتابیس نبود
            if (!existsInDb) ...[
              const SizedBox(width: 4),
              const Text(
                "(Not in DB)",
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _shareWord(String word, String meaning) {
    Share.share(
      'Check out this word: $word\nMeaning: $meaning\n\nLearned from Magic Academy App! 🎓',
    );
  }

  void _toggleBookmark(String word) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_bookmarkedWords.contains(word)) {
        _bookmarkedWords.remove(word);
      } else {
        _bookmarkedWords.add(word);
      }
    });
  }

  Future<void> _playRealAudio(String url) async {
    HapticFeedback.lightImpact();
    try {
      if (url.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("No audio provided for this word."),
              backgroundColor: Colors.orangeAccent.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint("❌ Error playing audio: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Audio format not supported on Web. Try on a real device! 📱",
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openDictionary(String word) async {
    final Uri url = Uri.parse(
      'https://dictionary.cambridge.org/dictionary/english/$word',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Widget _buildProgressDots() {
    final displayCount = math.min(_vocabList.length, 10);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (_currentIndex > 0) {
                HapticFeedback.lightImpact();
                setState(() {
                  _currentIndex--;
                  _isFlipped = false;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _currentIndex > 0
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _currentIndex > 0 ? Colors.white : Colors.white24,
                size: 18,
              ),
            ),
          ),

          Row(
            children: List.generate(displayCount, (index) {
              final isActive = index == (_currentIndex % displayCount);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? accentOrange
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),

          GestureDetector(
            onTap: () {
              if (_currentIndex < _vocabList.length - 1) {
                HapticFeedback.lightImpact();
                setState(() {
                  _currentIndex++;
                  _isFlipped = false;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _currentIndex < _vocabList.length - 1
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: _currentIndex < _vocabList.length - 1
                    ? Colors.white
                    : Colors.white24,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 100,
            color: Colors.amber,
          ).animate().scale(duration: 600.ms),
          const SizedBox(height: 20),
          const Text(
            "Session Finished!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "+$_sessionScore XP Earned Today",
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              "Total Wallet: $_globalWallet XP 💰",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              "Collect & Go Home",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
