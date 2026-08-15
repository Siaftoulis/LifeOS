import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import '../../presentation/theme/zen_markdown_bridge.dart';
import 'zen_sync_service.dart';
import 'native_yrs_bindings.dart';
import 'doc_handle.dart';

// ponytail: base64 JSON wrapper for binary Yjs updates, hub stays stateless; client CRDT state convergence model
// ponytail: remote transactions still record to undo history (global per-doc); acceptable for family scale, exclude via transaction API if it becomes an issue.

class RemotePresence {
  final String userId;
  final String userName;
  final String colorHex;
  final List<int>? blockPath;
  final int selectionOffset;
  final DateTime lastSeen;

  RemotePresence({
    required this.userId,
    required this.userName,
    required this.colorHex,
    this.blockPath,
    this.selectionOffset = 0,
    required this.lastSeen,
  });

  factory RemotePresence.fromJson(Map<String, dynamic> json) {
    return RemotePresence(
      userId: json['userId'] as String? ?? 'unknown',
      userName: json['userName'] as String? ?? 'Anonymous',
      colorHex: json['colorHex'] as String? ?? '#7E57C2',
      blockPath: (json['blockPath'] as List?)?.map((e) => e as int).toList(),
      selectionOffset: json['selectionOffset'] as int? ?? 0,
      lastSeen: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'colorHex': colorHex,
      'blockPath': blockPath,
      'selectionOffset': selectionOffset,
    };
  }
}

typedef MessageSender = void Function(Map<String, dynamic> message);

class ZenCollabService {
  final String notePath;
  final String userId;
  final String userName;
  final String userColorHex;
  final MessageSender sendMessage;
  final bool enableFlush;

  DocHandle? _nativeDoc;
  final List<Map<String, dynamic>> _blocksState = [];

  EditorState? _editorState;
  String? _frontmatterHeader;
  Timer? _debounceTimer;
  bool _isApplyingRemote = false;
  VoidCallback? _onRootChanged;

  final Map<String, RemotePresence> _presences = {};
  final StreamController<Map<String, RemotePresence>> _presenceController =
      StreamController<Map<String, RemotePresence>>.broadcast();

  Stream<Map<String, RemotePresence>> get presenceStream => _presenceController.stream;
  Map<String, RemotePresence> get activePresences => Map.unmodifiable(_presences);
  List<Map<String, dynamic>> get blocksState => List.unmodifiable(_blocksState);

  ZenCollabService({
    required this.notePath,
    required this.userId,
    required this.userName,
    required this.userColorHex,
    required this.sendMessage,
    this.enableFlush = true,
  }) {
    if (NativeYrsBindings.instance.isAvailable) {
      _nativeDoc = NativeYrsBindings.instance.createDoc();
    } else {
      debugPrint('CRITICAL: NativeYrsBindings unavailable for notePath $notePath. Collab disabled, local-only mode.');
    }
  }

  EditorState initializeFromMarkdown(String fullContent) {
    final result = ZenMarkdownBridge.createEditorState(fullContent);
    _frontmatterHeader = result.frontmatter;
    _editorState = result.editorState;

    try {
      if (_blocksState.isEmpty) {
        _seedBlocksFromDocument(_editorState!.document);
      } else {
        _applyDeltaBlocksToEditorState();
      }
    } catch (e) {
      // ponytail: native CRDT seeding must never block the editor from opening
      debugPrint('ZenCollabService seed error (continuing local-only): $e');
    }

    _listenToEditorChanges();
    sendSyncStep1();
    return _editorState!;
  }

  /// Attaches to an EditorState the host already owns (ZenWorkspace). Seeds the
  /// CRDT from the current document and starts broadcasting changes.
  void attachToEditorState(EditorState editorState) {
    _editorState = editorState;
    try {
      if (_blocksState.isEmpty) {
        _seedBlocksFromDocument(editorState.document);
      } else {
        _applyDeltaBlocksToEditorState();
      }
    } catch (e) {
      debugPrint('ZenCollabService attach seed error (local-only): $e');
    }
    _listenToEditorChanges();
    sendSyncStep1();
  }

  void sendSyncStep1() {
    if (_nativeDoc == null) return;
    final updateBytes = NativeYrsBindings.instance.encodeUpdate(_nativeDoc!);
    final payloadStr = base64Encode(updateBytes);

    sendMessage({
      'type': 'sync_step1',
      'room': notePath,
      'senderId': userId,
      'payload': payloadStr,
    });
  }

  void _seedBlocksFromDocument(Document document) {
    _blocksState.clear();
    int idx = 0;
    for (final child in document.root.children) {
      final textContent = child.delta?.toPlainText() ?? '';
      final blockData = {
        'id': child.id,
        'type': child.type,
        'attributes': Map<String, dynamic>.from(child.attributes),
        'text': textContent,
      };
      _blocksState.add(blockData);

      if (_nativeDoc != null) {
        NativeYrsBindings.instance.setBlock(
          _nativeDoc!,
          child.id,
          child.type,
          child.attributes,
          textContent,
        );
        NativeYrsBindings.instance.orderInsert(_nativeDoc!, idx, child.id);
      }
      idx++;
    }
  }

  void _listenToEditorChanges() {
    _onRootChanged = () {
      if (_isApplyingRemote) return;

      try {
        _syncEditorStateToBlocks();
        _scheduleDebouncedFlush();

        if (_nativeDoc == null) return;

        final updateBytes = NativeYrsBindings.instance.encodeUpdate(_nativeDoc!);
        if (updateBytes.isEmpty) return;

        final payloadStr = base64Encode(updateBytes);
        sendMessage({
          'type': 'crdt_update',
          'room': notePath,
          'senderId': userId,
          'payload': payloadStr,
        });
      } catch (e) {
        // ponytail: sync is a side-channel; a failure here must never break local editing
        debugPrint('ZenCollabService root listener error: $e');
      }
    };
    _editorState?.document.root.addListener(_onRootChanged!);
  }

  void _syncEditorStateToBlocks() {
    if (_editorState == null) return;
    final children = _editorState!.document.root.children;

    _blocksState.clear();
    int idx = 0;
    for (final child in children) {
      final textContent = child.delta?.toPlainText() ?? '';
      final blockData = {
        'id': child.id,
        'type': child.type,
        'attributes': Map<String, dynamic>.from(child.attributes),
        'text': textContent,
      };
      _blocksState.add(blockData);

      if (_nativeDoc != null) {
        NativeYrsBindings.instance.setBlock(
          _nativeDoc!,
          child.id,
          child.type,
          child.attributes,
          textContent,
        );
        NativeYrsBindings.instance.orderInsert(_nativeDoc!, idx, child.id);
      }
      idx++;
    }
  }

  void _applyDeltaBlocksToEditorState() {
    if (_editorState == null) return;

    _isApplyingRemote = true;
    try {
      final root = _editorState!.document.root;
      final currentChildren = List<Node>.from(root.children);

      final currentById = <String, Node>{};
      for (final child in currentChildren) {
        currentById[child.id] = child;
      }

      final newChildNodes = <Node>[];
      for (final item in _blocksState) {
        final blockId = item['id'] as String? ?? '';
        final blockType = item['type'] as String? ?? item['block_type'] as String? ?? 'paragraph';
        final textStr = item['text'] as String? ?? '';
        final attributes = (item['attributes'] as Map?)?.cast<String, dynamic>() ?? {};

        final existing = currentById[blockId];
        if (existing != null && existing.type == blockType) {
          // Delta update existing node without destroying node identity
          final currentText = existing.delta?.toPlainText() ?? '';
          if (currentText != textStr) {
            existing.delta?.delete(currentText.length);
            existing.delta?.insert(textStr);
          }
          newChildNodes.add(existing);
        } else {
          // Create new node for type
          final node = _createNodeForType(blockType, textStr, attributes);
          newChildNodes.add(node);
        }
      }

      if (newChildNodes.isEmpty) {
        newChildNodes.add(paragraphNode());
      }

      // Perform minimal diff updates on children list
      while (root.children.isNotEmpty) {
        try {
          root.children.removeAt(0);
        } catch (_) {
          break;
        }
      }
      for (int i = 0; i < newChildNodes.length; i++) {
        try {
          root.children.insert(i, newChildNodes[i]);
        } catch (_) {}
      }
    } finally {
      _isApplyingRemote = false;
    }
  }

  Node _createNodeForType(String type, String text, Map<String, dynamic> attributes) {
    final delta = Delta()..insert(text);
    if (type == 'heading') {
      return headingNode(level: attributes['level'] as int? ?? 1, delta: delta, attributes: attributes);
    } else if (type == 'bulleted_list') {
      return bulletedListNode(delta: delta, attributes: attributes);
    } else if (type == 'todo_list') {
      return todoListNode(checked: attributes['checked'] as bool? ?? false, delta: delta, attributes: attributes);
    } else if (type == 'quote') {
      return quoteNode(delta: delta, attributes: attributes);
    }
    return paragraphNode(text: text, attributes: attributes);
  }

  void handleRemoteMessage(Map<String, dynamic> message) {
    final type = message['type'];
    final room = message['room'];
    if (room != notePath) return;

    final senderId = message['senderId'];
    if (senderId == userId) return;

    if (type == 'crdt_update' || type == 'sync_step1' || type == 'sync_step2') {
      final payloadRaw = message['payload'] as String?;
      if (payloadRaw != null && _nativeDoc != null) {
        try {
          final updateBytes = base64Decode(payloadRaw);
          NativeYrsBindings.instance.applyUpdate(_nativeDoc!, updateBytes);

          if (type == 'sync_step1') {
            // Reply sync_step2 with response update
            final replyBytes = NativeYrsBindings.instance.encodeUpdate(_nativeDoc!);
            if (replyBytes.isNotEmpty) {
              sendMessage({
                'type': 'sync_step2',
                'room': notePath,
                'senderId': userId,
                'payload': base64Encode(replyBytes),
              });
            }
          }

          final updatedBlocks = NativeYrsBindings.instance.getBlocksJson(_nativeDoc!);
          if (updatedBlocks.isNotEmpty) {
            _blocksState.clear();
            _blocksState.addAll(updatedBlocks);
            _applyDeltaBlocksToEditorState();
            _scheduleDebouncedFlush();
          }
        } catch (e) {
          debugPrint('Error applying Yjs CRDT message $type: $e');
        }
      }
    } else if (type == 'presence') {
      final presenceData = message['user'] as Map<String, dynamic>?;
      if (presenceData != null) {
        final presence = RemotePresence.fromJson(presenceData);
        _presences[presence.userId] = presence;
        _presenceController.add(_presences);
      }
    }
  }

  void broadcastCursorSelection(Selection? selection) {
    List<int>? path;
    int offset = 0;
    if (selection != null) {
      path = selection.start.path;
      offset = selection.start.offset;
    }

    final presence = RemotePresence(
      userId: userId,
      userName: userName,
      colorHex: userColorHex,
      blockPath: path,
      selectionOffset: offset,
      lastSeen: DateTime.now(),
    );

    sendMessage({
      'type': 'presence',
      'room': notePath,
      'senderId': userId,
      'user': presence.toJson(),
    });
  }

  void _scheduleDebouncedFlush() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      flushToMarkdown();
    });
  }

  void flushToMarkdown() {
    // ponytail: flush guard — Drift/DB writes are app-context only; unit tests disable
    if (!enableFlush || _editorState == null) return;
    try {
      final markdownContent = ZenMarkdownBridge.exportMarkdown(_editorState!, _frontmatterHeader);
      ZenSyncService.instance.saveNote(notePath, markdownContent);
    } catch (e) {
      debugPrint('Error flushing markdown: $e');
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    if (_onRootChanged != null && _editorState != null) {
      try {
        _editorState!.document.root.removeListener(_onRootChanged!);
      } catch (_) {}
    }
    flushToMarkdown();
    _presenceController.close();
    if (_nativeDoc != null) {
      NativeYrsBindings.instance.destroyDoc(_nativeDoc!);
      _nativeDoc = null;
    }
  }
}
