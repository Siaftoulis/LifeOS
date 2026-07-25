import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';
import 'package:intl/intl.dart';

class ZenInspectorPanel extends StatelessWidget {
  final Map<String, dynamic> frontmatter;

  const ZenInspectorPanel({
    super.key,
    required this.frontmatter,
  });

  @override
  Widget build(BuildContext context) {
    if (frontmatter.isEmpty) {
      return Container(
        color: EverforestColors.bg0,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Expanded(
              child: Center(
                child: Text(
                  'No properties found.',
                  style: TextStyle(color: EverforestColors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final keys = frontmatter.keys.toList();

    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: keys.length,
              separatorBuilder: (context, index) => const Divider(color: EverforestColors.bg1, height: 1),
              itemBuilder: (context, index) {
                final key = keys[index];
                final value = frontmatter[key];
                return _buildPropertyRow(key, value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Text(
        'Properties',
        style: TextStyle(
          color: EverforestColors.fg,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildPropertyRow(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(_getIconForKey(key), size: 14, color: EverforestColors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    key,
                    style: const TextStyle(color: EverforestColors.grey, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: _buildPropertyValue(value),
          ),
        ],
      ),
    );
  }

  IconData _getIconForKey(String key) {
    switch (key.toLowerCase()) {
      case 'id':
        return Icons.fingerprint;
      case 'tags':
      case 'tag':
        return Icons.tag;
      case 'aliases':
      case 'alias':
        return Icons.link;
      case 'created_at':
      case 'created':
      case 'date':
        return Icons.calendar_today;
      case 'updated_at':
      case 'updated':
      case 'modified':
        return Icons.edit_calendar;
      case 'synced_at':
      case 'sync':
        return Icons.cloud_done;
      default:
        return Icons.data_object;
    }
  }

  Widget _buildPropertyValue(dynamic value) {
    if (value == null) {
      return const Text('null', style: TextStyle(color: EverforestColors.grey, fontStyle: FontStyle.italic, fontSize: 13));
    }

    if (value is List) {
      if (value.isEmpty) {
        return const Text('Empty list', style: TextStyle(color: EverforestColors.grey, fontStyle: FontStyle.italic, fontSize: 13));
      }
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: value.map((e) => _buildChip(e.toString())).toList(),
      );
    }

    if (value is Map) {
      return const Text('Object', style: TextStyle(color: EverforestColors.grey, fontStyle: FontStyle.italic, fontSize: 13));
    }

    // Try parsing as ISO date if it looks like one and the length matches roughly
    final strValue = value.toString();
    if (strValue.length > 10 && strValue.contains('T') && strValue.contains('Z')) {
      final date = DateTime.tryParse(strValue);
      if (date != null) {
        final formatter = DateFormat('MMM d, yyyy HH:mm');
        return Text(formatter.format(date.toLocal()), style: const TextStyle(color: EverforestColors.fg, fontSize: 13));
      }
    }

    return Text(strValue, style: const TextStyle(color: EverforestColors.fg, fontSize: 13));
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: EverforestColors.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg1),
      ),
      child: Text(
        label,
        style: const TextStyle(color: EverforestColors.fg, fontSize: 12),
      ),
    );
  }
}
