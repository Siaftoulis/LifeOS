import 'dart:convert';
import 'dart:io';

class GitHubUpdateFetcher {
  static Future<int> fetchLatestVersionTag() async {
    try {
      final req = await HttpClient().getUrl(Uri.parse('https://api.github.com/repos/PanagiotisSiaf/LifeOS/releases/latest'));
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final tag = jsonDecode(body)['tag_name'] as String? ?? '';
        return int.tryParse(tag.replaceAll(RegExp(r'[^0-9]'), '')) ?? -1;
      }
    } catch (_) {}
    return -1;
  }
}
