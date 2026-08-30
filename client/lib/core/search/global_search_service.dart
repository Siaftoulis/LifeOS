import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_client.dart';

enum SearchCategory {
  all,
  music,
  notes,
  gallery,
  tasks,
  settings,
}

class SearchResultItem {
  final String id;
  final String title;
  final String subtitle;
  final SearchCategory category;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onSelect;
  final Map<String, dynamic>? rawData;

  const SearchResultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.accentColor,
    this.onSelect,
    this.rawData,
  });
}

class GlobalSearchService {
  static final GlobalSearchService instance = GlobalSearchService._internal();
  GlobalSearchService._internal();

  /// Search across all domains with optional category filter
  Future<List<SearchResultItem>> search(String query, {SearchCategory category = SearchCategory.all, BuildContext? context}) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return _getDefaultSuggestions(context);
    }

    final results = <SearchResultItem>[];

    // 1. Settings & Navigation Actions
    if (category == SearchCategory.all || category == SearchCategory.settings) {
      results.addAll(_searchSettings(cleanQuery, context));
    }

    // 2. Query Local SQLite & Remote Daemon concurrently
    final futures = <Future<List<SearchResultItem>>>[];

    if (category == SearchCategory.all || category == SearchCategory.music) {
      futures.add(_searchMusic(cleanQuery, context));
    }

    if (category == SearchCategory.all || category == SearchCategory.gallery) {
      futures.add(_searchGallery(cleanQuery, context));
    }

    if (category == SearchCategory.all || category == SearchCategory.notes) {
      futures.add(_searchNotes(cleanQuery, context));
    }

    if (category == SearchCategory.all || category == SearchCategory.tasks) {
      futures.add(_searchTasks(cleanQuery, context));
    }

    final domainResults = await Future.wait(futures);
    for (final list in domainResults) {
      results.addAll(list);
    }

    return results;
  }

  List<SearchResultItem> _getDefaultSuggestions(BuildContext? context) {
    return [
      SearchResultItem(
        id: 'action-updates',
        title: 'System Updates & Rollback',
        subtitle: 'Check for new OTA builds or restore previous version',
        category: SearchCategory.settings,
        icon: Icons.system_update_rounded,
        accentColor: const Color(0xFFA7C080), // Everforest green
      ),
      SearchResultItem(
        id: 'action-audio-eq',
        title: 'Audiophile Equalizer & DSP',
        subtitle: '10-Band EQ, Bass Boost, 3D Spatial Audio & Preamp',
        category: SearchCategory.music,
        icon: Icons.equalizer_rounded,
        accentColor: const Color(0xFF7FBBB3), // Everforest blue
      ),
      SearchResultItem(
        id: 'action-cloud-gallery',
        title: 'Cloud Gallery Vault',
        subtitle: 'Lossless photo & video storage with AI smart albums',
        category: SearchCategory.gallery,
        icon: Icons.cloud_done_rounded,
        accentColor: const Color(0xFFDBBC7F), // Everforest yellow
      ),
      SearchResultItem(
        id: 'action-offline-music',
        title: 'Offline Music Downloads',
        subtitle: 'Browse all tracks saved locally on this device',
        category: SearchCategory.music,
        icon: Icons.download_for_offline_rounded,
        accentColor: const Color(0xFF83C092), // Everforest aqua
      ),
    ];
  }

  List<SearchResultItem> _searchSettings(String q, BuildContext? context) {
    final systemActions = [
      SearchResultItem(
        id: 'settings-updates',
        title: 'OTA System Updates & Rollback',
        subtitle: 'System Settings • Version Control',
        category: SearchCategory.settings,
        icon: Icons.system_update_rounded,
        accentColor: const Color(0xFFA7C080),
      ),
      SearchResultItem(
        id: 'settings-audio-dsp',
        title: 'Audiophile DSP Equalizer Settings',
        subtitle: 'Music Library • 10-Band EQ & Spatial Effects',
        category: SearchCategory.settings,
        icon: Icons.tune_rounded,
        accentColor: const Color(0xFF7FBBB3),
      ),
      SearchResultItem(
        id: 'settings-matrix',
        title: 'Spatial Matrix & App Drawer Grid',
        subtitle: 'Preferences • Configure Home Layout',
        category: SearchCategory.settings,
        icon: Icons.grid_view_rounded,
        accentColor: const Color(0xFFD699B6),
      ),
      SearchResultItem(
        id: 'settings-cloud-vault',
        title: 'Cloud Vault & Deduplication Cleaner',
        subtitle: 'Photo & Video Gallery Settings',
        category: SearchCategory.settings,
        icon: Icons.cleaning_services_rounded,
        accentColor: const Color(0xFFDBBC7F),
      ),
    ];

    return systemActions.where((item) {
      return item.title.toLowerCase().contains(q) || item.subtitle.toLowerCase().contains(q);
    }).toList();
  }

  Future<List<SearchResultItem>> _searchMusic(String q, BuildContext? context) async {
    final list = <SearchResultItem>[];
    try {
      final daemonUrl = ApiClient.instance.daemonUrl;
      final uri = Uri.parse('$daemonUrl/api/v1/music/tracks?q=$q');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tracks = (data['tracks'] as List?) ?? (data is List ? data : []);
        for (final t in tracks) {
          final title = t['title'] ?? t['name'] ?? 'Unknown Track';
          final artist = t['artist'] ?? 'Unknown Artist';
          list.add(SearchResultItem(
            id: 'music-${t['id'] ?? title}',
            title: title,
            subtitle: '$artist • Music Track',
            category: SearchCategory.music,
            icon: Icons.music_note_rounded,
            accentColor: const Color(0xFF83C092),
            rawData: t is Map<String, dynamic> ? t : null,
          ));
        }
      }
    } catch (_) {}
    return list;
  }

  Future<List<SearchResultItem>> _searchGallery(String q, BuildContext? context) async {
    final list = <SearchResultItem>[];
    try {
      final daemonUrl = ApiClient.instance.daemonUrl;
      final uri = Uri.parse('$daemonUrl/api/v1/gallery/assets?q=$q&limit=20');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final assets = (data['assets'] as List?) ?? [];
        for (final a in assets) {
          final title = a['title'] ?? a['filename'] ?? 'Photo Asset';
          final place = a['place'] ?? '';
          final tags = ((a['tags'] as List?) ?? []).join(', ');
          final sub = place.isNotEmpty ? '$place • $tags' : (tags.isNotEmpty ? tags : 'Gallery Photo');
          list.add(SearchResultItem(
            id: 'gallery-${a['id']}',
            title: title,
            subtitle: sub,
            category: SearchCategory.gallery,
            icon: Icons.image_rounded,
            accentColor: const Color(0xFFDBBC7F),
            rawData: a is Map<String, dynamic> ? a : null,
          ));
        }
      }
    } catch (_) {}
    return list;
  }

  Future<List<SearchResultItem>> _searchNotes(String q, BuildContext? context) async {
    final list = <SearchResultItem>[];
    try {
      final daemonUrl = ApiClient.instance.daemonUrl;
      final uri = Uri.parse('$daemonUrl/api/v1/markdown/files?q=$q');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final files = data is List ? data : ((data['files'] as List?) ?? []);
        for (final f in files) {
          final name = f['name'] ?? f['path'] ?? 'Note';
          list.add(SearchResultItem(
            id: 'note-$name',
            title: name.toString().replaceAll('.md', ''),
            subtitle: 'Zen Document • Obsidian Vault',
            category: SearchCategory.notes,
            icon: Icons.description_rounded,
            accentColor: const Color(0xFF7FBBB3),
            rawData: f is Map<String, dynamic> ? f : null,
          ));
        }
      }
    } catch (_) {}
    return list;
  }

  Future<List<SearchResultItem>> _searchTasks(String q, BuildContext? context) async {
    final list = <SearchResultItem>[];
    try {
      final daemonUrl = ApiClient.instance.daemonUrl;
      final uri = Uri.parse('$daemonUrl/api/v1/chtm/tasks?q=$q');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tasks = data is List ? data : ((data['tasks'] as List?) ?? []);
        for (final t in tasks) {
          final title = t['title'] ?? t['name'] ?? 'Task';
          final status = t['status'] ?? 'pending';
          list.add(SearchResultItem(
            id: 'task-${t['id'] ?? title}',
            title: title,
            subtitle: 'Task ($status) • Daily Hub',
            category: SearchCategory.tasks,
            icon: Icons.check_box_outlined,
            accentColor: const Color(0xFFE67E80),
            rawData: t is Map<String, dynamic> ? t : null,
          ));
        }
      }
    } catch (_) {}
    return list;
  }
}
