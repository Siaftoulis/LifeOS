import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/generated/libmpv/bindings.dart' as generated;
import 'package:media_kit/src/player/native/core/native_library.dart';
import 'package:media_kit/src/player/native/utils/temp_file.dart';
import 'package:path/path.dart' as path;

class NativeAudioDspEngine {
  static generated.MPV? _mpv;

  static List<Pointer<Void>> _getActiveMpvHandles() {
    if (kIsWeb || !Platform.isWindows) return [];
    try {
      final file = File(path.join(TempFile.directory, 'com.alexmercerind.media_kit.NativeReferenceHolder.$pid'));
      if (!file.existsSync()) return [];
      final raw = file.readAsStringSync().trim();
      final addr = int.tryParse(raw);
      if (addr == null || addr == 0) return [];
      final buffer = Pointer<IntPtr>.fromAddress(addr);
      final handles = <Pointer<Void>>[];
      for (int i = 0; i < 512; i++) {
        final handleAddr = (buffer + i).value;
        if (handleAddr != 0) {
          handles.add(Pointer<Void>.fromAddress(handleAddr));
        }
      }
      return handles;
    } catch (e) {
      debugPrint('Error locating MPV handles: $e');
      return [];
    }
  }

  static void applyMpvFilters(String filterString) {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      _mpv ??= generated.MPV(DynamicLibrary.open(NativeLibrary.path));
      final handles = _getActiveMpvHandles();
      if (handles.isNotEmpty) {
        final prop = 'af'.toNativeUtf8();
        final val = filterString.toNativeUtf8();
        try {
          for (final handle in handles) {
            _mpv!.mpv_set_property_string(handle.cast(), prop.cast(), val.cast());
          }
        } finally {
          calloc.free(prop);
          calloc.free(val);
        }
      }
    } catch (e) {
      debugPrint('AudioDspService MPV apply error: $e');
    }
  }
}
