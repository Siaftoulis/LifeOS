import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import '../api_client.dart';

class DeviceBackupService {
  static String get baseUrl => '${ApiClient.instance.daemonUrl}/api/v1/backup';

  /// Generates a mock sandbox directory containing test files to prevent
  /// affecting the user's real phone data during E2E testing.
  static Future<void> generateMockSandbox() async {
    final appDir = await getApplicationDocumentsDirectory();
    final sandboxDir = Directory(p.join(appDir.path, 'mock_test_sandbox'));
    
    if (!sandboxDir.existsSync()) {
      sandboxDir.createSync(recursive: true);
    }

    // 1. Mock Image
    final imageFile = File(p.join(sandboxDir.path, 'test_image.jpg'));
    if (!imageFile.existsSync()) {
      // 1x1 pixel JPEG
      const base64Image = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";
      imageFile.writeAsBytesSync(const Base64Decoder().convert(base64Image));
    }

    // 2. Mock Video
    final videoFile = File(p.join(sandboxDir.path, 'test_video.mp4'));
    if (!videoFile.existsSync()) {
      videoFile.writeAsStringSync('dummy mp4 content for testing');
    }

    // 3. Mock Streaming Data File (1MB of random bytes)
    final dataFile = File(p.join(sandboxDir.path, 'streaming_data.bin'));
    if (!dataFile.existsSync()) {
      final random = Random();
      final bytes = List<int>.generate(1024 * 1024, (i) => random.nextInt(256));
      dataFile.writeAsBytesSync(bytes);
    }

    // 4. Mock Phone Data (Fake SQLite DB and Preferences)
    final phoneDataDir = Directory(p.join(sandboxDir.path, 'phone_data'));
    if (!phoneDataDir.existsSync()) {
      phoneDataDir.createSync();
    }
    
    final contactsFile = File(p.join(phoneDataDir.path, 'contacts_mock.json'));
    if (!contactsFile.existsSync()) {
      contactsFile.writeAsStringSync('[{"name":"John Doe", "phone":"1234567890"}]');
    }
    
    final settingsFile = File(p.join(phoneDataDir.path, 'settings_mock.json'));
    if (!settingsFile.existsSync()) {
      settingsFile.writeAsStringSync('{"theme":"dark", "notifications":true}');
    }
    
    print('Mock sandbox generated at: ${sandboxDir.path}');
  }

  /// Performs a smart backup of the mock phone data,
  /// compresses it losslessly into a .pds file, and uploads it to the Go server.
  static Future<bool> performSmartBackup() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final phoneDataDir = Directory(p.join(appDir.path, 'mock_test_sandbox', 'phone_data'));
      
      if (!phoneDataDir.existsSync()) {
        await generateMockSandbox();
      }

      // We will create a temporary .pds archive
      final tempDir = await getTemporaryDirectory();
      final pdsFile = File(p.join(tempDir.path, 'lifeos_backup.pds'));

      // 1. Gather all data inside the mock phone data folder.
      final encoder = ZipFileEncoder();
      encoder.create(pdsFile.path);
      
      encoder.addDirectory(phoneDataDir);
      encoder.close();

      // Calculate file size and checksum
      final fileLength = await pdsFile.length();
      final fileBytes = await pdsFile.readAsBytes();
      final checksum = sha256.convert(fileBytes).toString();

      const int chunkSize = 1024 * 1024; // 1 MB chunks
      final int totalChunks = (fileLength / chunkSize).ceil();
      final String uploadId = 'backup_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

      // Helper function to upload a single chunk
      Future<bool> uploadChunk(int index) async {
        final start = index * chunkSize;
        final end = min(start + chunkSize, fileLength);
        final chunkBytes = fileBytes.sublist(start, end);

        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/chunk'));
        request.fields['upload_id'] = uploadId;
        request.fields['chunk_index'] = index.toString();
        request.files.add(http.MultipartFile.fromBytes(
          'chunk_file',
          chunkBytes,
          filename: 'chunk_$index',
        ));

        var response = await request.send();
        return response.statusCode == 200;
      }

      // Concurrency worker pool for uploading chunks
      int activeWorkers = 0;
      int nextIndex = 0;
      bool success = true;
      final completer = Completer<bool>();

      void startWorker() async {
        if (!success || nextIndex >= totalChunks) {
          if (activeWorkers == 0 && !completer.isCompleted) {
            completer.complete(success);
          }
          return;
        }

        final int currentIndex = nextIndex++;
        activeWorkers++;

        try {
          final ok = await uploadChunk(currentIndex);
          if (!ok) {
            success = false;
          }
        } catch (e) {
          print('Chunk upload failed for index $currentIndex: $e');
          success = false;
        } finally {
          activeWorkers--;
          startWorker();
        }
      }

      // Spawn up to 4 parallel workers
      const int maxConcurrency = 4;
      if (totalChunks > 0) {
        for (int i = 0; i < min(maxConcurrency, totalChunks); i++) {
          startWorker();
        }
      } else {
        completer.complete(false);
      }

      final uploadSuccess = await completer.future;

      if (!uploadSuccess) {
        if (pdsFile.existsSync()) pdsFile.deleteSync();
        return false;
      }

      // 3. Send Merge request
      final mergeUrl = Uri.parse('$baseUrl/upload/merge');
      final mergeResponse = await http.post(
        mergeUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'upload_id': uploadId,
          'filename': 'backup_dev-mobile-01_${DateTime.now().millisecondsSinceEpoch}.pds',
          'total_chunks': totalChunks,
          'checksum': checksum,
          'device_id': 'dev-mobile-01',
        }),
      );

      // Cleanup temp
      if (pdsFile.existsSync()) pdsFile.deleteSync();

      return mergeResponse.statusCode == 200;
    } catch (e) {
      print('Backup Error: $e');
      return false;
    }
  }

  /// Downloads the latest .pds backup from the Go server and restores the mock data state.
  static Future<bool> restoreFromCloud() async {
    try {
      // 1. Download the .pds file
      final response = await http.get(Uri.parse('$baseUrl/download'));
      if (response.statusCode != 200) return false;

      final tempDir = await getTemporaryDirectory();
      final pdsFile = File(p.join(tempDir.path, 'downloaded_backup.pds'));
      await pdsFile.writeAsBytes(response.bodyBytes);

      // 2. Uncompress the .pds file (lossless restoration) into a safe restored folder
      final appDir = await getApplicationDocumentsDirectory();
      final restoreTargetDir = Directory(p.join(appDir.path, 'mock_test_sandbox', 'restored_phone_data'));
      
      if (!restoreTargetDir.existsSync()) {
        restoreTargetDir.createSync(recursive: true);
      }

      final bytes = pdsFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (var file in archive) {
        final outPath = p.join(restoreTargetDir.path, file.name);
        if (file.isFile) {
          // Ensure parent dir exists
          File(outPath).parent.createSync(recursive: true);
          File(outPath).writeAsBytesSync(file.content as List<int>);
        } else {
          Directory(outPath).createSync(recursive: true);
        }
      }

      // Cleanup
      if (pdsFile.existsSync()) pdsFile.deleteSync();

      return true;
    } catch (e) {
      print('Restore Error: $e');
      return false;
    }
  }
}
