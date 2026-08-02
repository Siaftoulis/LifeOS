import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/presentation/widgets/zen_workspace.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ZenWorkspace renders AppFlowy Editor cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ZenWorkspace(),
      ),
    );

    await tester.pump();

    expect(find.byType(ZenWorkspace), findsOneWidget);
  });
}
