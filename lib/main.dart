import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:read_unlock_app/core/backend/backend.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:read_unlock_app/core/utils/app_state.dart';
import 'package:read_unlock_app/features/admin/screens/admin_uploader_screen.dart';
import 'package:read_unlock_app/features/auth/screens/login_switcher_screen.dart';
import 'package:read_unlock_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:read_unlock_app/features/system/screens/force_update_screen.dart';
import 'package:read_unlock_app/core/services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 Pro Initialization Sequence
  try {
    // Supabase: sign-in, data and rewards. The anon key is public by design;
    // row-level security protects the data.
    await Supabase.initialize(
      url: 'https://esruowjvnottjknrkubg.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVzcnVvd2p2bm90dGprbnJrdWJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MDQ4MDEsImV4cCI6MjA5Mjk4MDgwMX0.a_D-vnR-1UNlSgNDojNGO4FC9TlQP2W8pLpLJMcnwNo',
    );

    // App Services
    await AudioService.init();
    await AppState.load();

    debugPrint("All Systems Connected! 🚀 (Supabase)");
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

      final settings = await AppConfig.get('app_settings');
      final minVersionCode = settings['min_version_code'];
      if (minVersionCode is num) {
        return currentBuildNumber < minVersionCode.toInt();
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

        return StreamBuilder<AuthState>(
          stream: Backend.db.auth.onAuthStateChange,
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting &&
                Backend.currentUser == null) {
              return _buildLoadingScreen(
                const Color(0xFF8B5CF6),
                "Authenticating...",
              );
            }

            final session =
                authSnapshot.data?.session ?? Backend.db.auth.currentSession;
            if (session != null) {
              return const _SignedInGate();
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

/// Loads this parent's children from the server once per sign-in, then
/// shows the dashboard.
class _SignedInGate extends StatefulWidget {
  const _SignedInGate();

  @override
  State<_SignedInGate> createState() => _SignedInGateState();
}

class _SignedInGateState extends State<_SignedInGate> {
  late final Future<void> _sync = AppState.syncChildren();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _sync,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F13),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            ),
          );
        }
        return const DashboardScreen();
      },
    );
  }
}
