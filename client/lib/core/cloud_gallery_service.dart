import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';
import '../presentation/widgets/photo_video_gallery/gallery_item.dart';

class CloudGalleryService {
  static const String baseUrl = 'http://192.168.1.36:50051/api/v1/gallery';
  static const String userId = 'u-pds-123';
  static const String deviceId = 'dev-mobile-01';

  /// Fetch all cloud asset IDs
  static Future<Set<String>> fetchCloudAssetIds() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/assets'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e['id'] as String).toSet();
      }
    } catch (e) {
      print('Error fetching cloud assets: $e');
    }
    return {};
  }

  /// Upload a local asset to the cloud
  static Future<bool> uploadAsset(GalleryItem item) async {
    if (item.assetEntity == null) return false;

    try {
      final file = await item.assetEntity!.file;
      if (file == null) return false;

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.fields['user_id'] = userId;
      request.fields['device_id'] = deviceId;
      request.fields['asset_id'] = item.id;
      request.fields['type'] = item.type.toUpperCase();
      request.fields['created_at'] = item.date.toIso8601String();

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      print('Error uploading asset: $e');
      return false;
    }
  }

  /// Download a cloud asset to local device storage
  static Future<bool> downloadAssetToDevice(String assetId, String type) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stream?id=$assetId'));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        
        // Save to device gallery
        final filename = 'cloud_download_$assetId.jpg';
        final AssetEntity? savedAsset = await PhotoManager.editor.saveImage(
          bytes,
          filename: filename,
        );
        
        return savedAsset != null;
      }
    } catch (e) {
      print('Error downloading asset: $e');
    }
    return false;
  }
}
