import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import 'package:read_unlock_app/core/utils/book_reward.dart';
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
    notifyListeners();
  }

  /// Gives the reward for finishing a book in one transaction, so the
  /// "too fast" and "already read" checks always apply.
  Future<BookRewardDecision> claimBookReward({
    required String bookId,
    required int pageCount,
    required DateTime startedAt,
    required int xpReward,
    required int timeReward,
    required int correctQuizAnswers,
  }) async {
    final user = _auth.currentUser;
    if (user == null || AppState.activeChildId.isEmpty) {
      return const BookRewardDecision.rejected(
        "Please sign in to save rewards.",
      );
    }

    final secondsSpent = DateTime.now().difference(startedAt).inSeconds;

    final childRef = _db
        .collection('parents')
        .doc(user.uid)
        .collection('children')
        .doc(AppState.activeChildId);

    try {
      final decision = await _db.runTransaction<BookRewardDecision>((
        transaction,
      ) async {
        final childSnapshot = await transaction.get(childRef);
        if (!childSnapshot.exists) {
          return const BookRewardDecision.rejected("Child profile not found.");
        }

        final childData = childSnapshot.data() as Map<String, dynamic>;
        final readBooks = List<dynamic>.from(
          childData['readBooksHistory'] ?? const [],
        );

        final decision = BookRewardRules.decide(
          alreadyRead: readBooks.contains(bookId),
          secondsSpent: secondsSpent,
          pageCount: pageCount,
          xpReward: xpReward,
          timeReward: timeReward,
          correctAnswers: correctQuizAnswers,
        );
        if (!decision.granted) return decision;

        final updates = <String, dynamic>{
          'xp': FieldValue.increment(decision.xp),
          'lastBookReadId': bookId,
          'lastReadTimestamp': FieldValue.serverTimestamp(),
        };
        if (decision.firstRead) {
          updates['readBooksHistory'] = FieldValue.arrayUnion([bookId]);
        }
        if (decision.minutes > 0) {
          updates['timeBalance'] = FieldValue.increment(decision.minutes);
          updates['totalEarnedTime'] = FieldValue.increment(decision.minutes);
        }
        transaction.update(childRef, updates);
        return decision;
      });

      if (decision.granted && decision.minutes > 0) {
        AppState.timeBalance += decision.minutes;
        AppState.totalEarnedTime += decision.minutes;
        await AppState.save();
      }
      return decision;
    } catch (e) {
      debugPrint("Book reward error: $e");
      return const BookRewardDecision.rejected("Error saving your rewards!");
    }
  }
}
