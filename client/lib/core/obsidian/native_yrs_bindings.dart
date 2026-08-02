import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

// ponytail: arm64 only, matches release pipeline

typedef YrsDocCreateC = Pointer<Void> Function();
typedef YrsDocCreateDart = Pointer<Void> Function();

typedef YrsDocDestroyC = Void Function(Pointer<Void>);
typedef YrsDocDestroyDart = void Function(Pointer<Void>);

typedef YrsDocApplyUpdateC = Int32 Function(Pointer<Void>, Pointer<Uint8>, IntPtr);
typedef YrsDocApplyUpdateDart = int Function(Pointer<Void>, Pointer<Uint8>, int);

typedef YrsDocEncodeUpdateC = Pointer<Uint8> Function(Pointer<Void>, Pointer<Uint8>, IntPtr, Pointer<IntPtr>);
typedef YrsDocEncodeUpdateDart = Pointer<Uint8> Function(Pointer<Void>, Pointer<Uint8>, int, Pointer<IntPtr>);

typedef YrsOrderInsertC = Int32 Function(Pointer<Void>, Uint32, Pointer<Utf8>);
typedef YrsOrderInsertDart = int Function(Pointer<Void>, int, Pointer<Utf8>);

typedef YrsOrderRemoveC = Int32 Function(Pointer<Void>, Uint32);
typedef YrsOrderRemoveDart = int Function(Pointer<Void>, int);

typedef YrsBlockSetC = Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef YrsBlockSetDart = int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);

typedef YrsBlockTextInsertC = Int32 Function(Pointer<Void>, Pointer<Utf8>, Uint32, Pointer<Utf8>);
typedef YrsBlockTextInsertDart = int Function(Pointer<Void>, Pointer<Utf8>, int, Pointer<Utf8>);

typedef YrsBlockTextDeleteC = Int32 Function(Pointer<Void>, Pointer<Utf8>, Uint32, Uint32);
typedef YrsBlockTextDeleteDart = int Function(Pointer<Void>, Pointer<Utf8>, int, int);

typedef YrsDocGetBlocksJsonC = Pointer<Utf8> Function(Pointer<Void>);
typedef YrsDocGetBlocksJsonDart = Pointer<Utf8> Function(Pointer<Void>);

typedef YrsFreeStringC = Void Function(Pointer<Utf8>);
typedef YrsFreeStringDart = void Function(Pointer<Utf8>);

typedef YrsFreeBytesC = Void Function(Pointer<Uint8>, IntPtr);
typedef YrsFreeBytesDart = void Function(Pointer<Uint8>, int);

class NativeYrsBindings {
  static final NativeYrsBindings instance = NativeYrsBindings._internal();

  DynamicLibrary? _lib;
  bool _isAvailable = false;

  YrsDocCreateDart? _docCreate;
  YrsDocDestroyDart? _docDestroy;
  YrsDocApplyUpdateDart? _docApplyUpdate;
  YrsDocEncodeUpdateDart? _docEncodeUpdate;
  YrsOrderInsertDart? _orderInsert;
  YrsOrderRemoveDart? _orderRemove;
  YrsBlockSetDart? _blockSet;
  YrsBlockTextInsertDart? _blockTextInsert;
  YrsBlockTextDeleteDart? _blockTextDelete;
  YrsDocGetBlocksJsonDart? _docGetBlocksJson;
  YrsFreeStringDart? _freeString;
  YrsFreeBytesDart? _freeBytes;

  bool get isAvailable => _isAvailable;

  NativeYrsBindings._internal() {
    _initLibrary();
  }

  void _initLibrary() {
    try {
      if (Platform.isWindows) {
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final bundledDll = '$exeDir${Platform.pathSeparator}native_yrs.dll';
        
        if (File(bundledDll).existsSync()) {
          _lib = DynamicLibrary.open(bundledDll);
        } else {
          final relDll = pathJoin([Directory.current.path, '..', 'native_yrs', 'target', 'release', 'native_yrs.dll']);
          if (File(relDll).existsSync()) {
            _lib = DynamicLibrary.open(relDll);
          } else {
            _lib = DynamicLibrary.open('native_yrs.dll');
          }
        }
      } else if (Platform.isAndroid) {
        _lib = DynamicLibrary.open('libnative_yrs.so');
      } else {
        _lib = DynamicLibrary.process();
      }

      if (_lib != null) {
        _docCreate = _lib!.lookupFunction<YrsDocCreateC, YrsDocCreateDart>('yrs_doc_create');
        _docDestroy = _lib!.lookupFunction<YrsDocDestroyC, YrsDocDestroyDart>('yrs_doc_destroy');
        _docApplyUpdate = _lib!.lookupFunction<YrsDocApplyUpdateC, YrsDocApplyUpdateDart>('yrs_doc_apply_update');
        _docEncodeUpdate = _lib!.lookupFunction<YrsDocEncodeUpdateC, YrsDocEncodeUpdateDart>('yrs_doc_encode_update');
        _orderInsert = _lib!.lookupFunction<YrsOrderInsertC, YrsOrderInsertDart>('yrs_order_insert');
        _orderRemove = _lib!.lookupFunction<YrsOrderRemoveC, YrsOrderRemoveDart>('yrs_order_remove');
        _blockSet = _lib!.lookupFunction<YrsBlockSetC, YrsBlockSetDart>('yrs_block_set');
        _blockTextInsert = _lib!.lookupFunction<YrsBlockTextInsertC, YrsBlockTextInsertDart>('yrs_block_text_insert');
        _blockTextDelete = _lib!.lookupFunction<YrsBlockTextDeleteC, YrsBlockTextDeleteDart>('yrs_block_text_delete');
        _docGetBlocksJson = _lib!.lookupFunction<YrsDocGetBlocksJsonC, YrsDocGetBlocksJsonDart>('yrs_doc_get_blocks_json');
        _freeString = _lib!.lookupFunction<YrsFreeStringC, YrsFreeStringDart>('yrs_free_string');
        _freeBytes = _lib!.lookupFunction<YrsFreeBytesC, YrsFreeBytesDart>('yrs_free_bytes');
        _isAvailable = true;
      }
    } catch (e) {
      debugPrint('CRITICAL: NativeYrsBindings loading failed! Collaboration features disabled: $e');
      _isAvailable = false;
    }
  }

  Pointer<Void>? createDoc() {
    if (!_isAvailable || _docCreate == null) return null;
    return _docCreate!();
  }

  void destroyDoc(Pointer<Void> handle) {
    if (!_isAvailable || _docDestroy == null) return;
    _docDestroy!(handle);
  }

  int applyUpdate(Pointer<Void> handle, Uint8List update) {
    if (!_isAvailable || _docApplyUpdate == null) return -1;
    final ptr = calloc<Uint8>(update.length);
    ptr.asTypedList(update.length).setAll(0, update);
    try {
      return _docApplyUpdate!(handle, ptr, update.length);
    } finally {
      calloc.free(ptr);
    }
  }

  Uint8List encodeUpdate(Pointer<Void> handle, {Uint8List? stateVector}) {
    if (!_isAvailable || _docEncodeUpdate == null || _freeBytes == null) return Uint8List(0);
    final outLenPtr = calloc<IntPtr>();
    Pointer<Uint8> vecPtr = nullptr;
    int vecLen = 0;

    if (stateVector != null && stateVector.isNotEmpty) {
      vecLen = stateVector.length;
      vecPtr = calloc<Uint8>(vecLen);
      vecPtr.asTypedList(vecLen).setAll(0, stateVector);
    }

    try {
      final resPtr = _docEncodeUpdate!(handle, vecPtr, vecLen, outLenPtr);
      final len = outLenPtr.value;
      if (resPtr == nullptr || len == 0) return Uint8List(0);
      final bytes = Uint8List.fromList(resPtr.asTypedList(len));
      _freeBytes!(resPtr, len);
      return bytes;
    } finally {
      if (vecPtr != nullptr) calloc.free(vecPtr);
      calloc.free(outLenPtr);
    }
  }

  void orderInsert(Pointer<Void> handle, int index, String blockId) {
    if (!_isAvailable || _orderInsert == null) return;
    final cId = blockId.toNativeUtf8();
    try {
      _orderInsert!(handle, index, cId);
    } finally {
      calloc.free(cId);
    }
  }

  void orderRemove(Pointer<Void> handle, int index) {
    if (!_isAvailable || _orderRemove == null) return;
    _orderRemove!(handle, index);
  }

  void setBlock(Pointer<Void> handle, String blockId, String blockType, Map<String, dynamic> attributes, String text) {
    if (!_isAvailable || _blockSet == null) return;
    final cId = blockId.toNativeUtf8();
    final cType = blockType.toNativeUtf8();
    final cAttr = jsonEncode(attributes).toNativeUtf8();
    final cText = text.toNativeUtf8();

    try {
      _blockSet!(handle, cId, cType, cAttr, cText);
    } finally {
      calloc.free(cId);
      calloc.free(cType);
      calloc.free(cAttr);
      calloc.free(cText);
    }
  }

  void blockTextInsert(Pointer<Void> handle, String blockId, int index, String text) {
    if (!_isAvailable || _blockTextInsert == null) return;
    final cId = blockId.toNativeUtf8();
    final cText = text.toNativeUtf8();
    try {
      _blockTextInsert!(handle, cId, index, cText);
    } finally {
      calloc.free(cId);
      calloc.free(cText);
    }
  }

  void blockTextDelete(Pointer<Void> handle, String blockId, int index, int len) {
    if (!_isAvailable || _blockTextDelete == null) return;
    final cId = blockId.toNativeUtf8();
    try {
      _blockTextDelete!(handle, cId, index, len);
    } finally {
      calloc.free(cId);
    }
  }

  List<Map<String, dynamic>> getBlocksJson(Pointer<Void> handle) {
    if (!_isAvailable || _docGetBlocksJson == null || _freeString == null) return [];
    final strPtr = _docGetBlocksJson!(handle);
    if (strPtr == nullptr) return [];
    try {
      final jsonStr = strPtr.toDartString();
      final decoded = jsonDecode(jsonStr) as List?;
      if (decoded == null) return [];
      return decoded.map((e) => (e as Map).cast<String, dynamic>()).toList();
    } finally {
      _freeString!(strPtr);
    }
  }

  static String pathJoin(List<String> parts) {
    return parts.join(Platform.pathSeparator);
  }
}
