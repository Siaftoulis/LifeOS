import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/presentation/engine/spatial_engine.dart';

Widget _engine() {
  return MaterialApp(
    home: SpatialEngine(
      layout: [
        ['home', 'a', 'b'],
      ],
      startX: 0,
      startY: 0,
      builder: (id, y, x) => Container(key: ValueKey('$id-$y-$x')),
    ),
  );
}

Future<void> _ctrlArrow(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Ctrl+arrows move, single Escape steps back', (tester) async {
    await tester.pumpWidget(_engine());
    await tester.tapAt(const Offset(400, 300));
    await tester.pump();

    await _ctrlArrow(tester, LogicalKeyboardKey.arrowRight);
    expect(find.text('[ 1 , 0 ]'), findsOneWidget);

    await _ctrlArrow(tester, LogicalKeyboardKey.arrowRight);
    expect(find.text('[ 2 , 0 ]'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('[ 1 , 0 ]'), findsOneWidget);
  });

  testWidgets('double Escape goes home and clears history', (tester) async {
    await tester.pumpWidget(_engine());
    await tester.tapAt(const Offset(400, 300));
    await tester.pump();

    await _ctrlArrow(tester, LogicalKeyboardKey.arrowRight);
    await _ctrlArrow(tester, LogicalKeyboardKey.arrowRight);
    expect(find.text('[ 2 , 0 ]'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('[ 0 , 0 ]'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('[ 0 , 0 ]'), findsOneWidget);
  });

  testWidgets('slow double Escape is two single steps', (tester) async {
    await tester.pumpWidget(_engine());
    await tester.tapAt(const Offset(400, 300));
    await tester.pump();

    await _ctrlArrow(tester, LogicalKeyboardKey.arrowRight);
    await _ctrlArrow(tester, LogicalKeyboardKey.arrowRight);
    expect(find.text('[ 2 , 0 ]'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('[ 0 , 0 ]'), findsOneWidget);
  });
}