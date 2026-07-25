import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

class FrontmatterService {
  static final RegExp _frontmatterRegExp = RegExp(r'^---\r?\n(.*?)\r?\n---', dotAll: true);

  /// Extracts clean body and raw frontmatter header block from markdown content.
  static ({String? frontmatter, String body}) extractBodyAndFrontmatter(String fullContent) {
    final match = _frontmatterRegExp.firstMatch(fullContent);
    if (match == null) {
      return (frontmatter: null, body: fullContent);
    }

    final frontmatterStr = match.group(0);
    String bodyStr = fullContent.substring(match.end);
    if (bodyStr.startsWith('\n') || bodyStr.startsWith('\r\n')) {
      bodyStr = bodyStr.replaceFirst(RegExp(r'^\r?\n'), '');
    }

    return (frontmatter: frontmatterStr, body: bodyStr);
  }

  /// Combines frontmatter header block and clean markdown body string.
  static String combineFrontmatterAndBody(String? frontmatterHeader, String body) {
    if (frontmatterHeader == null || frontmatterHeader.trim().isEmpty) {
      return body;
    }
    final cleanHeader = frontmatterHeader.trim();
    final cleanBody = body.startsWith('\n') ? body.substring(1) : body;
    return '$cleanHeader\n$cleanBody';
  }

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
    } catch (_) {}
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
  /// Ensures clean formatting without throwing exceptions or logging debug errors.
  static String updateFrontmatter(String content, Map<String, dynamic> updates) {
    if (updates.isEmpty) return content;

    final match = _frontmatterRegExp.firstMatch(content);
    String yamlString = '';
    String restOfContent = content;

    if (match != null) {
      yamlString = match.group(1)!;
      restOfContent = content.substring(match.end);
      if (restOfContent.startsWith('\n') || restOfContent.startsWith('\r\n')) {
        restOfContent = restOfContent.replaceFirst(RegExp(r'^\r?\n'), '');
      }
    }

    String currentYaml = yamlString;

    try {
      final editor = YamlEditor(currentYaml.trim().isEmpty ? '' : currentYaml);
      bool editorFailed = false;

      for (final entry in updates.entries) {
        final key = entry.key;
        final val = entry.value;
        try {
          editor.update([key], val);
        } catch (_) {
          editorFailed = true;
          break;
        }
      }

      if (!editorFailed) {
        final newYamlString = editor.toString().trim();
        if (newYamlString.isEmpty) {
          return restOfContent;
        }
        return '---\n$newYamlString\n---\n$restOfContent';
      }
    } catch (_) {
      // YamlEditor failed -> fallback to regex key updates
    }

    // Line-based key updates fallback
    for (final entry in updates.entries) {
      final key = entry.key;
      final val = entry.value;
      final keyPattern = RegExp('^' + RegExp.escape(key) + r':.*$', multiLine: true);
      final formattedVal = val is String ? '"$val"' : '$val';

      if (keyPattern.hasMatch(currentYaml)) {
        currentYaml = currentYaml.replaceAll(keyPattern, '$key: $formattedVal');
      } else {
        final trimmed = currentYaml.trimRight();
        currentYaml = trimmed.isEmpty ? '$key: $formattedVal' : '$trimmed\n$key: $formattedVal';
      }
    }

    final cleanYaml = currentYaml.trim();
    if (cleanYaml.isEmpty) return restOfContent;
    return '---\n$cleanYaml\n---\n$restOfContent';
  }
}
