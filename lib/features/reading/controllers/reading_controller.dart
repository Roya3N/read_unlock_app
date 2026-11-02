import 'dart:async';
import 'package:flutter/material.dart';
import 'package:read_unlock_app/core/backend/backend.dart';
import '../models/book_model.dart';
import 'package:read_unlock_app/core/utils/book_reward.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';

class ReadingController extends ChangeNotifier {
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

      final rows = await Backend.db.from('books').select().order('created_at');
      allBooks = rows.map(Book.fromRow).toList();

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
  /// Reading session started on the server, so the server clock decides
  /// how long the book was read.
  String? _sessionId;
  Future<String?>? _sessionStart;

  void startReadingBook(Book book) {
    currentReadingBook = book;
    startReadingSession(book.id);
  }

  /// Starts the server-side reading timer for [bookId].
  void startReadingSession(String bookId) {
    _sessionId = null;
    _sessionStart = null;
    if (Backend.isSignedIn && AppState.activeChildId.isNotEmpty) {
      _sessionStart = Rewards.startReading(AppState.activeChildId, bookId)
          .then<String?>((id) => _sessionId = id)
          .catchError((Object e) {
            debugPrint("Start reading error: $e");
            return null;
          });
    }
    notifyListeners();
  }

  /// Asks the server for the reward for finishing the book. The server
  /// applies the same rules as [BookRewardRules] (too fast, already read,
  /// quiz bonus) and only its answer is shown.
  Future<BookRewardDecision> claimBookReward({
    required int correctQuizAnswers,
  }) async {
    if (!Backend.isSignedIn || AppState.activeChildId.isEmpty) {
      return const BookRewardDecision.rejected(
        "Please sign in to save rewards.",
      );
    }
    final sessionId = _sessionId ?? await _sessionStart;
    if (sessionId == null) {
      return const BookRewardDecision.rejected("Error saving your rewards!");
    }

    try {
      final r = await Rewards.finishReading(sessionId, correctQuizAnswers);
      await AppState.refreshActiveChild();
      if (r['granted'] != true) {
        return BookRewardDecision.rejected(
          r['reason'] == 'too_fast'
              ? "You read too fast! Take your time to earn rewards. 🐢"
              : "No reward this time.",
        );
      }
      return BookRewardDecision.fromServer(
        firstRead: r['first_read'] == true,
        xp: (r['xp'] as num?)?.toInt() ?? 0,
        minutes: (r['minutes'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint("Book reward error: $e");
      return const BookRewardDecision.rejected("Error saving your rewards!");
    }
  }
}
