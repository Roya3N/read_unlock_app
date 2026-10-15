import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF4A90E2);
  static const background = Color(0xFFF4F8FF);
}

abstract final class AppRadii {
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
}

abstract final class AppSpacing {
  static const s8 = SizedBox(height: 8);
  static const s10 = SizedBox(height: 10);
  static const s12 = SizedBox(height: 12);
  static const s16 = SizedBox(height: 16);
  static const s20 = SizedBox(height: 20);
  static const s30 = SizedBox(height: 30);
  static const s40 = SizedBox(height: 40);
}

