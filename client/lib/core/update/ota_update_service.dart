import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../api_client.dart';

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
    String? apk = json['apk_url'] as String?;
    String? zip = json['zip_url'] as String?;

    final assets = (json['assets'] as List?) ?? [];
    for (final asset in assets) {
      if (asset is Map<String, dynamic>) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        final url = asset['browser_download_url'] as String?;
        if (name.endsWith('.apk')) {
          apk = url;
        } else if (name.endsWith('.zip')) {
          zip = url;
        }
      }
    }

    final tag = json['tag_name'] as String? ?? '';
    final body = json['body'] as String? ?? '';
    final title = json['title'] as String? ?? json['name'] as String? ?? tag;

    // Extract build number: check json['build_number'] first, then tag (+38), body (Build #38), or title
    int buildNum = (json['build_number'] as num?)?.toInt() ?? 0;
    if (buildNum == 0 && tag.contains('+')) {
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

  int _currentBuildNumber = 45;
  String _currentVersionTag = 'v1.5.7';

  int get currentBuildNumber => _currentBuildNumber;
  String get currentVersionTag => _currentVersionTag;

  Future<void> initialize() async {
    updateReadyRelease.value = null;
    await _resolveCurrentVersion();
    await cleanupOldUpdates();

    // Trigger silent background check
    checkSilentUpdate();
  }

  Future<void> _resolveCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final v = info.version.trim();
      final b = int.tryParse(info.buildNumber) ?? 0;
      if (v.isNotEmpty) {
        _currentVersionTag = v.startsWith('v') ? v : 'v$v';
      }
      if (b > 0) {
        _currentBuildNumber = b;
      }
    } catch (_) {
      try {
        final jsonStr = await rootBundle.loadString('assets/version.json');
        final data = jsonDecode(jsonStr);
        _currentBuildNumber = (data['build_number'] as num?)?.toInt() ?? 45;
        _currentVersionTag = 'v${data['version'] ?? '1.5.7'}';
      } catch (_) {
        _currentBuildNumber = 45;
        _currentVersionTag = 'v1.5.7';
      }
    }
  }

  /// Silently checks for updates without throwing intrusive UI alerts
  Future<void> checkSilentUpdate({bool forceRefresh = false}) async {
    if (kIsWeb || isChecking.value || isDownloading.value) return;

    isChecking.value = true;
    try {
      await _resolveCurrentVersion();
      final latest = await fetchLatestRelease(forceRefresh: forceRefresh);
      if (latest != null) {
        if (isNewer(latest)) {
          debugPrint('[OTA] Newer version found: ${latest.tagName} (Current: $_currentVersionTag, Build: $_currentBuildNumber)');
          // Verify if already downloaded and valid
          final cached = await getCachedUpdateFile(latest);
          if (cached != null) {
            downloadedFilePath.value = cached.path;
            updateReadyRelease.value = latest;
            downloadProgress.value = 1.0;
            statusMessage.value = 'Ready to install ${latest.tagName}';
          } else {
            // Auto download release in background
            await downloadReleaseInBackground(latest);
          }
        } else {
          debugPrint('[OTA] App is up to date: Current $_currentVersionTag (#$_currentBuildNumber) >= Remote ${latest.tagName} (#${latest.buildNumber})');
          updateReadyRelease.value = null;
          downloadedFilePath.value = null;
          await cleanupOldUpdates();
        }
      }
    } catch (e) {
      debugPrint('[OTA] Background check error: $e');
    } finally {
      isChecking.value = false;
    }
  }

  bool isNewer(LifeOSRelease release, {String? currentTag, int? currentBuild}) {
    final curTag = currentTag ?? _currentVersionTag;
    final curBuild = currentBuild ?? _currentBuildNumber;

    // Compare semantic versions (e.g. 1.5.0 vs 1.5.1)
    final currentClean = curTag.split('+').first.replaceAll(RegExp(r'[^0-9\.]'), '');
    final remoteClean = release.tagName.split('+').first.replaceAll(RegExp(r'[^0-9\.]'), '');

    final semVerComp = _compareSemVer(remoteClean, currentClean);
    if (semVerComp > 0) {
      return true;
    }
    if (semVerComp < 0) {
      return false;
    }

    // SemVer is identical: compare explicit build numbers if present
    if (release.buildNumber > 0 && curBuild > 0) {
      return release.buildNumber > curBuild;
    }

    return false;
  }

  int _compareSemVer(String v1, String v2) {
    final p1 = v1.split('.').where((s) => s.isNotEmpty).map((e) => int.tryParse(e) ?? 0).toList();
    final p2 = v2.split('.').where((s) => s.isNotEmpty).map((e) => int.tryParse(e) ?? 0).toList();
    final maxLen = p1.length > p2.length ? p1.length : p2.length;

    for (int i = 0; i < maxLen; i++) {
      final num1 = i < p1.length ? p1[i] : 0;
      final num2 = i < p2.length ? p2[i] : 0;
      if (num1 > num2) return 1;
      if (num1 < num2) return -1;
    }
    return 0;
  }

  /// Fetches latest release, checking Go host-daemon first, with GitHub fallback
  Future<LifeOSRelease?> fetchLatestRelease({bool forceRefresh = false}) async {
    // 1. Try Go Host Daemon Server Cache
    try {
      String? daemonUrl;
      try {
        daemonUrl = ApiClient.instance.daemonUrl;
      } catch (_) {}

      if (daemonUrl != null && daemonUrl.isNotEmpty) {
        final refreshParam = forceRefresh ? '?refresh=true' : '';
        final uri = Uri.parse('$daemonUrl/api/v1/system/updates/latest$refreshParam');
        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is Map<String, dynamic> && data['tag_name'] != null) {
            debugPrint('[OTA] Fetched release info from Host Daemon: ${data['tag_name']}');
            return LifeOSRelease.fromJson(data);
          }
        }
      }
    } catch (e) {
      debugPrint('[OTA] Daemon release check skipped/failed: $e');
    }

    // 2. Direct GitHub Fallback
    try {
      final res = await http.get(
        Uri.parse('https://api.github.com/repos/$_githubRepo/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return LifeOSRelease.fromJson(data);
      } else {
        debugPrint('[OTA] GitHub API responded with HTTP ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('[OTA] GitHub fallback check failed: $e');
    }
    return null;
  }

  Future<Directory> _getUpdatesDirectory() async {
    Directory updatesDir;
    if (Platform.isAndroid) {
      final extCacheList = await getExternalCacheDirectories();
      if (extCacheList != null && extCacheList.isNotEmpty) {
        updatesDir = Directory('${extCacheList.first.path}/updates');
      } else {
        final extStorage = await getExternalStorageDirectory();
        if (extStorage != null) {
          updatesDir = Directory('${extStorage.path}/updates');
        } else {
          final tempDir = await getTemporaryDirectory();
          updatesDir = Directory('${tempDir.path}/updates');
        }
      }
    } else {
      final tempDir = await getTemporaryDirectory();
      updatesDir = Directory('${tempDir.path}/updates');
    }

    if (!await updatesDir.exists()) {
      await updatesDir.create(recursive: true);
    }
    return updatesDir;
  }

  Future<File?> getCachedUpdateFile(LifeOSRelease release) async {
    try {
      final dir = await _getUpdatesDirectory();
      final ext = Platform.isAndroid ? 'apk' : 'zip';
      final file = File('${dir.path}/lifeos-${release.tagName}.$ext');
      final minExpectedSize = Platform.isAndroid ? 20000000 : 10000000;
      if (await file.exists() && await file.length() > minExpectedSize) {
        return file;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> downloadReleaseInBackground(LifeOSRelease release) async {
    if (kIsWeb) return false;

    // Resolve download candidate URLs (check daemon download proxy first, then direct GitHub asset URL)
    final candidateUrls = <String>[];
    String? daemonUrl;
    try {
      daemonUrl = ApiClient.instance.daemonUrl;
    } catch (_) {}

    final assetType = Platform.isAndroid ? 'apk' : 'zip';
    if (daemonUrl != null && daemonUrl.isNotEmpty) {
      candidateUrls.add('$daemonUrl/api/v1/system/updates/download?asset=$assetType');
    }
    final directUrl = Platform.isAndroid ? release.apkUrl : release.zipUrl;
    if (directUrl != null && directUrl.isNotEmpty && !candidateUrls.contains(directUrl)) {
      candidateUrls.add(directUrl);
    }

    if (candidateUrls.isEmpty) {
      debugPrint('[OTA] No suitable download URL for platform');
      return false;
    }

    isDownloading.value = true;
    downloadProgress.value = 0.0;
    statusMessage.value = 'Downloading ${release.tagName}...';

    final client = http.Client();
    try {
      final updatesDir = await _getUpdatesDirectory();
      final ext = Platform.isAndroid ? 'apk' : 'zip';
      final saveFile = File('${updatesDir.path}/lifeos-${release.tagName}.$ext');
      final partFile = File('${updatesDir.path}/lifeos-${release.tagName}.$ext.part');

      // Check if already fully cached
      final minExpectedSize = Platform.isAndroid ? 20000000 : 10000000;
      if (await saveFile.exists() && await saveFile.length() > minExpectedSize) {
        downloadedFilePath.value = saveFile.path;
        updateReadyRelease.value = release;
        downloadProgress.value = 1.0;
        statusMessage.value = 'Ready to install ${release.tagName}';
        return true;
      }

      if (await partFile.exists()) {
        await partFile.delete().catchError((_) => partFile);
      }

      http.StreamedResponse? response;
      for (final downloadUrl in candidateUrls) {
        try {
          final request = http.Request('GET', Uri.parse(downloadUrl));
          request.headers['User-Agent'] = 'LifeOS-Client';
          final candidateRes = await client.send(request).timeout(const Duration(seconds: 15));
          if (candidateRes.statusCode == 200) {
            response = candidateRes;
            debugPrint('[OTA] Successfully connected to download stream: $downloadUrl');
            break;
          }
        } catch (e) {
          debugPrint('[OTA] Download attempt failed ($downloadUrl): $e');
        }
      }

      if (response != null && response.statusCode == 200) {
        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;
        final sink = partFile.openWrite();

        try {
          await response.stream.listen((chunk) {
            sink.add(chunk);
            receivedBytes += chunk.length;
            if (totalBytes > 0) {
              downloadProgress.value = receivedBytes / totalBytes;
            }
          }).asFuture();
        } finally {
          await sink.flush();
          await sink.close();
        }

        final partLength = await partFile.length();
        if (await partFile.exists() && partLength > minExpectedSize) {
          if (await saveFile.exists()) {
            await saveFile.delete().catchError((_) => saveFile);
          }
          await partFile.rename(saveFile.path);

          downloadedFilePath.value = saveFile.path;
          updateReadyRelease.value = release;
          downloadProgress.value = 1.0;
          statusMessage.value = 'Ready to install ${release.tagName}';
          debugPrint('[OTA] Download complete: ${saveFile.path} ($partLength bytes)');

          // Clean up older cached versions
          await cleanupOldUpdates(preserveTag: release.tagName);
          return true;
        } else {
          debugPrint('[OTA] Downloaded file invalid or too small: $partLength bytes');
          if (await partFile.exists()) {
            await partFile.delete().catchError((_) => partFile);
          }
        }
      }
    } catch (e) {
      debugPrint('[OTA] Download error: $e');
      statusMessage.value = 'Download failed';
    } finally {
      client.close();
      isDownloading.value = false;
    }
    return false;
  }

  /// Installs the prepared update on Android or Windows
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
      return await _installWindowsUpdate(targetPath);
    }
    return false;
  }

  /// Windows in-place automated updater
  Future<bool> _installWindowsUpdate(String zipPath) async {
    try {
      statusMessage.value = 'Extracting update...';
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) return false;

      final updatesDir = await _getUpdatesDirectory();
      final stagingDir = Directory('${updatesDir.path}/staging');
      if (await stagingDir.exists()) {
        await stagingDir.delete(recursive: true).catchError((_) => stagingDir);
      }
      await stagingDir.create(recursive: true);

      // Extract ZIP archive into staging
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final outPath = '${stagingDir.path}/${file.name}';
        if (file.isFile) {
          final outFile = File(outPath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(outPath).create(recursive: true);
        }
      }

      final exePath = Platform.resolvedExecutable;
      final appDir = File(exePath).parent.path;
      final runnerBat = File('${updatesDir.path}/update_runner.bat');

      // Generate atomic detached batch script
      final scriptContent = '''
@echo off
setlocal
echo Waiting for LifeOS to close...
timeout /t 2 /nobreak >nul

echo Copying updated files to $appDir...
xcopy "${stagingDir.path}\\*" "$appDir\\" /E /Y /C /H /R /K >nul

echo Cleaning up staging...
rmdir /s /q "${stagingDir.path}" >nul

echo Restarting LifeOS...
start "" "$exePath"

(goto) 2>nul & del "%~f0"
''';

      await runnerBat.writeAsString(scriptContent);

      debugPrint('[OTA] Launching detached Windows updater script: ${runnerBat.path}');
      await Process.start(
        'cmd.exe',
        ['/c', runnerBat.path],
        mode: ProcessStartMode.detached,
      );

      // Exit cleanly so updater script can overwrite locked binaries
      exit(0);
    } catch (e) {
      debugPrint('[OTA] Windows in-place update error: $e');
      statusMessage.value = 'Update extraction failed';
      return false;
    }
  }

  /// Cleans obsolete and orphan update artifacts from local device cache
  Future<void> cleanupOldUpdates({String? preserveTag}) async {
    try {
      final dir = await _getUpdatesDirectory();
      if (!await dir.exists()) return;

      final files = await dir.list().toList();
      for (final entity in files) {
        if (entity is File) {
          final name = entity.uri.pathSegments.last;
          if (name.endsWith('.part')) {
            // Delete dangling partial downloads
            await entity.delete().catchError((_) => entity);
          } else if (preserveTag != null && !name.contains(preserveTag)) {
            // Delete previous versions
            await entity.delete().catchError((_) => entity);
          } else if (preserveTag == null && updateReadyRelease.value == null) {
            // No update pending: purge old downloads
            await entity.delete().catchError((_) => entity);
          }
        }
      }
    } catch (e) {
      debugPrint('[OTA] Storage cleanup error: $e');
    }
  }

  void dismissUpdateNotification() {
    updateReadyRelease.value = null;
  }
}
