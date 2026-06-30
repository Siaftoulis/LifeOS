import 'dart:convert';
import 'package:http/http.dart' as http;
import 'device_gallery_service.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final String serverUrl = 'http://192.168.1.36:50051/api/v1/gallery'; // Replace with dynamic host later
  final String userId = 'default_user';
  final String deviceId = 'default_device';

  Future<List<Map<String, dynamic>>> fetchRemoteAssets() async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/assets'));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching remote assets: $e');
    }
    return [];
  }

  Future<void> syncLocalAssets() async {
    final localAssets = await DeviceGalleryService().fetchAllMedia(maxItems: 100);
    final remoteAssets = await fetchRemoteAssets();
    
    final remoteIds = remoteAssets.map((e) => e['id'] as String).toSet();

    for (final asset in localAssets) {
      if (!remoteIds.contains(asset.id)) {
        await _uploadAsset(asset);
      }
    }
  }

  Future<void> _uploadAsset(GalleryItem item) async {
    final file = await item.assetEntity?.file;
    if (file == null) return;

    final request = http.MultipartRequest('POST', Uri.parse('$serverUrl/upload'))
      ..fields['user_id'] = userId
      ..fields['device_id'] = deviceId
      ..fields['asset_id'] = item.id
      ..fields['type'] = item.type.toUpperCase()
      ..fields['created_at'] = item.date.toIso8601String()
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final response = await request.send();
      if (response.statusCode == 201) {
        print('Successfully uploaded ${item.id}');
      } else {
        print('Failed to upload ${item.id}: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading asset: $e');
    }
  }
}
