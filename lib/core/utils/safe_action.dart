import 'dart:async';
import 'package:flutter/material.dart';

class SafeAction {
  // این متغیر چک می‌کنه که آیا همین الان یه دکمه در حال اجرا هست یا نه
  static bool _isProcessing = false;

  // متد جادویی ما برای اجرای امن دستورات
  static void execute(VoidCallback action, {int cooldownMs = 500}) {
    if (_isProcessing) {
      // اگر در زمان استراحت (Cooldown) هستیم، کلیک‌های اضافی رو کاملا نادیده بگیر
      return;
    }

    // قفل رو فعال کن
    _isProcessing = true;

    // کار اصلی رو انجام بده (مثلا باز کردن یک صفحه)
    action();

    // بعد از نیم ثانیه (یا هر زمانی که تنظیم کنی) قفل رو باز کن
    Future.delayed(Duration(milliseconds: cooldownMs), () {
      _isProcessing = false;
    });
  }
} // TODO Implement this library.
