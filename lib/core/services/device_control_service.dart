import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppUsage {
  final String packageName;
  final String label;
  final int minutes;
  const AppUsage(this.packageName, this.label, this.minutes);
}

/// Android-only device controls that use supported system features
/// (see MainActivity.kt). On other platforms every call is a safe no-op.
///
/// - Kids Mode = Android screen pinning. Android asks to confirm; leaving
///   needs the device PIN only if "Ask for PIN before unpinning" is on.
/// - Usage report = Usage Access, granted by the user in system settings.
///   It measures; it does not block other apps.
class DeviceControlService {
  static const _channel = MethodChannel('smart_unlock/device');

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static Future<bool> _call(String method) async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } catch (e) {
      debugPrint("Device control $method error: $e");
      return false;
    }
  }

  static Future<bool> startKidsMode() => _call('startPinning');
  static Future<bool> stopKidsMode() => _call('stopPinning');
  static Future<bool> isKidsModeOn() => _call('isPinned');
  static Future<bool> hasUsageAccess() => _call('hasUsageAccess');
  static Future<bool> openUsageAccessSettings() =>
      _call('openUsageAccessSettings');

  static Future<List<AppUsage>> usageToday() async {
    if (!isSupported) return const [];
    try {
      final raw = await _channel.invokeListMethod<Map>('usageToday') ?? [];
      return raw
          .map(
            (m) => AppUsage(
              m['package']?.toString() ?? '',
              m['label']?.toString() ?? '',
              m['minutes'] is int ? m['minutes'] as int : 0,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("Device usage error: $e");
      return const [];
    }
  }
}
