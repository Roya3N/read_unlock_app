import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  // ⏱️ ۱. متد ثبت زمان روزانه و کل (کد خودت)
  static Future<void> addDailyTime(String childId, int minutesEarned) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // آپدیت زمان امروز (برای نمودار)
    DocumentReference dailyRef = FirebaseFirestore.instance
        .collection('parents')
        .doc(user.uid)
        .collection('children')
        .doc(childId)
        .collection('daily_activity')
        .doc(today);

    await dailyRef.set({
      'date': today,
      'minutes': FieldValue.increment(minutesEarned),
    }, SetOptions(merge: true));

    // آپدیت زمان کل (برای داشبورد)
    await FirebaseFirestore.instance
        .collection('parents')
        .doc(user.uid)
        .collection('children')
        .doc(childId)
        .update({
          'timeBalance': FieldValue.increment(minutesEarned),
          'totalEarnedTime': FieldValue.increment(minutesEarned),
        });
  }

  // 🌱 ۲. متد جدید: ثبت کلمات در گنجینه لغات (Vocabulary Journey)
  static Future<void> saveLearnedWords(
    String childId,
    List<dynamic> newWords,
  ) async {
    if (newWords.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentReference childRef = FirebaseFirestore.instance
        .collection('parents')
        .doc(user.uid)
        .collection('children')
        .doc(childId);

    // 🪄 آپگرید طلایی: استفاده از set و merge برای جلوگیری از ارور
    await childRef
        .set({
          'learnedWords': FieldValue.arrayUnion(newWords),
        }, SetOptions(merge: true))
        .catchError((error) => print("Error saving words: $error"));
  }
}
