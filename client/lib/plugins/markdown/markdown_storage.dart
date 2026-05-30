import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MarkdownStorage {
  static Future<String> getRootPath() async {
    final docDir = await getApplicationDocumentsDirectory();
    final notesDir = Directory('${docDir.path}/LifeOS_Notes');
    if (!await notesDir.exists()) await notesDir.create(recursive: true);
    return notesDir.path;
  }

  static Future<void> saveNote(String filename, String content) async {
    final root = await getRootPath();
    final file = File('$root/$filename');
    await file.writeAsString(content);
  }
}
