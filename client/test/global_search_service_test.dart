import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/core/search/global_search_service.dart';

void main() {
  group('Global Search Service Tests', () {
    test('Empty query returns default rich suggestions', () async {
      final service = GlobalSearchService.instance;
      final results = await service.search('');

      expect(results, isNotEmpty);
      expect(results.any((r) => r.title.contains('Updates')), isTrue);
      expect(results.any((r) => r.title.contains('Equalizer')), isTrue);
      expect(results.any((r) => r.title.contains('Gallery')), isTrue);
    });

    test('Settings category filtering and query match', () async {
      final service = GlobalSearchService.instance;
      final results = await service.search('update', category: SearchCategory.settings);

      expect(results, isNotEmpty);
      expect(results.first.category, SearchCategory.settings);
      expect(results.first.title.toLowerCase(), contains('update'));
    });

    test('Category filtering respects category choice', () async {
      final service = GlobalSearchService.instance;
      final musicOnly = await service.search('matrix', category: SearchCategory.music);
      
      // 'matrix' is a spatial settings action, so music category should not include it
      expect(musicOnly.any((r) => r.category == SearchCategory.settings), isFalse);
    });
  });
}
