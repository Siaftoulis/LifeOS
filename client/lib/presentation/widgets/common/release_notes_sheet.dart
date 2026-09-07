import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../core/update/ota_update_service.dart';
import '../../../theme/everforest_colors.dart';

/// Interactive modal bottom sheet displaying OTA release notes rendered with full Markdown support.
class ReleaseNotesSheet extends StatelessWidget {
  final LifeOSRelease release;

  const ReleaseNotesSheet({super.key, required this.release});

  static Future<void> show(BuildContext context, LifeOSRelease release) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReleaseNotesSheet(release: release),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ota = OtaUpdateService.instance;
    final mq = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mq.size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: EverforestColors.bg2, width: 1.5),
          left: BorderSide(color: EverforestColors.bg2, width: 1.5),
          right: BorderSide(color: EverforestColors.bg2, width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: EverforestColors.bg2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EverforestColors.green.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.new_releases_rounded,
                      color: EverforestColors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                release.title.isNotEmpty ? release.title : 'LifeOS Update',
                                style: const TextStyle(
                                  color: EverforestColors.fg,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: EverforestColors.aqua.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                release.tagName,
                                style: const TextStyle(
                                  color: EverforestColors.aqua,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Published: ${release.publishedAt.year}-${release.publishedAt.month.toString().padLeft(2, '0')}-${release.publishedAt.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: EverforestColors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: EverforestColors.grey, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(color: EverforestColors.bg2, height: 1),

            // Markdown Changelog Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: release.body.trim().isNotEmpty
                    ? MarkdownBody(
                        data: release.body,
                        selectable: true,
                        onTapLink: (text, href, title) {
                          if (href != null && href.isNotEmpty) {
                            launchUrlString(href, mode: LaunchMode.externalApplication);
                          }
                        },
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: EverforestColors.fg, fontSize: 13, height: 1.55),
                          h1: const TextStyle(color: EverforestColors.green, fontSize: 17, fontWeight: FontWeight.bold),
                          h2: const TextStyle(color: EverforestColors.aqua, fontSize: 15, fontWeight: FontWeight.bold),
                          h3: const TextStyle(color: EverforestColors.yellow, fontSize: 13.5, fontWeight: FontWeight.w600),
                          h4: const TextStyle(color: EverforestColors.fg, fontSize: 13, fontWeight: FontWeight.w600),
                          code: const TextStyle(
                            color: EverforestColors.orange,
                            backgroundColor: EverforestColors.bg1,
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: EverforestColors.bg1,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: EverforestColors.bg2),
                          ),
                          blockquote: const TextStyle(color: EverforestColors.grey, fontStyle: FontStyle.italic, fontSize: 12),
                          blockquoteDecoration: BoxDecoration(
                            border: const Border(left: BorderSide(color: EverforestColors.aqua, width: 3)),
                            color: EverforestColors.bg1.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          listBullet: const TextStyle(color: EverforestColors.aqua, fontSize: 12),
                          strong: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold),
                          em: const TextStyle(color: EverforestColors.fg, fontStyle: FontStyle.italic),
                          a: const TextStyle(color: EverforestColors.blue, decoration: TextDecoration.underline),
                          horizontalRuleDecoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: EverforestColors.bg2, width: 1)),
                          ),
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No detailed changelog provided for this release.',
                            style: TextStyle(color: EverforestColors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
              ),
            ),

            const Divider(color: EverforestColors.bg2, height: 1),

            // Actions bottom bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EverforestColors.grey,
                      side: const BorderSide(color: EverforestColors.bg2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('DISMISS'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await ota.installUpdate();
                    },
                    icon: const Icon(Icons.download_done_rounded, size: 16),
                    label: Text(
                      'INSTALL ${release.tagName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EverforestColors.green,
                      foregroundColor: EverforestColors.bg0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
