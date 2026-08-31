import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class LifeOSRelease {
  final String tagName;
  final String title;
  final String body;
  final DateTime publishedAt;
  final String? apkUrl;
  final String? zipUrl;
  final int buildNumber;

  const LifeOSRelease({
    required this.tagName,
    required this.title,
    required this.body,
    required this.publishedAt,
    this.apkUrl,
    this.zipUrl,
    required this.buildNumber,
  });

  factory LifeOSRelease.fromJson(Map<String, dynamic> json) {
    final assets = (json['assets'] as List?) ?? [];
    String? apk;
    String? zip;

    for (final asset in assets) {
      final name = (asset['name'] as String? ?? '').toLowerCase();
      final url = asset['browser_download_url'] as String?;
      if (name.endsWith('.apk')) {
        apk = url;
      } else if (name.endsWith('.zip')) {
        zip = url;
      }
    }

    final tag = json['tag_name'] as String? ?? '';
    final body = json['body'] as String? ?? '';
    final title = json['name'] as String? ?? tag;

    // Extract build number accurately from tag (+38), body (Build #38), or title
    int buildNum = 0;
    if (tag.contains('+')) {
      buildNum = int.tryParse(tag.split('+').last) ?? 0;
    }
    if (buildNum == 0) {
      final buildMatch = RegExp(r'(?:Build\s*#|build_number[\s:]+)(\d+)', caseSensitive: false).firstMatch(body);
      if (buildMatch != null) {
        buildNum = int.tryParse(buildMatch.group(1)!) ?? 0;
      }
    }
    if (buildNum == 0) {
      final titleMatch = RegExp(r'Build\s*#(\d+)', caseSensitive: false).firstMatch(title);
      if (titleMatch != null) {
        buildNum = int.tryParse(titleMatch.group(1)!) ?? 0;
      }
    }
    if (buildNum == 0 && RegExp(r'^v?\d+$').hasMatch(tag.trim())) {
      buildNum = int.tryParse(tag.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }

    return LifeOSRelease(
      tagName: tag,
      title: title,
      body: body,
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? '') ?? DateTime.now(),
      apkUrl: apk,
      zipUrl: zip,
      buildNumber: buildNum,
    );
  }
}

class OtaUpdateService {
  static final OtaUpdateService instance = OtaUpdateService._internal();
  OtaUpdateService._internal();

  static const MethodChannel _channel = MethodChannel('com.lifeos.app/ota_installer');
  static const String _githubRepo = 'Siaftoulis/LifeOS';

  final ValueNotifier<bool> isChecking = ValueNotifier(false);
  final ValueNotifier<bool> isDownloading = ValueNotifier(false);
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  final ValueNotifier<LifeOSRelease?> updateReadyRelease = ValueNotifier(null);
  final ValueNotifier<String?> downloadedFilePath = ValueNotifier(null);
  final ValueNotifier<String> statusMessage = ValueNotifier('');

  int _currentBuildNumber = 39;
  String _currentVersionTag = 'v1.5.1';

  int get currentBuildNumber => _currentBuildNumber;
  String get currentVersionTag => _currentVersionTag;

  Future<void> initialize() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/version.json').catchError((_) => '{"build_number":39, "version":"1.5.1"}');
      final data = jsonDecode(jsonStr);
      _currentBuildNumber = data['build_number'] ?? 39;
      _currentVersionTag = 'v${data['version'] ?? '1.5.1'}';
    } catch (_) {
      _currentBuildNumber = 39;
      _currentVersionTag = 'v1.5.1';
    }

    // Trigger silent background check
    checkSilentUpdate();
  }

  /// Silently checks for updates without throwing UI alerts
  Future<void> checkSilentUpdate() async {
    if (kIsWeb || isChecking.value || isDownloading.value) return;

    isChecking.value = true;
    try {
      final latest = await fetchLatestRelease();
      if (latest != null && isNewer(latest)) {
        debugPrint('[OTA] Newer version found: ${latest.tagName} (Current: $_currentVersionTag, Build: $_currentBuildNumber)');
        // Start background download automatically
        await downloadReleaseInBackground(latest);
      }
    } catch (e) {
      debugPrint('[OTA] Background check failed: $e');
    } finally {
      isChecking.value = false;
    }
  }

  bool isNewer(LifeOSRelease release) {
    // Compare semantic versions (e.g. 1.5.0 vs 1.5.1)
    final currentClean = _currentVersionTag.split('+').first.replaceAll(RegExp(r'[^0-9\.]'), '');
    final remoteClean = release.tagName.split('+').first.replaceAll(RegExp(r'[^0-9\.]'), '');

    final semVerComp = _compareSemVer(remoteClean, currentClean);
    if (semVerComp > 0) {
      return true;
    }
    if (semVerComp < 0) {
      return false;
    }

    // SemVer is identical: compare explicit build numbers if present
    if (release.buildNumber > 0 && _currentBuildNumber > 0) {
      return release.buildNumber > _currentBuildNumber;
    }

    return false;
  }

  int _compareSemVer(String v1, String v2) {
    final p1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final p2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final maxLen = p1.length > p2.length ? p1.length : p2.length;

    for (int i = 0; i < maxLen; i++) {
      final num1 = i < p1.length ? p1[i] : 0;
      final num2 = i < p2.length ? p2[i] : 0;
      if (num1 > num2) return 1;
      if (num1 < num2) return -1;
    }
    return 0;
  }

  Future<LifeOSRelease?> fetchLatestRelease() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.github.com/repos/$_githubRepo/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return LifeOSRelease.fromJson(data);
      }
    } catch (e) {
      debugPrint('[OTA] Failed to fetch latest release: $e');
    }
    return null;
  }

  Future<List<LifeOSRelease>> fetchReleaseHistory() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.github.com/repos/$_githubRepo/releases?per_page=20'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => LifeOSRelease.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('[OTA] Failed to fetch release history: $e');
    }
    return [];
  }

  Future<bool> downloadReleaseInBackground(LifeOSRelease release) async {
    final downloadUrl = Platform.isAndroid ? release.apkUrl : release.zipUrl;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      debugPrint('[OTA] No suitable asset found for platform');
      return false;
    }

    isDownloading.value = true;
    downloadProgress.value = 0.0;
    statusMessage.value = 'Downloading ${release.tagName}...';

    try {
      final tempDir = await getTemporaryDirectory();
      final updatesDir = Directory('${tempDir.path}/updates');
      if (!await updatesDir.exists()) {
        await updatesDir.create(recursive: true);
      }

      final ext = Platform.isAndroid ? 'apk' : 'zip';
      final saveFile = File('${updatesDir.path}/lifeos-${release.tagName}.$ext');

      // If already cached and valid size
      if (await saveFile.exists() && await saveFile.length() > 5000000) {
        downloadedFilePath.value = saveFile.path;
        updateReadyRelease.value = release;
        downloadProgress.value = 1.0;
        statusMessage.value = 'Ready to install ${release.tagName}';
        return true;
      }

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request).timeout(const Duration(minutes: 10));

      if (response.statusCode == 200) {
        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;
        final sink = saveFile.openWrite();

        await response.stream.listen((chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            downloadProgress.value = receivedBytes / totalBytes;
          }
        }).asFuture();

        await sink.flush();
        await sink.close();

        if (await saveFile.exists() && await saveFile.length() > 1000000) {
          downloadedFilePath.value = saveFile.path;
          updateReadyRelease.value = release;
          downloadProgress.value = 1.0;
          statusMessage.value = 'Ready to install ${release.tagName}';
          debugPrint('[OTA] Download complete: ${saveFile.path}');
          return true;
        }
      }
    } catch (e) {
      debugPrint('[OTA] Download error: $e');
      statusMessage.value = 'Download failed';
    } finally {
      isDownloading.value = false;
    }
    return false;
  }

  /// Installs the prepared update or triggers a rollback
  Future<bool> installUpdate({String? customFilePath}) async {
    final targetPath = customFilePath ?? downloadedFilePath.value;
    if (targetPath == null || targetPath.isEmpty) return false;

    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<bool>('installApk', {'filePath': targetPath});
        return result ?? false;
      } catch (e) {
        debugPrint('[OTA] Android native install invocation error: $e');
        return false;
      }
    } else if (Platform.isWindows) {
      try {
        // On Windows, open explorer pointing to the downloaded zip/binary
        await Process.start('explorer.exe', ['/select,', targetPath]);
        return true;
      } catch (e) {
        debugPrint('[OTA] Windows launcher error: $e');
        return false;
      }
    }
    return false;
  }

  /// 1-Tap Rollback action from Settings
  Future<bool> triggerRollback(LifeOSRelease previousRelease) async {
    statusMessage.value = 'Preparing rollback to ${previousRelease.tagName}...';
    final success = await downloadReleaseInBackground(previousRelease);
    if (success) {
      return installUpdate();
    }
    return false;
  }

  void dismissUpdateNotification() {
    updateReadyRelease.value = null;
  }
}
