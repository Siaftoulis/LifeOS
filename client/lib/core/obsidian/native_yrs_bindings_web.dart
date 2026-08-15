// ponytail: web stub — Yjs CRDT collab has no browser native lib, so the
// service falls back to its existing local-only mode (isAvailable == false).
import 'doc_handle.dart';
import 'package:flutter/foundation.dart';

class NativeYrsBindings {
  static final NativeYrsBindings instance = NativeYrsBindings._internal();

  NativeYrsBindings._internal();

  bool get isAvailable => false;

  DocHandle? createDoc() => null;

  void destroyDoc(DocHandle handle) {}

  int applyUpdate(DocHandle handle, Uint8List update) => -1;

  Uint8List encodeUpdate(DocHandle handle, {Uint8List? stateVector}) => Uint8List(0);

  void orderInsert(DocHandle handle, int index, String blockId) {}

  void orderRemove(DocHandle handle, int index) {}

  void setBlock(DocHandle handle, String blockId, String blockType, Map<String, dynamic> attributes, String text) {}

  void blockTextInsert(DocHandle handle, String blockId, int index, String text) {}

  void blockTextDelete(DocHandle handle, String blockId, int index, int len) {}

  List<Map<String, dynamic>> getBlocksJson(DocHandle handle) => [];
}
