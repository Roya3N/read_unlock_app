import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  // ۱. ساخت پلیرهای مجزا برای جلوگیری از تداخل صداها
  static final AudioPlayer _correctPlayer = AudioPlayer();
  static final AudioPlayer _wrongPlayer = AudioPlayer();
  static final AudioPlayer _rewardPlayer = AudioPlayer();

  // آدرس فایل‌های صوتی
  static const String correctSoundPath = 'sounds/correct.mp3';
  static const String wrongSoundPath = 'sounds/wrong.mp3';
  static const String rewardSoundPath = 'sounds/reward.mp3';

  // متغیر برای سیستم Mute (بی‌صدا کردن)
  static bool _isMuted = false;

  /// مقداردهی اولیه و کش کردن صداها (Preload)
  /// این متد رو می‌تونی توی main.dart یا زمان لود شدن اپلیکیشن صدا بزنی
  static Future<void> init() async {
    try {
      // تنظیم ReleaseMode روی Stop تا به محض تمام شدن صدا، منابع آزاد بشن
      await _correctPlayer.setReleaseMode(ReleaseMode.stop);
      await _wrongPlayer.setReleaseMode(ReleaseMode.stop);
      await _rewardPlayer.setReleaseMode(ReleaseMode.stop);

      debugPrint("✅ AudioService initialized successfully.");
    } catch (e) {
      debugPrint("❌ Error initializing AudioService: $e");
    }
  }

  /// فعال / غیرفعال کردن کل صداهای اپلیکیشن
  static void toggleMute(bool mute) {
    _isMuted = mute;
    double volume = _isMuted ? 0.0 : 1.0;

    _correctPlayer.setVolume(volume);
    _wrongPlayer.setVolume(volume);
    _rewardPlayer.setVolume(volume);

    debugPrint(_isMuted ? "🔇 Audio Muted" : "🔊 Audio Unmuted");
  }

  /// پخش صدای جواب درست (با قابلیت قطع صدای قبلی در صورت کلیک سریع)
  static Future<void> playCorrect() async {
    if (_isMuted) return;
    try {
      // اگر صدایی از قبل در حال پخشه، اول قطعش کن تا تو هم نپیچن
      if (_correctPlayer.state == PlayerState.playing) {
        await _correctPlayer.stop();
      }
      await _correctPlayer.play(AssetSource(correctSoundPath));
    } catch (e) {
      debugPrint("❌ Error playing correct sound: $e");
    }
  }

  /// پخش صدای جواب غلط
  static Future<void> playWrong() async {
    if (_isMuted) return;
    try {
      if (_wrongPlayer.state == PlayerState.playing) {
        await _wrongPlayer.stop();
      }
      await _wrongPlayer.play(AssetSource(wrongSoundPath));
    } catch (e) {
      debugPrint("❌ Error playing wrong sound: $e");
    }
  }

  /// پخش صدای جایزه
  static Future<void> playReward() async {
    if (_isMuted) return;
    try {
      if (_rewardPlayer.state == PlayerState.playing) {
        await _rewardPlayer.stop();
      }
      await _rewardPlayer.play(AssetSource(rewardSoundPath));
    } catch (e) {
      debugPrint("❌ Error playing reward sound: $e");
    }
  }

  /// آزادسازی منابع رم (مخصوص زمانی که کاربر کلاً از اپلیکیشن خارج می‌شه)
  static Future<void> dispose() async {
    await _correctPlayer.dispose();
    await _wrongPlayer.dispose();
    await _rewardPlayer.dispose();
  }
}
