import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/core/services/local_audio_metadata_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalAudioMetadataService Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('lifeos_audio_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Parses ID3v2.3 tags with Title, Artist, Album, and embedded APIC Cover', () async {
      final mockFile = File('${tempDir.path}/test_song.mp3');

      // Build mock ID3v2.3 byte buffer
      final builder = BytesBuilder();

      // Header: "ID3", version 3, revision 0, flags 0
      builder.add([0x49, 0x44, 0x33, 0x03, 0x00, 0x00]);

      // Frame TIT2: "Echoes"
      final tit2Data = [0x00, ...utf8.encode('Echoes')]; // encoding 0 (ISO-8859-1)
      final tit2Frame = [
        ...utf8.encode('TIT2'),
        0x00, 0x00, 0x00, tit2Data.length,
        0x00, 0x00, // flags
        ...tit2Data,
      ];

      // Frame TPE1: "Pink Floyd"
      final tpe1Data = [0x00, ...utf8.encode('Pink Floyd')];
      final tpe1Frame = [
        ...utf8.encode('TPE1'),
        0x00, 0x00, 0x00, tpe1Data.length,
        0x00, 0x00,
        ...tpe1Data,
      ];

      // Frame TALB: "Meddle"
      final talbData = [0x00, ...utf8.encode('Meddle')];
      final talbFrame = [
        ...utf8.encode('TALB'),
        0x00, 0x00, 0x00, talbData.length,
        0x00, 0x00,
        ...talbData,
      ];

      // Frame APIC: Embedded Album Cover
      // JPEG magic bytes
      final jpegBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46];
      final apicData = [
        0x00, // encoding: ISO-8859-1
        ...ascii.encode('image/jpeg'), 0x00, // mime null-terminated
        0x03, // picture type: front cover
        ...ascii.encode('Cover'), 0x00, // description null-terminated
        ...jpegBytes,
      ];
      final apicFrame = [
        ...utf8.encode('APIC'),
        0x00, 0x00, 0x00, apicData.length,
        0x00, 0x00,
        ...apicData,
      ];

      final frames = BytesBuilder();
      frames.add(tit2Frame);
      frames.add(tpe1Frame);
      frames.add(talbFrame);
      frames.add(apicFrame);
      final framesBytes = frames.toBytes();

      // Synchsafe integer size for header (4 bytes, 7 bits each)
      final size = framesBytes.length;
      final sizeBytes = [
        (size >> 21) & 0x7F,
        (size >> 14) & 0x7F,
        (size >> 7) & 0x7F,
        size & 0x7F,
      ];
      builder.add(sizeBytes);
      builder.add(framesBytes);

      // Add dummy audio payload
      builder.add(List.filled(256, 0xAA));

      await mockFile.writeAsBytes(builder.toBytes());

      final metadata =
          await LocalAudioMetadataService.instance.readMetadata(mockFile);

      expect(metadata.title, 'Echoes');
      expect(metadata.artist, 'Pink Floyd');
      expect(metadata.album, 'Meddle');
      expect(metadata.coverBytes, isNotNull);
      expect(metadata.coverBytes!.length, equals(jpegBytes.length));
    });

    test('Infers artist and title from filename when tags are absent', () async {
      final mockFile = File('${tempDir.path}/01. Daft Punk - Get Lucky.mp3');
      await mockFile.writeAsBytes(List.filled(200, 0x00));

      final metadata =
          await LocalAudioMetadataService.instance.readMetadata(mockFile);

      expect(metadata.title, 'Get Lucky');
      expect(metadata.artist, 'Daft Punk');
    });

    test('Parses ID3v1 trailing block fallback', () async {
      final mockFile = File('${tempDir.path}/retro_song.mp3');

      final builder = BytesBuilder();
      // Dummy audio payload
      builder.add(List.filled(1000, 0xBB));

      // 128 bytes ID3v1 block
      final id3v1 = Uint8List(128);
      id3v1.setRange(0, 3, ascii.encode('TAG'));
      final titleBytes = ascii.encode('Starman');
      id3v1.setRange(3, 3 + titleBytes.length, titleBytes);
      final artistBytes = ascii.encode('David Bowie');
      id3v1.setRange(33, 33 + artistBytes.length, artistBytes);
      final albumBytes = ascii.encode('Ziggy Stardust');
      id3v1.setRange(63, 63 + albumBytes.length, albumBytes);
      final yearBytes = ascii.encode('1972');
      id3v1.setRange(93, 93 + yearBytes.length, yearBytes);

      builder.add(id3v1);
      await mockFile.writeAsBytes(builder.toBytes());

      final metadata =
          await LocalAudioMetadataService.instance.readMetadata(mockFile);

      expect(metadata.title, 'Starman');
      expect(metadata.artist, 'David Bowie');
      expect(metadata.album, 'Ziggy Stardust');
      expect(metadata.year, 1972);
    });
  });
}
