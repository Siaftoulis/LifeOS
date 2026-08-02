import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/core/obsidian/zen_collab_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ZenCollabService honest CRDT convergence test: different seed notes, character text & block order merge', () {
    final client1Messages = <Map<String, dynamic>>[];
    final client2Messages = <Map<String, dynamic>>[];

    final client1 = ZenCollabService(
      notePath: 'test_note.md',
      userId: 'user1',
      userName: 'Alice',
      userColorHex: '#FF0000',
      sendMessage: (msg) => client1Messages.add(msg),
      enableFlush: false,
    );

    final client2 = ZenCollabService(
      notePath: 'test_note.md',
      userId: 'user2',
      userName: 'Bob',
      userColorHex: '#00FF00',
      sendMessage: (msg) => client2Messages.add(msg),
      enableFlush: false,
    );

    const markdown1 = '''# Heading Client 1
- Item 1 from Alice
''';

    const markdown2 = '''# Heading Client 2
- Item 1 from Bob
- Item 2 from Bob
''';

    // Seed clients with DIFFERENT initial markdown notes
    client1.initializeFromMarkdown(markdown1);
    client2.initializeFromMarkdown(markdown2);

    // Initial sync handshake (step 1 & step 2 exchange)
    for (final msg in List<Map<String, dynamic>>.from(client1Messages)) {
      client2.handleRemoteMessage(msg);
    }
    for (final msg in List<Map<String, dynamic>>.from(client2Messages)) {
      client1.handleRemoteMessage(msg);
    }

    // Secondary handshake reply exchange
    for (final msg in List<Map<String, dynamic>>.from(client1Messages)) {
      client2.handleRemoteMessage(msg);
    }
    for (final msg in List<Map<String, dynamic>>.from(client2Messages)) {
      client1.handleRemoteMessage(msg);
    }

    // Assert no duplicate IDs in block state (catches duplicate-order bug)
    final client1Ids = client1.blocksState.map((b) => b['id'] as String).toList();
    final client2Ids = client2.blocksState.map((b) => b['id'] as String).toList();

    expect(client1Ids.toSet().length, equals(client1Ids.length), reason: 'Client 1 blocks contain duplicate IDs');
    expect(client2Ids.toSet().length, equals(client2Ids.length), reason: 'Client 2 blocks contain duplicate IDs');

    // Assert convergence: Client 1 and Client 2 final states are 100% identical in block count and order
    expect(client1.blocksState.length, equals(client2.blocksState.length));
    for (int i = 0; i < client1.blocksState.length; i++) {
      expect(client1.blocksState[i]['id'], equals(client2.blocksState[i]['id']));
      expect(client1.blocksState[i]['type'], equals(client2.blocksState[i]['type']));
      expect(client1.blocksState[i]['text'], equals(client2.blocksState[i]['text']));
    }

    client1.dispose();
    client2.dispose();
  });
}
