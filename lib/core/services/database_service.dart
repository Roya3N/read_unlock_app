import 'package:flutter/foundation.dart';
import 'package:read_unlock_app/core/backend/backend.dart';

class DatabaseService {
  /// Adds words to the child's vocabulary journey (no duplicates).
  static Future<void> saveLearnedWords(
    String childId,
    List<dynamic> newWords,
  ) async {
    if (newWords.isEmpty || childId.isEmpty || !Backend.isSignedIn) return;
    try {
      await Children.addLearnedWords(childId, newWords);
    } catch (e) {
      debugPrint("Error saving words: $e");
    }
  }
}
