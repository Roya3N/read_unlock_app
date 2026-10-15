//dart run get_supabase_links.dart
//dart run scripts/get_supabase_links.dart

import 'dart:convert';
import 'dart:io';

void main() async {
  // ==========================================
  // ⚙️ Supabase Settings
  // ==========================================
  const String projectId =
      "esruowjvnottjknrkubg"; // I extracted this from your screenshot! 😎
  const String anonKey = "PASTE_YOUR_ANON_KEY_HERE"; // 👈 Paste your key here
  const String bucketName = "images";

  // 👈 Update this to the exact folder where you drop the story images
  // Example: "books/10-12-pre teens/Advanced/my-story-name"
  const String folderPath = "books/YOUR_CATEGORY/YOUR_STORY";

  final String apiUrl =
      "https://$projectId.supabase.co/storage/v1/object/list/$bucketName";
  final String baseUrl =
      "https://$projectId.supabase.co/storage/v1/object/public/$bucketName/";

  print("⏳ Connecting to Supabase API...");

  HttpClient client = HttpClient();
  try {
    HttpClientRequest request = await client.postUrl(Uri.parse(apiUrl));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer $anonKey');

    // Supabase needs to know which folder to look inside
    final body = jsonEncode({
      "prefix": folderPath,
      "limit": 100,
      "offset": 0,
      "sortBy": {"column": "name", "order": "asc"},
    });
    request.write(body);

    HttpClientResponse response = await request.close();

    if (response.statusCode == 200) {
      String responseBody = await response.transform(utf8.decoder).join();
      List<dynamic> files = jsonDecode(responseBody);

      List<String> rawLinks = [];

      // Filter out empty folders and keep only files
      var validFiles = files
          .where(
            (file) =>
                file['name'] != null && file['name'].toString().contains('.'),
          )
          .toList();

      // Pro Trick: Sort files numerically so 10.png doesn't come before 2.png
      validFiles.sort((a, b) {
        String nameA = a['name'];
        String nameB = b['name'];
        int numA = int.tryParse(nameA.split('.').first) ?? 0;
        int numB = int.tryParse(nameB.split('.').first) ?? 0;
        return numA.compareTo(numB);
      });

      for (var file in validFiles) {
        // Construct the full public URL
        rawLinks.add('    "$baseUrl$folderPath/${file['name']}"');
      }

      if (rawLinks.isEmpty) {
        print("❌ No images found in '$folderPath'. Check the spelling!");
        return;
      }

      print("\n✅ Success! Links are ready for your JSON:\n");
      print('  "pages": [');
      print(rawLinks.join(',\n'));
      print('  ]');
      print("\n✨ Copy this list and use it in your Admin Uploader.");
    } else {
      print("❌ Server Error: ${response.statusCode}");
      print("Please check your Anon Key and Folder Path.");
    }
  } catch (e) {
    print("❌ Network Error: $e");
  } finally {
    client.close();
  }
}
