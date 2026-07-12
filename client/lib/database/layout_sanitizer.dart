import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/feature_registry.dart';

Future<File> getPrefsFile(Directory? cachedDir) async {
  if (Platform.isAndroid) {
    final dir = cachedDir ?? await getApplicationDocumentsDirectory();
    return File('${dir.path}/prefs.json');
  }
  return File('prefs.json');
}

Future<String> getVaultPath() async {
  if (Platform.isAndroid || Platform.isIOS) {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/vault';
  }
  return 'vault';
}

List<List<String>> sanitizeLayout(List<List<String>> val) {
  if (val.isEmpty || val[0].isEmpty) return [['home', 'configurator', 'rpg_hub']];

  // Clean invalid modules first
  for (int r = 0; r < val.length; r++) {
    for (int c = 0; c < val[r].length; c++) {
      final mod = val[r][c];
      if (mod != 'void' && mod != '' && !FeatureRegistry.availableModules.contains(mod)) {
        val[r][c] = 'void';
      }
    }
  }
  bool hasHome = false;
  bool hasConfigurator = false;
  for (final row in val) {
    if (row.contains('home')) hasHome = true;
    if (row.contains('configurator')) hasConfigurator = true;
  }

  if (!hasHome) {
    bool placed = false;
    for (int r = 0; r < val.length; r++) {
      for (int c = 0; c < val[r].length; c++) {
        if (val[r][c] == 'void' || val[r][c] == '') {
          val[r][c] = 'home';
          placed = true;
          break;
        }
      }
      if (placed) break;
    }
    if (!placed) val[0][0] = 'home';
  }

  if (!hasConfigurator) {
    bool placed = false;
    for (int r = 0; r < val.length; r++) {
      for (int c = 0; c < val[r].length; c++) {
        if (val[r][c] == 'void' || val[r][c] == '') {
          val[r][c] = 'configurator';
          placed = true;
          break;
        }
      }
      if (placed) break;
    }
    if (!placed) {
      if (val[0].length > 1) val[0][1] = 'configurator';
      else if (val.length > 1) val[1][0] = 'configurator';
      else val.add(['configurator']);
    }
  }
  return val;
}
