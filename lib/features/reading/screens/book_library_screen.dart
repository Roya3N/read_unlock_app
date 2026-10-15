import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart'; // 👈 اضافه شد برای انیمیشن‌های Pro
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:read_unlock_app/features/child/screens/parent_signup_screen.dart';
import 'package:read_unlock_app/features/reading/controllers/reading_controller.dart';
import 'reading_screen.dart';
import '../models/book_model.dart';

class BookLibraryScreen extends StatefulWidget {
  const BookLibraryScreen({super.key});

  @override
  State<BookLibraryScreen> createState() => _BookLibraryScreenState();
}

class _BookLibraryScreenState extends State<BookLibraryScreen> {
  final ReadingController _readingController = ReadingController();
  late int childAge;
  String selectedCategory = 'Kids (5-9 years)';
  String searchQuery = "";

  final List<Map<String, String>> sidebarCategories = [
    {'id': 'Toddlers (3-4 years)', 'short': '3-4 Yrs', 'icon': '🐣'},
    {'id': 'Kids (5-9 years)', 'short': '5-9 Yrs', 'icon': '🚀'},
    {'id': 'Pre-teens (10-12 years)', 'short': '10-12 Yrs', 'icon': '⚡'},
    {'id': 'Teens (13-17 years)', 'short': '13-17 Yrs', 'icon': '🔥'},
  ];

  @override
  void initState() {
    super.initState();
    childAge = AppState.activeChildAge > 0 ? AppState.activeChildAge : 10;

    if (childAge >= 3 && childAge <= 4) {
      selectedCategory = 'Toddlers (3-4 years)';
    } else if (childAge >= 5 && childAge <= 9) {
      selectedCategory = 'Kids (5-9 years)';
    } else if (childAge >= 10 && childAge <= 12) {
      selectedCategory = 'Pre-teens (10-12 years)';
    } else {
      selectedCategory = 'Teens (13-17 years)';
    }
    _readingController.initialize(selectedCategory);
  }

  Color getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4ADE80);
      case 'medium':
        return const Color(0xFF3B82F6);
      case 'hard':
        return const Color(0xFFF87171);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  // 🔒 دیالوگ شیشه‌ای و جذاب برای کاربران مهمان
  void _showGuestLockDialog(BuildContext context) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24).withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFFBBF24), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withOpacity(0.2),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFFFBBF24),
                        size: 60,
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(end: 1.1, duration: 800.ms),
                  const SizedBox(height: 15),
                  const Text(
                    "Premium Adventure! 🚀",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Ask your parents to create an account to unlock ALL magical books and heroes!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // بستن پاپ‌آپ
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ParentSignupScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 10,
                      shadowColor: const Color(0xFF8B5CF6).withOpacity(0.5),
                    ),
                    child: const Text(
                      "Ask Parents to Sign Up",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().scale(curve: Curves.easeOutBack),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // 🌌 هاله‌های نورانی انیمیشن‌دار
          Positioned(
            top: -50,
            left: -50,
            child: _buildGlowOrb(const Color(0xFF8B5CF6), 250)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.2, duration: 4.seconds),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _buildGlowOrb(const Color(0xFF3B82F6), 300)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.1, duration: 5.seconds),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // هدر جذاب
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
                        '📚 Magic Library',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ).animate().fade().slideX(begin: -0.2),
                ),

                // بدنه اصلی
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // بخش چپ: سرچ‌بار + لیست کتاب‌ها
                      Expanded(
                        child: Column(
                          children: [
                            // 🔍 سرچ‌بار شیشه‌ای
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 10,
                                bottom: 15,
                              ),
                              child:
                                  ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 10,
                                            sigmaY: 10,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.05,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: TextField(
                                              onChanged: (value) {
                                                setState(
                                                  () => searchQuery = value,
                                                );
                                                _readingController
                                                    .updateSearchQuery(
                                                      value,
                                                    ); // 👈 خبر دادن به کنترلر
                                              },
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              decoration: const InputDecoration(
                                                hintText:
                                                    "Find an adventure...",
                                                hintStyle: TextStyle(
                                                  color: Colors.white38,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.search_rounded,
                                                  color: Color(0xFF8B5CF6),
                                                  size: 22,
                                                ),
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .animate()
                                      .fade(delay: 200.ms)
                                      .slideY(begin: -0.2),
                            ),

                            // 📚 گرید کتاب‌ها
                            // 📚 گرید کتاب‌ها
                            Expanded(
                              child: AnimatedBuilder(
                                animation: _readingController,
                                builder: (context, child) {
                                  if (_readingController.isLoading) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF8B5CF6),
                                      ),
                                    );
                                  }

                                  if (_readingController
                                      .errorMessage
                                      .isNotEmpty) {
                                    return _buildEmptyState(
                                      _readingController.errorMessage,
                                    );
                                  }

                                  final books =
                                      _readingController.filteredBooks;

                                  if (books.isEmpty) {
                                    return _buildEmptyState(
                                      searchQuery.isEmpty
                                          ? "No books available yet!\nAsk your parent to add some. 📚"
                                          : "No magical books found here! 🕵️‍♂️",
                                    );
                                  }

                                  return GridView.builder(
                                    padding: const EdgeInsets.only(
                                      left: 20,
                                      right: 10,
                                      bottom: 40,
                                    ),
                                    physics: const BouncingScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 160,
                                          childAspectRatio: 0.55,
                                          crossAxisSpacing: 15,
                                          mainAxisSpacing: 20,
                                        ),
                                    itemCount: books.length,
                                    itemBuilder: (context, index) {
                                      // فرمول قفل مهمان: فقط اولین کتاب باز است
                                      bool isGuestLocked =
                                          AppState.isGuest && index > 0;

                                      return _build3DBookCard(
                                            books[index],
                                            context,
                                            isGuestLocked,
                                          )
                                          .animate()
                                          .fade(delay: (100 * index).ms)
                                          .slideY(begin: 0.2);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // بخش راست: سایدبار ثابت
                      _buildRightSidebar()
                          .animate()
                          .fade(delay: 300.ms)
                          .slideX(begin: 0.2),
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

  Widget _buildGlowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 100)],
      ),
    );
  }

  // 🌟 سایدبار ثابت و شیشه‌ای
  Widget _buildRightSidebar() {
    return Container(
      width: 95,
      margin: const EdgeInsets.only(right: 15, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
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

  Widget _buildVerticalFilterChip(Map<String, String> cat) {
    String id = cat['id']!;
    String range = cat['short']!.split(' ').first;
    String icon = cat['icon']!;
    bool isSelected = selectedCategory == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => selectedCategory = id);
        _readingController.updateCategory(id); // 👈 خبر دادن به کنترلر
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12),
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B5CF6)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFFA78BFA) : Colors.transparent,
            width: 2,
          ),
          // 🛡️ فیکسِ قطعی ارور اینجاست:
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.4),
                    blurRadius: 15.0,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Colors.transparent, // سایه نامرئی
                    blurRadius: 0.0, // حتماً با اعشار
                    offset: Offset(0, 0),
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

  Widget _build3DBookCard(Book book, BuildContext context, bool isGuestLocked) {
    // 👈 محاسبات XP از UI رفت تو مغز متفکر
    bool isPracticeOnly = _readingController.isPracticeOnly(book);
    int finalXp = isPracticeOnly ? 0 : book.xpReward;
    Color levelColor = getLevelColor(book.level);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();

        // 🚨 بررسی قفل مهمان
        if (isGuestLocked) {
          _showGuestLockDialog(context);
          return;
        }

        if (book.pages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("This book has no pages yet!"),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        if (isPracticeOnly) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("📖 Practice Mode! No XP given."),
              backgroundColor: Colors.blueGrey,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _readingController.startReadingBook(book);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReadingScreen(
              pages: book.pages,
              pageTexts: book.pageTexts,
              title: book.title,
              quiz: book.quiz,
              level: book.level,
              xpReward: finalXp,
              timeReward: isPracticeOnly ? 0 : 10,
              vocabulary: book.vocabulary,
            ),
          ),
        );
      },
      child: Column(
        children: [
          // کاور کتاب سه‌بعدی
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: levelColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(4, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  book.coverImage.isNotEmpty
                      ? Image.network(
                          book.coverImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              _buildFallbackCover(levelColor),
                        )
                      : _buildFallbackCover(levelColor),

                  // شیرازه کتاب
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 8,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xCC000000),
                            Color(0x33000000),
                            Colors.transparent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),

                  // 🔒 لایه قفل مهمان روی کاور
                  if (isGuestLocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(
                            0.65,
                          ), // پس‌زمینه تاریک
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_rounded,
                            color: Colors.white70,
                            size: 40,
                          ),
                        ),
                      ),
                    ),

                  if (isPracticeOnly && !isGuestLocked)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // عنوان کتاب
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isGuestLocked ? Colors.white54 : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),

          // تگ‌های شیشه‌ای پایین کارت
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: levelColor.withOpacity(0.3)),
                ),
                child: Text(
                  book.level.toUpperCase(),
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isPracticeOnly
                      ? Colors.white12
                      : const Color(0xFFFBBF24).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isPracticeOnly
                        ? Colors.transparent
                        : const Color(0xFFFBBF24).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: isPracticeOnly
                          ? Colors.white54
                          : const Color(0xFFFBBF24),
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isPracticeOnly ? "0" : "$finalXp",
                      style: TextStyle(
                        color: isPracticeOnly
                            ? Colors.white54
                            : const Color(0xFFFBBF24),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
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

  Widget _buildFallbackCover(Color color) {
    return Container(
      color: color.withOpacity(0.15),
      child: Center(
        child: Icon(
          Icons.auto_stories_rounded,
          color: color.withOpacity(0.5),
          size: 40,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        // 🛡️ انیمیشن رو آوردیم داخل روی Column که سایه متن نداره
        child:
            Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🎒", style: TextStyle(fontSize: 50)),
                    const SizedBox(height: 15),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                  ],
                )
                .animate(key: ValueKey(message))
                .fade()
                .scale(), // اضافه شدن کلید هوشمند
      ),
    );
  }
}
