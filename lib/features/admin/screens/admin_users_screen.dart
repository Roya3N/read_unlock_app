import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:read_unlock_app/core/backend/backend.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final Color bgDark = const Color(0xFF0D0D17);
  final Color accentColor = const Color(0xFFF59E0B); // نارنجی رادار
  String searchQuery = "";

  late Future<List<Map<String, dynamic>>> _childrenFuture = _fetchChildren();

  // ⭐️ ادمین از طریق RLS همه‌ی بچه‌ها و والدین را می‌بیند
  Future<List<Map<String, dynamic>>> _fetchChildren() async {
    final rows = await Backend.db.from('children').select().order('created_at');

    // ایمیل والدین (اگر خواندنش شکست خورد، لیست بچه‌ها باز هم نمایش داده می‌شود)
    final parentEmails = <String, String?>{};
    try {
      final parents = await Backend.db.from('parents').select('id,email,name');
      for (final p in parents) {
        parentEmails[p['id'].toString()] = p['email']?.toString();
      }
    } catch (e) {
      debugPrint("Admin parents load error: $e");
    }

    return rows.map((row) {
      final parentId = row['parent_id']?.toString();
      return <String, dynamic>{
        ...childFromRow(row),
        'parentId': parentId,
        'parentFound': parentEmails.containsKey(parentId),
        'parentEmail': parentEmails[parentId],
      };
    }).toList();
  }

  void _reload() {
    setState(() => _childrenFuture = _fetchChildren());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "User Radar 🛰️",
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
      body: Column(
        children: [
          // 🔍 نوار جستجو
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) =>
                  setState(() => searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search explorer name...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _childrenFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint("Admin users load error: ${snapshot.error}");
                }

                final docs = snapshot.data ?? [];

                // فیلتر کردن بر اساس جستجو
                final filteredDocs = docs.where((doc) {
                  final name = (doc['name'] ?? "").toString().toLowerCase();
                  return name.contains(searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No explorers found.",
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index];
                    final docId = data['id'] as String;

                    return _buildUserCard(data, docId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> data, String childId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white10,
            backgroundImage: AssetImage(
              "assets/avatars/${data['avatar'] ?? 'boy1'}.png",
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? "Unknown",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                // 💎 بخش جدید: نمایش ایمیل یا نام والد
                if (data['parentFound'] == true)
                  Text(
                    "Parent: ${data['parentEmail'] ?? 'No Email'}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  const SizedBox(height: 14), // فضای رزرو شده

                Text(
                  "ID: $childId",
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${data['xp'] ?? 0} XP 🔥",
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${data['timeBalance'] ?? 0}m Time ⏳",
                style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white54),
            onPressed: () => _showEditDialog(data, childId),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  void _showEditDialog(Map<String, dynamic> data, String childId) {
    final xpController = TextEditingController(text: data['xp'].toString());
    final timeController = TextEditingController(
      text: data['timeBalance'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(
          "Edit ${data['name']}",
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: xpController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Set XP",
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: timeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Set Time (min)",
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // ⭐️ تغییر XP و زمان فقط از طریق تابع سرور (با ثبت در تاریخچه)
                await Rewards.adminSetChildRewards(
                  childId,
                  xp: int.parse(xpController.text),
                  timeBalance: int.parse(timeController.text),
                  reason: 'admin_users_screen',
                );

                if (mounted) _reload();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Changes Saved! ✅"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                // 🚨 اگر باز هم کار نکرد، اینجا ارور رو در کنسول می‌بینی
                debugPrint("Admin Edit Error: $e");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }
}
