import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class DeviceBackupService {
  static const String baseUrl = 'http://192.168.1.36:50051/api/v1/backup';

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

      // 2. Upload the .pds file to the server.
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.fields['device_id'] = 'dev-mobile-01';
      request.files.add(await http.MultipartFile.fromPath('backup_file', pdsFile.path));

      var response = await request.send();
      
      // Cleanup temp
      if (pdsFile.existsSync()) pdsFile.deleteSync();

      return response.statusCode == 201;
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
