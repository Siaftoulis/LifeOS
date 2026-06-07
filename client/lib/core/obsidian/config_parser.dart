import 'dart:io';
import 'dart:convert';

class ObsidianConfig {
  bool showLineNumber = false;
  bool showFrontmatter = false;
  String theme = 'everforest';
}

class ConfigParser {
  final String vaultPath;
  
  ConfigParser(this.vaultPath);

  Future<ObsidianConfig> parseConfig() async {
    final config = ObsidianConfig();
    final obsidianDir = Directory('$vaultPath/.obsidian');
    
    if (await obsidianDir.exists()) {
      try {
        final appJson = File('${obsidianDir.path}/app.json');
        if (await appJson.exists()) {
          final data = jsonDecode(await appJson.readAsString());
          config.showLineNumber = data['showLineNumber'] ?? false;
          config.showFrontmatter = data['showFrontmatter'] ?? false;
        }
        
        final appearanceJson = File('${obsidianDir.path}/appearance.json');
        if (await appearanceJson.exists()) {
          final data = jsonDecode(await appearanceJson.readAsString());
          config.theme = data['cssTheme'] ?? 'everforest';
        }
      } catch (e) {
        // Fallback to default if there's an error parsing
      }
    }
    return config;
  }
}
