import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';

class ReadingController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // === وضعیت‌ها ===
  bool isLoading = true;
  String errorMessage = '';

  // === دیتای کتاب‌ها و فیلترها ===
  List<Book> allBooks = [];
  List<Book> filteredBooks = [];
  String _currentCategory = '';
  String _searchQuery = '';

  // === متغیرهای ضد تقلب ===
  Book? currentReadingBook;
  DateTime? _bookStartTime;

  // ==========================================
  // ۱. راه‌اندازی و فیلترها
  // ==========================================
  void initialize(String initialCategory) {
    _currentCategory = initialCategory;
    fetchLibraryBooks();
  }

  Future<void> fetchLibraryBooks() async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final snapshot = await _db.collection('books').get();
      allBooks = snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();

      _applyFilters();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = "Couldn't load the magical books. ✨";
      isLoading = false;
      notifyListeners();
    }
  }

  void updateCategory(String newCategory) {
    _currentCategory = newCategory;
    _applyFilters();
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    filteredBooks = allBooks.where((book) {
      bool matchesCat = book.category == _currentCategory;
      bool matchesSearch = book.title.toLowerCase().contains(_searchQuery);
      return matchesCat && matchesSearch;
    }).toList();
  }

  bool isPracticeOnly(Book book) {
    int childAge = AppState.activeChildAge > 0 ? AppState.activeChildAge : 10;
    String userActualGroup;
    if (childAge >= 3 && childAge <= 4)
      userActualGroup = 'Toddlers (3-4 years)';
    else if (childAge >= 5 && childAge <= 9)
      userActualGroup = 'Kids (5-9 years)';
    else if (childAge >= 10 && childAge <= 12)
      userActualGroup = 'Pre-teens (10-12 years)';
    else
      userActualGroup = 'Teens (13-17 years)';

    List<String> pureAgeGroups = [
      'Toddlers (3-4 years)',
      'Kids (5-9 years)',
      'Pre-teens (10-12 years)',
      'Teens (13-17 years)',
    ];

    int userIdx = pureAgeGroups.indexOf(userActualGroup);
    int bookIdx = pureAgeGroups.indexOf(book.category);

    return (bookIdx != -1 && (userIdx - bookIdx) > 1);
  }

  // ==========================================
  // ۲. منطق خواندن و ضد تقلب (Anti-Cheat)
  // ==========================================
  void startReadingBook(Book book) {
    currentReadingBook = book;
    _bookStartTime = DateTime.now(); // ثبت زمان شروع
    notifyListeners();
  }

  Future<bool> finalizeBookAndClaimRewards({
    required int correctQuizAnswers,
    required int totalQuizQuestions,
  }) async {
    if (currentReadingBook == null || _bookStartTime == null) return false;

    // بررسی سرعتِ خواندن
    final now = DateTime.now();
    final timeSpentInSeconds = now.difference(_bookStartTime!).inSeconds;
    final minRequiredTime =
        currentReadingBook!.pages.length * 5; // هر صفحه ۵ ثانیه

    if (timeSpentInSeconds < minRequiredTime) {
      errorMessage = "You read too fast! Take your time to earn rewards. 🐢";
      return false;
    }

    try {
      final user = _auth.currentUser;
      if (user == null || AppState.activeChildId.isEmpty) return false;

      final childRef = _db
          .collection('parents')
          .doc(user.uid)
          .collection('children')
          .doc(AppState.activeChildId);

      final success = await _db.runTransaction<bool>((transaction) async {
        final childSnapshot = await transaction.get(childRef);
        if (!childSnapshot.exists) return false;

        final childData = childSnapshot.data() as Map<String, dynamic>;
        int currentXp = childData['xp'] ?? 0;
        int currentTimeBalance = childData['timeBalance'] ?? 0;
        List<dynamic> readBooks = childData['readBooksHistory'] ?? [];

        // اگر قبلا خونده باشه فقط ۱ امتیاز میده
        if (readBooks.contains(currentReadingBook!.id)) {
          currentXp += 1;
        } else {
          int performanceBonus = (correctQuizAnswers * 2);
          currentXp += currentReadingBook!.xpReward + performanceBonus;
          currentTimeBalance += currentReadingBook!.timeReward;
          readBooks.add(currentReadingBook!.id);
        }

        transaction.update(childRef, {
          'xp': currentXp,
          'timeBalance': currentTimeBalance,
          'readBooksHistory': readBooks,
          'lastBookReadId': currentReadingBook!.id,
          'lastReadTimestamp': FieldValue.serverTimestamp(),
        });

        AppState.timeBalance = currentTimeBalance;
        return true;
      });

      if (success) {
        currentReadingBook = null;
        _bookStartTime = null;
        return true;
      }
      return false;
    } catch (e) {
      errorMessage = "Error saving your rewards!";
      return false;
    }
  }
}
