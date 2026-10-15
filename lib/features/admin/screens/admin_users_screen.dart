import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final Color bgDark = const Color(0xFF0D0D17);
  final Color accentColor = const Color(0xFFF59E0B); // نارنجی رادار
  String searchQuery = "";

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
            child: StreamBuilder<QuerySnapshot>(
              // ⭐️ استفاده از collectionGroup برای پیدا کردن تمام بچه‌ها در کل دیتابیس
              stream: FirebaseFirestore.instance
                  .collectionGroup('children')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

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
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    final docId = filteredDocs[index].id;
                    final parentRef = filteredDocs[index]
                        .reference
                        .parent
                        .parent; // ارجاع به والد

                    return _buildUserCard(data, docId, parentRef);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    Map<String, dynamic> data,
    String childId,
    DocumentReference? parentRef,
  ) {
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
                FutureBuilder<DocumentSnapshot>(
                  future: parentRef?.get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final pData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      return Text(
                        "Parent: ${pData['email'] ?? 'No Email'}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                    return const SizedBox(
                      height: 14,
                    ); // فضای رزرو شده تا لود بشه
                  },
                ),

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
            onPressed: () => _showEditDialog(data, childId, parentRef),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  void _showEditDialog(
    Map<String, dynamic> data,
    String childId,
    DocumentReference? parentRef,
  ) {
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
                // ⭐️ استفاده مستقیم از رفرنس خود داکیومنت برای امنیت و سرعت بیشتر
                await FirebaseFirestore.instance
                    .collection('parents')
                    .doc(parentRef?.id) // گرفتن ID والد
                    .collection('children')
                    .doc(childId)
                    .update({
                      'xp': int.parse(xpController.text),
                      'timeBalance': int.parse(timeController.text),
                    });

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
