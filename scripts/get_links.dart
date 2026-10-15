import 'dart:convert';
import 'dart:io';

void main() async {
  // ==========================================
  // ⚙️ Bot Settings (Only change the folder name)
  // ==========================================
  String username = "Roya3N"; // Your GitHub username
  String repo = "read-app-assets"; // Repository name

  // 👈 Write the exact folder name here (with spaces, no need for %20)
  String folderName = "activities";

  // Convert spaces to standard internet format (URL Encoding)
  String encodedFolder = Uri.encodeComponent(folderName);
  String apiUrl =
      "https://api.github.com/repos/$username/$repo/contents/$encodedFolder";

  print("⏳ Connecting to GitHub server...");

  HttpClient client = HttpClient();
  try {
    HttpClientRequest request = await client.getUrl(Uri.parse(apiUrl));
    // GitHub requires a User-Agent header for API requests
    request.headers.set('User-Agent', 'Flutter-Admin-App');
    HttpClientResponse response = await request.close();

    if (response.statusCode == 200) {
      String responseBody = await response.transform(utf8.decoder).join();
      List<dynamic> files = jsonDecode(responseBody);

      List<String> rawLinks = [];

      // 🚀 Pro Upgrade: Natural Sorting
      // This ensures that image '2.png' comes before '10.png'
      files.sort((a, b) {
        int numA = int.tryParse(a['name'].split('.').first) ?? 0;
        int numB = int.tryParse(b['name'].split('.').first) ?? 0;
        return numA.compareTo(numB);
      });

      for (var file in files) {
        String name = file['name'].toLowerCase();
        // Filter to include only image files
        if (name.endsWith('.jpg') ||
            name.endsWith('.jpeg') ||
            name.endsWith('.png')) {
          rawLinks.add('    "${file['download_url']}"');
        }
      }

      print(
        "\n✅ Here you go! The complete list ready to be copied into the Admin Panel:\n",
      );
      print('  "pages": [');
      print(rawLinks.join(',\n'));
      print('  ]');
      print("\n✨ All done!");
    } else {
      print(
        "❌ Error! GitHub server did not respond. Status code: ${response.statusCode}",
      );
      print("Make sure the folder name matches exactly what is on GitHub.");
    }
  } catch (e) {
    print("❌ Connection error: $e");
  } finally {
    client.close();
  }
}
