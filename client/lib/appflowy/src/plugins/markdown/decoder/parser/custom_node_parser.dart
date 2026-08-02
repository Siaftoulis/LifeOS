import 'package:appflowy_editor/appflowy_editor.dart';

abstract class CustomNodeParser {
  Node? transform(String input);
}
