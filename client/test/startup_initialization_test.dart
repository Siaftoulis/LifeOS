import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/api_client.dart';
import 'package:lifeos_client/database/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Startup & URL Resolution Safe Tests', () {
    test('PreferencesService defaults do not throw StateError on VM', () {
      expect(PreferencesService.cachedBaseUrl.value, isNotEmpty);
      expect(PreferencesService.cachedDaemonUrl.value, isNotEmpty);
      expect(PreferencesService.cachedBaseUrl.value, contains('50051'));
    });

    test('ApiClient discovery behaves properly on native VM without throwing', () async {
      final daemonUrl = await ApiClient.discoverDaemonUrl();
      expect(daemonUrl, isNotEmpty);
      final baseUrl = await ApiClient.discoverBaseUrl();
      expect(baseUrl, isNotEmpty);
    });
  });
}
