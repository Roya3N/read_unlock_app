import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:read_unlock_app/core/services/secure_storage_service.dart';
import 'package:read_unlock_app/features/auth/screens/login_switcher_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false; // 👈 اضافه کردن وضعیت لودینگ

  // ==========================================
  // 💥 متد نابودگر (حذف اکانت) - نسخه Pro
  // ==========================================
  Future<void> _deleteAccountLogic(BuildContext context) async {
    setState(() {
      _isLoading = true; // تغییر وضعیت به در حال بارگذاری
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String uid = user.uid;
      var db = FirebaseFirestore.instance;

      // 👈 استفاده از WriteBatch برای حذف ایمن و یکپارچه
      WriteBatch batch = db.batch();

      // ۱. آماده‌سازی حذف بچه‌ها
      var childrenSnap = await db
          .collection('parents')
          .doc(uid)
          .collection('children')
          .get();
      for (var doc in childrenSnap.docs) {
        batch.delete(doc.reference); // اضافه کردن به لیست حذفیات
      }

      // ۲. آماده‌سازی حذف والد
      DocumentReference parentRef = db.collection('parents').doc(uid);
      batch.delete(parentRef);

      // اجرای قطعی عملیات دیتابیس در یک لحظه
      await batch.commit();

      // ۳. پاک کردن پین‌کد از حافظه امن گوشی (Pro Feature)
      await SecureStorageService.deleteParentPin();
      await SecureStorageService.resetLockout();
      // ۴. پاک کردن کاربر از سیستم احراز هویت
      await user.delete();

      // ۵. پرتاب به صفحه ورود
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginSwitcherScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'For security reasons, please log out and log in again to delete your account.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("خطا در حذف اکانت: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // پایان حالت لودینگ
        });
      }
    }
  }

  // ==========================================
  // ⚠️ دیالوگ هشدار قبل از حذف
  // ==========================================
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          !_isLoading, // وقتی در حال لود است با کلیک در بیرون بسته نشود
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.redAccent, size: 30),
              SizedBox(width: 10),
              Text(
                "Delete Account?",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.",
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.2),
                foregroundColor: Colors.redAccent,
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccountLogic(context);
              },
              child: const Text(
                "Yes, Delete",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              color: const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.redAccent,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.redAccent,
                      ),
                title: const Text(
                  "Delete Account Permanently",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Erase all data and log out",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: _isLoading
                    ? null
                    : () => _showDeleteConfirmation(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
