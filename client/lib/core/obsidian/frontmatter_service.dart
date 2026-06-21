import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

class FrontmatterService {
  static final RegExp _frontmatterRegExp = RegExp(r'^---\n(.*?)\n---', multiLine: true, dotAll: true);

  /// Extracts and parses the YAML frontmatter from markdown content.
  /// Returns an empty map if no frontmatter is found.
  static Map<String, dynamic> parseFrontmatter(String content) {
    final match = _frontmatterRegExp.firstMatch(content);
    if (match == null) return {};

    try {
      final yamlString = match.group(1)!;
      final yamlMap = loadYaml(yamlString);
      if (yamlMap is YamlMap) {
        return _convertYamlMapToDartMap(yamlMap);
      }
    } catch (e) {
      print('FrontmatterService parse error: $e');
    }
    return {};
  }

  static Map<String, dynamic> _convertYamlMapToDartMap(YamlMap yamlMap) {
    final Map<String, dynamic> map = {};
    for (final entry in yamlMap.entries) {
      if (entry.value is YamlMap) {
        map[entry.key.toString()] = _convertYamlMapToDartMap(entry.value);
      } else if (entry.value is YamlList) {
        map[entry.key.toString()] = (entry.value as YamlList).toList();
      } else {
        map[entry.key.toString()] = entry.value;
      }
    }
    return map;
  }

  /// Updates the frontmatter in the provided markdown content with new key-value pairs.
  /// Ensures single-newline clean formatting for the YAML block.
  static String updateFrontmatter(String content, Map<String, dynamic> updates) {
    final match = _frontmatterRegExp.firstMatch(content);
    String yamlString = '';
    String restOfContent = content;

    if (match != null) {
      yamlString = match.group(1)!;
      // Capture the content after the frontmatter block, preserving exactly 
      // the newlines that were already there (trimming one leading newline max if we want to be clean).
      // Let's just substring from match.end.
      restOfContent = content.substring(match.end);
      if (restOfContent.startsWith('\n')) {
          restOfContent = restOfContent.substring(1);
      }
    }

    try {
      // If the original YAML is empty, initialize it with empty object to allow updates
      final editor = YamlEditor(yamlString.trim().isEmpty ? '' : yamlString);
      
      for (final entry in updates.entries) {
        editor.update([entry.key], entry.value);
      }
      
      String newYamlString = editor.toString().trim();
      // Enforce single-newline formatting by ensuring no extra whitespace
      if (newYamlString.isEmpty) {
        return restOfContent; // No frontmatter left
      }
      return '---\n$newYamlString\n---\n$restOfContent';
    } catch (e) {
      print('FrontmatterService update error: $e');
      return content; // Return original content on failure
    }
  }
}
