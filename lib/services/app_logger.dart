import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  // متد اصلی فرستادن لاگ به دیتابیس
  static Future<void> _sendLog({
    required String type, // 'error', 'warning', 'info'
    required String message,
  }) async {
    try {
      // پیدا کردن کاربری که ارور براش رخ داده
      final user = FirebaseAuth.instance.currentUser;
      final userIdentifier = user?.email ?? 'Guest / Not Logged In';

      await FirebaseFirestore.instance.collection('system_logs').add({
        'type': type,
        'message': message,
        'user': userIdentifier,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // تو کنسول خودت هم چاپش می‌کنیم که موقع برنامه‌نویسی ببینیش
      debugPrint("[$type.toUpperCase()] $message");
    } catch (e) {
      debugPrint("🚨 Failed to send log to Firebase: $e");
    }
  }

  // 🔴 برای ثبت ارورهای خطرناک (مثلاً قطع شدن دیتابیس)
  static Future<void> error(String message, [dynamic error]) async {
    final fullMessage = error != null ? "$message | Details: $error" : message;
    await _sendLog(type: 'error', message: fullMessage);
  }

  // 🟠 برای ثبت هشدارهای مشکوک (مثلاً کاربری که قصد هک داره)
  static Future<void> warning(String message) async {
    await _sendLog(type: 'warning', message: message);
  }

  // 🔵 برای ثبت اتفاقات مهم ولی عادی (مثلاً یه اکانت جدید ساخته شد)
  static Future<void> info(String message) async {
    await _sendLog(type: 'info', message: message);
  }
}
