import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

import '../../../theme/everforest_colors.dart';
import '../../../presentation/widgets/media_hub/movie_library/movie_library_dashboard.dart';
import '../../../presentation/widgets/media_hub/music_library/music_dashboard_widget.dart';
import '../../../presentation/widgets/book_library/book_library_dashboard.dart';
import '../../../presentation/widgets/chtm/chtm_view.dart';
import '../../../presentation/widgets/maps_live_tracking/maps_dashboard_widget.dart';
import '../../gallery/gallery_home_view.dart';
import '../zen_editor.dart';

import 'zen_embed_models.dart';
import 'zen_embed_card.dart';
import 'zen_embed_photos.dart';
import 'zen_embed_maps.dart';
import 'zen_embed_calendar.dart';
import 'zen_embed_media.dart';
import 'zen_embed_notes.dart';

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

/// Matches a standalone `[[photos]]` / `![[photos]]` / `![[photos|300]]` / `![[movies|m3]]` line.
final RegExp zenEmbedLineRegExp = RegExp(
  '^!?\\[\\[(${zenEmbedSpecs.keys.join('|')})(?:\\|([^\\]|]+))?\\]\\]\$',
);

/// Round-trips a zen_embed node as a `![[module]]` / `![[module|ref]]` markdown line.
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
