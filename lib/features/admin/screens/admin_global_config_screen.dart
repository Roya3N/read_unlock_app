import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminGlobalConfigScreen extends StatefulWidget {
  const AdminGlobalConfigScreen({super.key});

  @override
  State<AdminGlobalConfigScreen> createState() =>
      _AdminGlobalConfigScreenState();
}

class _AdminGlobalConfigScreenState extends State<AdminGlobalConfigScreen> {
  final Color bgDark = const Color(0xFF0D0D17);
  final Color cyberTeal = const Color(0xFF14B8A6);
  final Color accentPurple = const Color(0xFF8B5CF6);

  final TextEditingController _versionController = TextEditingController();
  final TextEditingController _privacyUrlController = TextEditingController();
  final TextEditingController _supportEmailController = TextEditingController();

  bool _forceUpdate = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadGlobalConfig();
  }

  Future<void> _loadGlobalConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('global')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _versionController.text = data['app_version'] ?? "1.0.0";
        _privacyUrlController.text =
            data['privacy_policy_url'] ?? "https://yourwebsite.com/privacy";
        _supportEmailController.text =
            data['support_email'] ?? "support@yourwebsite.com";
        _forceUpdate = data['force_update'] ?? false;
      } else {
        _versionController.text = "1.0.0";
        _privacyUrlController.text = "https://";
        _supportEmailController.text = "admin@email.com";
      }
    } catch (e) {
      debugPrint("Error loading global config: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    try {
      await FirebaseFirestore.instance.collection('config').doc('global').set({
        'app_version': _versionController.text.trim(),
        'privacy_policy_url': _privacyUrlController.text.trim(),
        'support_email': _supportEmailController.text.trim(),
        'force_update': _forceUpdate,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Global Settings Deployed! 🌍",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: cyberTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving global config: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _versionController.dispose();
    _privacyUrlController.dispose();
    _supportEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Global Config 🌍",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cyberTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("🚀 APP VERSION CONTROL"),
                  _buildSwitchField(),
                  const SizedBox(height: 15),
                  _buildTextField(
                    "Current App Version",
                    Icons.numbers_rounded,
                    _versionController,
                  ),
                  const SizedBox(height: 30),

                  _buildSectionTitle("🔗 EXTERNAL LINKS"),
                  _buildTextField(
                    "Privacy Policy URL",
                    Icons.link_rounded,
                    _privacyUrlController,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    "Support Email",
                    Icons.email_rounded,
                    _supportEmailController,
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cyberTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "SAVE GLOBAL DATA",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ).animate().scale(delay: 200.ms),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSwitchField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _forceUpdate
              ? Colors.redAccent.withOpacity(0.5)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.system_update_rounded,
            color: _forceUpdate ? Colors.redAccent : cyberTeal,
            size: 30,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Force Update",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _forceUpdate
                      ? "Users MUST update to continue"
                      : "Update is optional",
                  style: TextStyle(
                    color: _forceUpdate ? Colors.redAccent : Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _forceUpdate,
            activeColor: Colors.redAccent,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() => _forceUpdate = value);
            },
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: cyberTeal),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
