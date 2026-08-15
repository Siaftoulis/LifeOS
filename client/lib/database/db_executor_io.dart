import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

Future<QueryExecutor> openDbExecutor() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  return NativeDatabase(File('${dbFolder.path}/lifeos.sqlite'));
}
