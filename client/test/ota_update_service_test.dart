import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/core/update/ota_update_service.dart';

void main() {
  group('OTA Update Service Tests', () {
    test('LifeOSRelease JSON parsing with GitHub Release assets', () {
      final mockJson = {
        'tag_name': 'v1.5.7',
        'name': 'LifeOS v1.5.7 (Build #45)',
        'body': 'Highlights:\n- Silent OTA updates\n- Server Cache proxy',
        'published_at': '2026-09-01T10:00:00Z',
        'assets': [
          {
            'name': 'app-release.apk',
            'browser_download_url': 'https://github.com/Siaftoulis/LifeOS/releases/download/v1.5.7/app-release.apk'
          },
          {
            'name': 'lifeos-windows-release.zip',
            'browser_download_url': 'https://github.com/Siaftoulis/LifeOS/releases/download/v1.5.7/lifeos-windows-release.zip'
          }
        ]
      };

      final release = LifeOSRelease.fromJson(mockJson);

      expect(release.tagName, 'v1.5.7');
      expect(release.title, 'LifeOS v1.5.7 (Build #45)');
      expect(release.apkUrl, contains('app-release.apk'));
      expect(release.zipUrl, contains('lifeos-windows-release.zip'));
      expect(release.buildNumber, 45);
      expect(release.publishedAt.year, 2026);
    });

    test('LifeOSRelease JSON parsing with Host Daemon response', () {
      final mockDaemonJson = {
        'tag_name': 'v1.5.8',
        'title': 'LifeOS v1.5.8',
        'body': 'Host daemon cached build',
        'published_at': '2026-09-02T12:00:00Z',
        'build_number': 46,
        'apk_url': 'http://127.0.0.1:50051/api/v1/system/updates/download?asset=apk',
        'zip_url': 'http://127.0.0.1:50051/api/v1/system/updates/download?asset=zip',
        'cached_apk': true,
        'cached_zip': true
      };

      final release = LifeOSRelease.fromJson(mockDaemonJson);

      expect(release.tagName, 'v1.5.8');
      expect(release.title, 'LifeOS v1.5.8');
      expect(release.buildNumber, 46);
      expect(release.apkUrl, contains('download?asset=apk'));
      expect(release.zipUrl, contains('download?asset=zip'));
    });

    test('isNewer version comparisons logic', () {
      final ota = OtaUpdateService.instance;
      final now = DateTime(2026, 9, 1);

      final olderRelease = LifeOSRelease(
        tagName: 'v1.5.6',
        title: 'Older release',
        body: '',
        publishedAt: now,
        buildNumber: 44,
      );

      final sameRelease = LifeOSRelease(
        tagName: 'v1.5.7',
        title: 'Current release',
        body: '',
        publishedAt: now,
        buildNumber: 45,
      );

      final newerMinor = LifeOSRelease(
        tagName: 'v1.5.8',
        title: 'Newer minor',
        body: '',
        publishedAt: now,
        buildNumber: 46,
      );

      final newerMajor = LifeOSRelease(
        tagName: 'v2.0.0',
        title: 'New major',
        body: '',
        publishedAt: now,
        buildNumber: 50,
      );

      final newerBuildSameTag = LifeOSRelease(
        tagName: 'v1.5.7',
        title: 'Hotfix build',
        body: '',
        publishedAt: now,
        buildNumber: 46,
      );

      // Testing with base v1.5.7 (#45)
      expect(ota.isNewer(olderRelease, currentTag: 'v1.5.7', currentBuild: 45), isFalse);
      expect(ota.isNewer(sameRelease, currentTag: 'v1.5.7', currentBuild: 45), isFalse);
      expect(ota.isNewer(newerMinor, currentTag: 'v1.5.7', currentBuild: 45), isTrue);
      expect(ota.isNewer(newerMajor, currentTag: 'v1.5.7', currentBuild: 45), isTrue);
      expect(ota.isNewer(newerBuildSameTag, currentTag: 'v1.5.7', currentBuild: 45), isTrue);
    });
  });
}
