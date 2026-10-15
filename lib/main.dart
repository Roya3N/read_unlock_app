import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:read_unlock_app/features/admin/screens/admin_uploader_screen.dart';
import 'package:read_unlock_app/features/auth/screens/login_switcher_screen.dart';
import 'package:read_unlock_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:read_unlock_app/features/system/screens/force_update_screen.dart';
import 'firebase_options.dart';
import 'package:read_unlock_app/core/services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 Pro Initialization Sequence
  try {
    // 1. Firebase Init
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Supabase Init 🌟
    await Supabase.initialize(
      url: 'https://esruowjvnottjknrkubg.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVzcnVvd2p2bm90dGprbnJrdWJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MDQ4MDEsImV4cCI6MjA5Mjk4MDgwMX0.a_D-vnR-1UNlSgNDojNGO4FC9TlQP2W8pLpLJMcnwNo',
    );

    // 3. App Services
    await AudioService.init();
    await AppState.load();

    debugPrint("All Systems Connected! 🚀 (Firebase & Supabase)");
  } catch (e) {
    debugPrint("Initialization Critical Error: $e ❌");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Unlock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFF3B82F6),
          surface: Color(0xFF1E1E24),
        ),
        useMaterial3: true,
        // Pro UI: استایل سراسری برای دکمه‌ها و اسنک‌بارها
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E1E24).withOpacity(0.95),
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      home: const AppRootGate(),
    );
  }
}

class AppRootGate extends StatefulWidget {
  const AppRootGate({super.key});

  @override
  State<AppRootGate> createState() => _AppRootGateState();
}

class _AppRootGateState extends State<AppRootGate> {
  // 🛠️ درِ مخفی ادمین (برای تست سریع)
  static const bool _forceAdminMode = false;

  Future<bool> _requiresForceUpdate() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      DocumentSnapshot configSnap = await FirebaseFirestore.instance
          .collection('config')
          .doc('app_settings')
          .get();

      if (configSnap.exists && configSnap.data() != null) {
        int minVersionCode = configSnap.get('min_version_code') ?? 1;
        return currentBuildNumber < minVersionCode;
      }
    } catch (e) {
      debugPrint("Version Check Error: $e");
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_forceAdminMode) return const AdminBookUploader();

    return FutureBuilder<bool>(
      future: _requiresForceUpdate(),
      builder: (context, versionSnapshot) {
        // ⏳ Pro Splash Screen (زمان چک کردن دیتابیس)
        if (versionSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen(
            const Color(0xFFFBBF24),
            "Checking Version...",
          );
        }

        if (versionSnapshot.data == true) {
          return const ForceUpdateScreen();
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen(
                const Color(0xFF8B5CF6),
                "Authenticating...",
              );
            }

            if (authSnapshot.hasData) {
              return const DashboardScreen();
            }

            return const LoginSwitcherScreen();
          },
        );
      },
    );
  }

  // 🎨 طراحی متمرکز لودینگ (Pro Upgrade)
  Widget _buildLoadingScreen(Color accentColor, String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: accentColor),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: accentColor.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
