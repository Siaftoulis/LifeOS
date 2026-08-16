import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../theme/everforest_colors.dart';
import '../../api_client.dart';
import '../../core/movie_repository.dart' as repo;
import '../../core/device_gallery_service.dart';
import '../../core/domain_repositories.dart' show MusicTrack, MusicRepository;
import '../../database/database.dart' hide MusicTrack;
import '../../database/chtm_dao.dart';
import '../../presentation/widgets/media_hub/photo_video_gallery/gallery_item.dart';
import '../../presentation/widgets/media_hub/photo_video_gallery/aves_viewer_screen.dart';
import '../../presentation/widgets/media_hub/movie_library/movie_library_dashboard.dart';
import '../../presentation/widgets/media_hub/music_library/music_dashboard_widget.dart';
import '../../presentation/widgets/book_library/book_library_dashboard.dart';
import '../../presentation/widgets/chtm/chtm_view.dart';
import '../../presentation/widgets/maps_live_tracking/maps_dashboard_widget.dart';
import '../gallery/gallery_home_view.dart';
import 'zen_editor.dart';

class ZenEmbedKeys {
  const ZenEmbedKeys._();

  static const String type = 'zen_embed';
  static const String module = 'module';
  static const String ref = 'ref';
  static const String height = 'height';

  static const double minHeight = 120;
  static const double maxHeight = 640;
  static const double defaultHeight = 200;
}

double zenEmbedHeightOf(Node node) {
  final h = node.attributes[ZenEmbedKeys.height];
  return h is num ? h.toDouble() : ZenEmbedKeys.defaultHeight;
}

Node zenEmbedNode({required String module, String? ref, double? height}) {
  return Node(
    type: ZenEmbedKeys.type,
    attributes: {
      ZenEmbedKeys.module: module,
      if (ref != null) ZenEmbedKeys.ref: ref,
      if (height != null) ZenEmbedKeys.height: height,
    },
  );
}

/// Moves a zen_embed block one step up (-1) or down (+1) among its siblings.
///
/// Move = insert a copy next to the target sibling, then delete the original.
/// Up: insert before the target; down: insert after it. Insert goes first so
/// Transaction.add()'s path transformation keeps the delete path valid.
Future<void> moveZenEmbedBlock(
  EditorState editorState,
  Node node,
  int direction,
) async {
  final siblings = node.parent?.children;
  if (siblings == null) return;
  final index = siblings.indexOf(node);
  final target = index + direction;
  if (index < 0 || target < 0 || target >= siblings.length) return;

  final targetPath = direction < 0
      ? siblings[target].path
      : siblings[target].path.next;
  final transaction = editorState.transaction
    ..insertNode(targetPath, node, deepCopy: true)
    ..deleteNode(node);
  await editorState.apply(transaction);
}

class ZenEmbedSpec {
  const ZenEmbedSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.preview,
    required this.full,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Compact inline preview rendered inside the note. [ref] is an optional
  /// entity reference (e.g. a movie id) for single-entity embeds.
  final Widget Function(String? ref) preview;

  /// The full module opened on a separate page.
  final Widget Function() full;
}

Widget _moduleShell(String title, Widget child) {
  return Scaffold(
    backgroundColor: EverforestColors.bg0,
    appBar: AppBar(
      backgroundColor: EverforestColors.bg1,
      elevation: 0,
      iconTheme: const IconThemeData(color: EverforestColors.fg),
      title: Text(title, style: const TextStyle(color: EverforestColors.fg)),
    ),
    body: child,
  );
}

/// One embed render-window per Zen link module.
final Map<String, ZenEmbedSpec> zenEmbedSpecs = {
  'photos': ZenEmbedSpec(
    id: 'photos',
    label: 'Photos',
    icon: Icons.photo_library_outlined,
    preview: (ref) => PhotosEmbedPreview(ref: ref),
    full: () => _moduleShell('Photos', const GalleryHomeView()),
  ),
  'maps': ZenEmbedSpec(
    id: 'maps',
    label: 'Maps',
    icon: Icons.map_outlined,
    preview: (ref) => MapsEmbedPreview(ref: ref),
    full: () => _moduleShell('Maps', const MapsDashboardWidget()),
  ),
  'calendar': ZenEmbedSpec(
    id: 'calendar',
    label: 'Calendar',
    icon: Icons.calendar_month_outlined,
    preview: (ref) => const CalendarEmbedPreview(),
    full: () => const CHTMView(),
  ),
  'books': ZenEmbedSpec(
    id: 'books',
    label: 'Books',
    icon: Icons.menu_book_outlined,
    preview: (ref) => BooksEmbedPreview(ref: ref),
    full: () => const BookLibraryDashboard(),
  ),
  'movies': ZenEmbedSpec(
    id: 'movies',
    label: 'Movies',
    icon: Icons.movie_outlined,
    preview: (ref) => MoviesEmbedPreview(ref: ref),
    full: () => const MovieLibraryDashboard(),
  ),
  'music': ZenEmbedSpec(
    id: 'music',
    label: 'Music',
    icon: Icons.music_note_outlined,
    preview: (ref) => MusicEmbedPreview(ref: ref),
    full: () => const MusicDashboardWidget(),
  ),
  'notes': ZenEmbedSpec(
    id: 'notes',
    label: 'Notes',
    icon: Icons.description_outlined,
    preview: (ref) => NotesEmbedPreview(ref: ref),
    full: () => _moduleShell('Notes', const ZenEditor()),
  ),
};

/// Matches a standalone `[[photos]]` / `![[photos]]` / `![[photos|300]]`
/// (height) / `![[movies|m3]]` (entity ref) line.
final RegExp zenEmbedLineRegExp = RegExp(
  '^!?\\[\\[(${zenEmbedSpecs.keys.join('|')})(?:\\|([^\\]|]+))?\\]\\]\$',
);

/// Round-trips a zen_embed node as a `![[module]]` / `![[module|ref]]`
/// markdown line.
class ZenEmbedNodeParser extends NodeParser {
  const ZenEmbedNodeParser();

  @override
  String get id => ZenEmbedKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final module = node.attributes[ZenEmbedKeys.module] as String? ?? '';
    final name = zenEmbedSpecs.containsKey(module) ? module : 'photos';
    final ref = node.attributes[ZenEmbedKeys.ref] as String?;
    if (ref != null && ref.isNotEmpty) {
      return '![[$name|$ref]]\n';
    }
    final height = node.attributes[ZenEmbedKeys.height];
    if (height is num) {
      return '![[$name|${height.toInt()}]]\n';
    }
    return '![[$name]]\n';
  }
}

class ZenEmbedBlockComponentBuilder extends BlockComponentBuilder {
  ZenEmbedBlockComponentBuilder({super.configuration});

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return ZenEmbedBlockComponentWidget(
      key: node.key,
      node: node,
      showActions: showActions(node),
      configuration: configuration,
    );
  }

  @override
  bool validate(Node node) => node.delta == null && node.children.isEmpty;
}

class ZenEmbedBlockComponentWidget extends BlockComponentStatefulWidget {
  const ZenEmbedBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<ZenEmbedBlockComponentWidget> createState() =>
      _ZenEmbedBlockComponentWidgetState();
}

class _ZenEmbedBlockComponentWidgetState
    extends State<ZenEmbedBlockComponentWidget>
    with SelectableMixin, BlockComponentConfigurable {
  final _bodyKey = GlobalKey();

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  late final editorState = Provider.of<EditorState>(context, listen: false);

  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  @override
  Widget build(BuildContext context) {
    final module = widget.node.attributes[ZenEmbedKeys.module] as String? ?? '';
    final ref = widget.node.attributes[ZenEmbedKeys.ref] as String?;
    final spec = zenEmbedSpecs[module];

    Widget child = Padding(
      key: _bodyKey,
      padding: padding,
      child: spec == null
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EverforestColors.bg1,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: EverforestColors.red),
              ),
              child: Text(
                'Unknown embed: $module',
                style: const TextStyle(color: EverforestColors.red),
              ),
            )
          : ZenEmbedCard(
              spec: spec,
              ref: ref,
              height: zenEmbedHeightOf(widget.node),
              onHeightChanged: (h) {
                editorState.apply(
                  editorState.transaction
                    ..updateNode(widget.node, {ZenEmbedKeys.height: h}),
                );
              },
              onMove: (direction) =>
                  moveZenEmbedBlock(editorState, widget.node, direction),
            ),
    );

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [BlockSelectionType.block],
      child: child,
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        child: child,
      );
    }

    return child;
  }

  @override
  Position start() => Position(path: widget.node.path);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({bool shiftWithBaseOffset = false}) {
    final box = _bodyKey.currentContext?.findRenderObject();
    if (box is RenderBox) {
      return Offset.zero & box.size;
    }
    return Rect.zero;
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox == null) {
      return null;
    }
    final size = _renderBox!.size;
    return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
  }

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox == null) {
      return [];
    }
    final box = _bodyKey.currentContext?.findRenderObject();
    final parentBox = context.findRenderObject();
    if (parentBox is RenderBox && box is RenderBox) {
      return [box.localToGlobal(Offset.zero, ancestor: parentBox) & box.size];
    }
    return [Offset.zero & _renderBox!.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) =>
      Selection.single(path: widget.node.path, startOffset: 0, endOffset: 1);

  @override
  Offset localToGlobal(
    Offset offset, {
    bool shiftWithBaseOffset = false,
  }) =>
      _renderBox!.localToGlobal(offset);
}

/// The inline render window: header bar + compact preview body.
class ZenEmbedCard extends StatefulWidget {
  const ZenEmbedCard({
    super.key,
    required this.spec,
    this.ref,
    required this.height,
    required this.onHeightChanged,
    required this.onMove,
  });

  final ZenEmbedSpec spec;
  final String? ref;
  final double height;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<int> onMove;

  @override
  State<ZenEmbedCard> createState() => _ZenEmbedCardState();
}

class _ZenEmbedCardState extends State<ZenEmbedCard> {
  double _dragHeight = 0;

  @override
  Widget build(BuildContext context) {
    final height = _dragHeight > 0 ? _dragHeight : widget.height;
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EverforestColors.bg2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(context),
          SizedBox(
            height: height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openFull(context),
              child: RepaintBoundary(
                child: ClipRect(child: widget.spec.preview(widget.ref)),
              ),
            ),
          ),
          _resizeHandle(),
        ],
      ),
    );
  }

  Widget _resizeHandle() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (details) {
          _dragHeight = widget.height;
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragHeight = (_dragHeight + details.delta.dy)
                .clamp(ZenEmbedKeys.minHeight, ZenEmbedKeys.maxHeight);
          });
        },
        onVerticalDragEnd: (details) {
          widget.onHeightChanged(_dragHeight.roundToDouble());
          setState(() => _dragHeight = 0);
        },
        child: Container(
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: EverforestColors.bg2)),
          ),
          child: const Icon(
            Icons.drag_handle,
            size: 14,
            color: EverforestColors.grey,
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      height: 34,
      color: const Color(0xFF1E2326),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(widget.spec.icon, size: 15, color: EverforestColors.green),
          const SizedBox(width: 8),
          Text(
            widget.spec.label,
            style: const TextStyle(
              color: EverforestColors.fg,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 16,
            tooltip: 'Move embed up',
            icon: const Icon(
              Icons.keyboard_arrow_up,
              color: EverforestColors.grey,
            ),
            onPressed: () => widget.onMove(-1),
          ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 16,
            tooltip: 'Move embed down',
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: EverforestColors.grey,
            ),
            onPressed: () => widget.onMove(1),
          ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 16,
            tooltip: 'Open ${widget.spec.label} full screen',
            icon: const Icon(Icons.open_in_full, color: EverforestColors.grey),
            onPressed: () => _openFull(context),
          ),
        ],
      ),
    );
  }

  void _openFull(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => widget.spec.full()),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-module previews
// ---------------------------------------------------------------------------

class PhotosEmbedPreview extends StatefulWidget {
  const PhotosEmbedPreview({super.key, this.ref});

  /// Single-photo embed reference (gallery asset id from the daemon).
  final String? ref;

  @override
  State<PhotosEmbedPreview> createState() => _PhotosEmbedPreviewState();
}

class _PhotosEmbedPreviewState extends State<PhotosEmbedPreview> {
  final DeviceGalleryService _service = DeviceGalleryService();
  List<GalleryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.ref != null && widget.ref!.isNotEmpty) return;
    _load();
  }

  Future<void> _load() async {
    var granted = await _service.requestPermission();
    var items = <GalleryItem>[];
    if (granted) {
      try {
        items = await _service.fetchMediaPage(page: 0);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ref != null && widget.ref!.isNotEmpty) {
      return _SinglePhotoEmbed(ref: widget.ref!);
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: EverforestColors.green),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'No photos yet — tap to open the gallery',
          style: TextStyle(color: EverforestColors.grey),
        ),
      );
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: math.min(12, _items.length),
      itemBuilder: (context, index) {
        final item = _items[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (_, __, ___) =>
                  AvesViewerScreen(items: _items, initialIndex: index),
            ),
          ),
          child: _thumbnail(item),
        );
      },
    );
  }

  Widget _thumbnail(GalleryItem item) {
    final Widget image = item.assetEntity != null
        ? AssetEntityImage(
            item.assetEntity!,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(200),
            fit: BoxFit.cover,
          )
        : Image.file(
            File(item.pathOrUrl),
            fit: BoxFit.cover,
            cacheWidth: 200,
          );
    return ClipRRect(borderRadius: BorderRadius.circular(4), child: image);
  }
}

/// Renders one gallery asset from the daemon as a metadata card with its
/// thumbnail (`GET /api/v1/gallery/asset?id=` + `thumbnail?id=`).
class _SinglePhotoEmbed extends StatefulWidget {
  const _SinglePhotoEmbed({required this.ref});

  final String ref;

  @override
  State<_SinglePhotoEmbed> createState() => _SinglePhotoEmbedState();
}

class _SinglePhotoEmbedState extends State<_SinglePhotoEmbed> {
  Map<String, dynamic>? _asset;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.getDaemon(
        '/api/v1/gallery/asset?id=${Uri.encodeQueryComponent(widget.ref)}',
      );
      if (mounted) {
        setState(() =>
            _asset = res is Map ? Map<String, dynamic>.from(res) : null);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Text(
          'Photo not found — tap to open the gallery',
          style: TextStyle(color: EverforestColors.grey),
        ),
      );
    }
    final a = _asset;
    if (a == null) {
      return const Center(
        child: CircularProgressIndicator(color: EverforestColors.green),
      );
    }

    final thumbUrl =
        '${ApiClient.instance.daemonUrl}/api/v1/gallery/thumbnail?id='
        '${Uri.encodeQueryComponent(widget.ref)}';
    final tags = (a['tags'] as List?)?.cast<String>() ?? [];
    final date = (a['created_at'] as String? ?? '').split('T').first;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EverforestColors.bg2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              thumbUrl,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 68,
                height: 68,
                color: EverforestColors.bg1,
                child: const Icon(Icons.image_outlined, color: EverforestColors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (a['title']?.toString() ?? '').isNotEmpty
                      ? a['title'].toString()
                      : a['filename']?.toString() ?? 'Unknown Photo',
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${a['source'] ?? ''} • ${a['width'] ?? 0}×${a['height'] ?? 0}',
                  style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tags.take(3).join(' · '),
                    style: const TextStyle(
                      color: EverforestColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapsEmbedPreview extends StatelessWidget {
  const MapsEmbedPreview({super.key, this.ref});

  /// Single-pin embed reference (geofence id from the daemon).
  final String? ref;

  @override
  Widget build(BuildContext context) {
    if (ref != null && ref!.isNotEmpty) {
      return _SinglePinEmbed(ref: ref!);
    }
    return StreamBuilder<List<Geofence>>(
      stream: AppDatabase.instance.mapsDao.watchAllGeofences(),
      builder: (context, snapshot) {
        final pins = (snapshot.data ?? const <Geofence>[])
            .where((g) => g.isActive == 1)
            .toList();
        if (pins.isEmpty) {
          return const Center(
            child: Text(
              'No places pinned yet — tap to open the map',
              style: TextStyle(color: EverforestColors.grey),
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: CustomPaint(
                painter: _PinsPainter(
                  pins: pins
                      .map((g) => (lat: g.latitude, lng: g.longitude, name: g.name))
                      .toList(),
                ),
              ),
            ),
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pins.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: EverforestColors.bg2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: EverforestColors.green),
                      const SizedBox(width: 4),
                      Text(
                        pins[index].name,
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Static pin map: no tile downloads, just pin positions relative to each
/// other. ponytail: single-frame painter, upgrade to a real flutter_map
/// preview if tiles offline rendering becomes worth it.
class _PinsPainter extends CustomPainter {
  _PinsPainter({required this.pins});

  final List<({double lat, double lng, String name})> pins;

  @override
  void paint(Canvas canvas, Size size) {
    var minLat = pins.first.lat;
    var maxLat = pins.first.lat;
    var minLng = pins.first.lng;
    var maxLng = pins.first.lng;
    for (final p in pins) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }
    final spanLat = math.max(maxLat - minLat, 0.0001);
    final spanLng = math.max(maxLng - minLng, 0.0001);
    const pad = 20.0;

    Offset project(double lat, double lng) {
      final x = pad + (lng - minLng) / spanLng * (size.width - pad * 2);
      final y = size.height -
          pad -
          (lat - minLat) / spanLat * (size.height - pad * 2);
      return Offset(x, y);
    }

    final paint = Paint()
      ..color = const Color(0xFF2E383C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double i = 1; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width / 3 * i,
          0,
          size.width / 3 * i,
          size.height,
        )
            .deflate(0.001),
        paint,
      );
    }

    for (final p in pins) {
      final pos = project(p.lat, p.lng);
      canvas.drawCircle(pos, 5, Paint()..color = EverforestColors.green);
      canvas.drawCircle(
        pos,
        8,
        Paint()
          ..color = EverforestColors.green.withValues(alpha: 0.3),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: p.name,
          style: const TextStyle(
            color: EverforestColors.fg,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width / 2);
      tp.paint(canvas, pos + const Offset(10, -4));
    }
  }

  @override
  bool shouldRepaint(_PinsPainter oldDelegate) =>
      oldDelegate.pins != pins;
}

class CalendarEmbedPreview extends StatelessWidget {
  const CalendarEmbedPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final dao = ChtmDao(AppDatabase.instance);
    return StreamBuilder<List<CalendarEvent>>(
      stream: dao.watchAllEvents(),
      builder: (context, snapshot) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final upcoming = (snapshot.data ?? const <CalendarEvent>[])
            .where((e) => e.startTime > nowMs)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        final events = upcoming.take(5).toList();
        if (events.isEmpty) {
          return const Center(
            child: Text(
              'No upcoming events',
              style: TextStyle(color: EverforestColors.grey),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: events.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF2E383C)),
          itemBuilder: (context, index) {
            final e = events[index];
            final start = DateTime.fromMillisecondsSinceEpoch(e.startTime);
            return Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _parseColor(e.colorCode),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.title,
                    style: const TextStyle(
                      color: EverforestColors.fg,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _fmtDate(start),
                  style: const TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return EverforestColors.green;
    }
  }

  static String _fmtDate(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}, $hh:$mm';
  }
}

class _EmbedCardData {
  const _EmbedCardData(this.title, this.subtitle, this.color);

  final String title;
  final String subtitle;
  final Color color;
}

class _CardStrip extends StatelessWidget {
  const _CardStrip({required this.items});

  final List<_EmbedCardData> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Nothing here yet — tap to open the library',
          style: TextStyle(color: EverforestColors.grey),
        ),
      );
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final it = items[index];
        return Container(
          width: 110,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: it.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                it.title,
                style: const TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                it.subtitle,
                style: const TextStyle(
                  color: EverforestColors.grey,
                  fontSize: 10.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class BooksEmbedPreview extends StatelessWidget {
  const BooksEmbedPreview({super.key, this.ref});

  /// Single-book embed reference (book id from the daemon).
  final String? ref;

  @override
  Widget build(BuildContext context) {
    if (ref != null && ref!.isNotEmpty) {
      return _SingleBookEmbed(ref: ref!);
    }
    return StreamBuilder<List<Book>>(
      stream: AppDatabase.instance.booksDao.watchAllBooks(),
      builder: (context, snapshot) {
        final items = (snapshot.data ?? const <Book>[])
            .take(8)
            .map((b) => _EmbedCardData(
                  b.title,
                  b.author ?? '',
                  EverforestColors.bg2,
                ))
            .toList();
        return _CardStrip(items: items);
      },
    );
  }
}

class MoviesEmbedPreview extends StatelessWidget {
  const MoviesEmbedPreview({super.key, this.ref});

  /// Single-movie embed reference (movie id from the daemon).
  final String? ref;

  @override
  Widget build(BuildContext context) {
    if (ref != null && ref!.isNotEmpty) {
      return _SingleMovieEmbed(ref: ref!);
    }
    return ValueListenableBuilder<List<repo.Movie>>(
      valueListenable: repo.MovieRepository.instance.movies,
      builder: (context, movies, child) {
        final items = movies
            .take(8)
            .map((m) {
              Color color = EverforestColors.bg2;
              try {
                color = Color(int.parse(m.colorHex));
              } catch (_) {}
              return _EmbedCardData(
                m.title,
                '${m.director} • ${m.year}',
                color,
              );
            })
            .toList();
        return _CardStrip(items: items);
      },
    );
  }
}

/// Renders one movie from the daemon (`GET /api/v1/movies/{id}`) as a
/// metadata card. Data lives server-side, nothing is copied into the note.
class _SingleMovieEmbed extends StatelessWidget {
  const _SingleMovieEmbed({required this.ref});

  final String ref;

  @override
  Widget build(BuildContext context) {
    return _SingleEntityEmbed(
      ref: ref,
      endpoint: '/api/v1/movies',
      notFoundMessage: 'Movie not found — tap to open the library',
      leading: (m) {
        final posterUrl = m['poster_url'] as String? ?? '';
        if (posterUrl.isEmpty) return null;
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            posterUrl,
            width: 48,
            height: 68,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      },
      subtitle: (m) => '${m['director'] ?? ''} • ${m['year'] ?? ''}',
      meta: (m) => m['genres'] as String? ?? '',
      rating: (m) => m['rating'],
      status: (m) => m['status']?.toString() ?? '',
    );
  }
}

/// Renders one book from the daemon (`GET /api/v1/books/{id}`) as a
/// metadata card.
class _SingleBookEmbed extends StatelessWidget {
  const _SingleBookEmbed({required this.ref});

  final String ref;

  @override
  Widget build(BuildContext context) {
    return _SingleEntityEmbed(
      ref: ref,
      endpoint: '/api/v1/books',
      notFoundMessage: 'Book not found — tap to open the library',
      leading: (b) => Container(
        width: 48,
        height: 68,
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.menu_book_outlined,
          color: EverforestColors.green,
          size: 26,
        ),
      ),
      subtitle: (b) =>
          '${b['author'] ?? ''} • ${b['current_page'] ?? 0}/${b['total_pages'] ?? 0} p.',
      status: (b) {
        final s = b['status']?.toString() ?? '';
        final page = (b['current_page'] is num) ? (b['current_page'] as num).toInt() : 0;
        final total = (b['total_pages'] is num) ? (b['total_pages'] as num).toInt() : 0;
        if (s.isNotEmpty && page > 0 && total > 0) {
          return '$s — page $page of $total';
        }
        return s;
      },
    );
  }
}

/// Fetches one entity from the daemon and renders a metadata card. Shared by
/// the movie and book embeds; data stays server-side, nothing is copied.
class _SingleEntityEmbed extends StatefulWidget {
  const _SingleEntityEmbed({
    required this.ref,
    required this.endpoint,
    required this.notFoundMessage,
    required this.subtitle,
    required this.status,
    this.leading,
    this.meta,
    this.rating,
  });

  final String ref;
  final String endpoint;
  final String notFoundMessage;
  final Widget? Function(Map<String, dynamic> entity)? leading;
  final String Function(Map<String, dynamic> entity) subtitle;
  final String Function(Map<String, dynamic> entity)? meta;
  final dynamic Function(Map<String, dynamic> entity)? rating;
  final String Function(Map<String, dynamic> entity) status;

  @override
  State<_SingleEntityEmbed> createState() => _SingleEntityEmbedState();
}

class _SingleEntityEmbedState extends State<_SingleEntityEmbed> {
  Map<String, dynamic>? _entity;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res =
          await ApiClient.instance.getDaemon('${widget.endpoint}/${widget.ref}');
      if (mounted) {
        setState(() => _entity = res is Map ? Map<String, dynamic>.from(res) : null);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
        child: Text(
          widget.notFoundMessage,
          style: const TextStyle(color: EverforestColors.grey),
        ),
      );
    }
    final e = _entity;
    if (e == null) {
      return const Center(
        child: CircularProgressIndicator(color: EverforestColors.green),
      );
    }

    Color color = EverforestColors.bg2;
    try {
      color = Color(int.parse(e['color']));
    } catch (_) {}

    final ratingValue = widget.rating?.call(e);
    final rating =
        (ratingValue is num) ? ratingValue.toDouble() : 0.0;
    final meta = widget.meta?.call(e) ?? '';
    final leading = widget.leading?.call(e);

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e['title'] as String? ?? 'Unknown Title',
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating > 0)
                      const Icon(Icons.star, size: 14, color: EverforestColors.yellow),
                    if (rating > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle(e),
                  style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  widget.status(e),
                  style: const TextStyle(
                    color: EverforestColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders one track from the daemon (`GET /api/v1/music/tracks/{id}`) as a
/// metadata card.
class _SingleTrackEmbed extends StatelessWidget {
  const _SingleTrackEmbed({required this.ref});

  final String ref;

  @override
  Widget build(BuildContext context) {
    return _SingleEntityEmbed(
      ref: ref,
      endpoint: '/api/v1/music/tracks',
      notFoundMessage: 'Track not found — tap to open the library',
      leading: (t) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.music_note_outlined,
          color: EverforestColors.green,
          size: 24,
        ),
      ),
      subtitle: (t) => '${t['artist'] ?? ''} • ${t['album'] ?? ''}',
      status: (t) => (t['album'] as String? ?? '').isNotEmpty ? 'Album track' : '',
    );
  }
}

/// Renders one vault note from the daemon (`GET /api/v1/notes/{id}`) as a
/// metadata card with a snippet.
class _SingleNoteEmbed extends StatelessWidget {
  const _SingleNoteEmbed({required this.ref});

  final String ref;

  @override
  Widget build(BuildContext context) {
    return _SingleEntityEmbed(
      ref: ref,
      endpoint: '/api/v1/notes',
      notFoundMessage: 'Note not found — tap to open the editor',
      leading: (n) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.description_outlined,
          color: EverforestColors.green,
          size: 24,
        ),
      ),
      subtitle: (n) => n['path'] as String? ?? '',
      meta: (n) => n['snippet'] as String? ?? '',
      status: (_) => '',
    );
  }
}

class NotesEmbedPreview extends StatelessWidget {
  const NotesEmbedPreview({super.key, this.ref});

  /// Single-note embed reference (vault-relative path without .md).
  final String? ref;

  @override
  Widget build(BuildContext context) {
    if (ref != null && ref!.isNotEmpty) {
      return _SingleNoteEmbed(ref: ref!);
    }
    return _CardStrip(items: const []);
  }
}

/// Renders one pin from the daemon (`GET /api/v1/radar/geofences/{id}`) as a
/// metadata card.
class _SinglePinEmbed extends StatelessWidget {
  const _SinglePinEmbed({required this.ref});

  final String ref;

  @override
  Widget build(BuildContext context) {
    return _SinglePinMap(ref: ref);
  }
}

/// Renders one pin from the daemon (`GET /api/v1/radar/geofences/{id}`) as a
/// map view centered on the pin, reusing the pin painter.
class _SinglePinMap extends StatefulWidget {
  const _SinglePinMap({required this.ref});

  final String ref;

  @override
  State<_SinglePinMap> createState() => _SinglePinMapState();
}

class _SinglePinMapState extends State<_SinglePinMap> {
  Map<String, dynamic>? _pin;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance
          .getDaemon('/api/v1/radar/geofences/${widget.ref}');
      if (mounted) {
        setState(() => _pin = res is Map ? Map<String, dynamic>.from(res) : null);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Text(
          'Pin not found — tap to open the map',
          style: TextStyle(color: EverforestColors.grey),
        ),
      );
    }
    final pin = _pin;
    if (pin == null) {
      return const Center(
        child: CircularProgressIndicator(color: EverforestColors.green),
      );
    }
    final lat = pin['lat'] is num ? (pin['lat'] as num).toDouble() : 0.0;
    final lng = pin['lon'] is num ? (pin['lon'] as num).toDouble() : 0.0;
    final name = pin['name'] as String? ?? widget.ref;
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _PinsPainter(pins: [(lat: lat, lng: lng, name: name)]),
          ),
        ),
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(color: EverforestColors.bg2),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: EverforestColors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$name — ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: EverforestColors.fg, fontSize: 11),
                ),
              ),
              Text(
                pin['radius'] is num
                    ? '${(pin['radius'] as num).toInt()} m radius'
                    : '',
                style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MusicEmbedPreview extends StatelessWidget {
  const MusicEmbedPreview({super.key, this.ref});

  /// Single-track embed reference (track id from the daemon).
  final String? ref;

  @override
  Widget build(BuildContext context) {
    if (ref != null && ref!.isNotEmpty) {
      return _SingleTrackEmbed(ref: ref!);
    }
    return ValueListenableBuilder<List<MusicTrack>>(
      valueListenable: MusicRepository.instance.tracks,
      builder: (context, tracks, child) {
        final items = tracks
            .take(8)
            .map((t) => _EmbedCardData(
                  t.title,
                  t.artist,
                  EverforestColors.green.withValues(alpha: 0.35),
                ))
            .toList();
        return _CardStrip(items: items);
      },
    );
  }
}
