import 'package:flutter/foundation.dart';
import 'package:read_unlock_app/core/backend/backend.dart';

class AppLogger {
  /// Sends a log line to `system_logs` (signed-in users only; admins read
  /// them in the admin logs screen).
  static Future<void> _sendLog({
    required String type, // 'error', 'warning', 'info'
    required String message,
  }) async {
    debugPrint("[${type.toUpperCase()}] $message");
    if (!Backend.isSignedIn) return;
    try {
      await Backend.db.from('system_logs').insert({
        'level': type,
        'message': message.length > 2000 ? message.substring(0, 2000) : message,
        'context': {'email': Backend.currentUser?.email},
      });
    } catch (e) {
      debugPrint("Failed to send log: $e");
    }
  }

  static Future<void> error(String message, [dynamic error]) async {
    final fullMessage = error != null ? "$message | Details: $error" : message;
    await _sendLog(type: 'error', message: fullMessage);
  }

  static Future<void> warning(String message) async {
    await _sendLog(type: 'warning', message: message);
  }

  static Future<void> info(String message) async {
    await _sendLog(type: 'info', message: message);
  }
}
