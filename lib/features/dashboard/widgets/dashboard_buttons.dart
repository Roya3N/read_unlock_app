import 'package:flutter/material.dart';
import 'package:read_unlock_app/core/theme/app_style.dart';

class DashboardPrimaryButton extends StatelessWidget {
  const DashboardPrimaryButton({
    super.key,
    required this.text,
    required this.color,
    this.onTap,
  });

  final String text;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(color: color, borderRadius: AppRadii.r16),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class DashboardOutlineButton extends StatelessWidget {
  const DashboardOutlineButton({
    super.key,
    required this.text,
    required this.onTap,
    this.borderColor = AppColors.primary,
  });

  final String text;
  final VoidCallback onTap;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: AppRadii.r16,
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            color: borderColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
