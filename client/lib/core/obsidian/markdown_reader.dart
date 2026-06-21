import 'dart:io';

class MarkdownLink {
  final String originalText;
  final String target;
  final String? label;
  final bool isWikiLink;

  MarkdownLink({
    required this.originalText,
    required this.target,
    this.label,
    required this.isWikiLink,
  });

  @override
  String toString() {
    return 'MarkdownLink(target: $target, label: $label, isWikiLink: $isWikiLink)';
  }
}

class MarkdownReader {
  // Regex to match Obsidian-style wiki links: [[Target]] or [[Target|Label]]
  static final RegExp wikiLinkRegExp = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');
  
  // Regex to match standard Markdown links: [Label](Target)
  static final RegExp mdLinkRegExp = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

  /// High-performance local file reader
  static Future<String> readFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    // High performance bulk read
    return await file.readAsString();
  }

  /// Tokenizes all links within the text content using RegExp
  static List<MarkdownLink> tokenizeLinks(String content) {
    final List<MarkdownLink> links = [];

    // Parse Wiki Links
    for (final match in wikiLinkRegExp.allMatches(content)) {
      links.add(MarkdownLink(
        originalText: match.group(0)!,
        target: match.group(1)!.trim(),
        label: match.group(2)?.trim(),
        isWikiLink: true,
      ));
    }

    // Parse Standard Markdown Links
    for (final match in mdLinkRegExp.allMatches(content)) {
      links.add(MarkdownLink(
        originalText: match.group(0)!,
        target: match.group(2)!.trim(),
        label: match.group(1)?.trim(),
        isWikiLink: false,
      ));
    }

    return links;
  }

  /// Combined reader and tokenizer
  static Future<List<MarkdownLink>> readAndTokenizeLinks(String filePath) async {
    final content = await readFile(filePath);
    return tokenizeLinks(content);
  }
}
