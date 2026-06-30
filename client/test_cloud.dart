import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final serverUrl = 'http://100.115.141.4:50051/api/v1/gallery';
  final dummyFile = File('dummy_image.jpg');
  await dummyFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]); // fake jpg bytes

  print('1. Uploading photo to Cloud...');
  final request = http.MultipartRequest('POST', Uri.parse('$serverUrl/upload'))
    ..fields['user_id'] = 'test_user'
    ..fields['device_id'] = 'test_device'
    ..fields['asset_id'] = 'test_asset_123'
    ..fields['type'] = 'PHOTO'
    ..fields['created_at'] = DateTime.now().toIso8601String()
    ..files.add(await http.MultipartFile.fromPath('file', dummyFile.path));

  final response = await request.send();
  print('Upload Status Code: ${response.statusCode}');
  
  if (response.statusCode == 201) {
    print('Photo backed up successfully!');
  } else {
    print('Failed to backup photo.');
    return;
  }

  print('\n2. Fetching photos from Cloud (Retrieving)...');
  final getRes = await http.get(Uri.parse('$serverUrl/assets'));
  print('Fetch Status Code: ${getRes.statusCode}');
  
  if (getRes.statusCode == 200) {
    final List<dynamic> assets = json.decode(getRes.body);
    print('Total assets on cloud: ${assets.length}');
    for (var asset in assets) {
      if (asset['id'] == 'test_asset_123') {
        print('SUCCESS: Found our uploaded photo in the cloud! It is NOT lost.');
        print('Asset details: $asset');
      }
    }
  }
}
