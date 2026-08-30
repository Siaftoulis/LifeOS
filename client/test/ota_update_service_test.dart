import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/core/update/ota_update_service.dart';

void main() {
  group('OTA Update Service Tests', () {
    test('LifeOSRelease JSON parsing with APK and ZIP assets', () {
      final mockJson = {
        'tag_name': 'v1.5.1',
        'name': 'Release Build #3 — LifeOS Fast Sync & Audio',
        'body': 'Highlights:\n- Silent OTA updates\n- Rollback support',
        'published_at': '2026-08-30T10:00:00Z',
        'assets': [
          {
            'name': 'app-release.apk',
            'browser_download_url': 'https://github.com/PanagiotisSiaf/LifeOS/releases/download/v1.5.1/app-release.apk'
          },
          {
            'name': 'lifeos-windows-release.zip',
            'browser_download_url': 'https://github.com/PanagiotisSiaf/LifeOS/releases/download/v1.5.1/lifeos-windows-release.zip'
          }
        ]
      };

      final release = LifeOSRelease.fromJson(mockJson);

      expect(release.tagName, 'v1.5.1');
      expect(release.title, 'Release Build #3 — LifeOS Fast Sync & Audio');
      expect(release.apkUrl, contains('app-release.apk'));
      expect(release.zipUrl, contains('lifeos-windows-release.zip'));
      expect(release.publishedAt.year, 2026);
    });

    test('isNewer version comparisons', () {
      final ota = OtaUpdateService.instance;

      final olderRelease = LifeOSRelease(
        tagName: 'v1.4.9',
        title: 'Old release',
        body: '',
        publishedAt: DateTime.now(),
        buildNumber: 1,
      );

      final newerRelease = LifeOSRelease(
        tagName: 'v1.5.2',
        title: 'New release',
        body: '',
        publishedAt: DateTime.now(),
        buildNumber: 5,
      );

      final sameRelease = LifeOSRelease(
        tagName: 'v1.5.0',
        title: 'Current release',
        body: '',
        publishedAt: DateTime.now(),
        buildNumber: 2,
      );

      expect(ota.isNewer(newerRelease), isTrue);
      expect(ota.isNewer(olderRelease), isFalse);
      expect(ota.isNewer(sameRelease), isFalse);
    });
  });
}
