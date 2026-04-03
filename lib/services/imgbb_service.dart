import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImgBBService {
  static const String apiKey = '6389731c687f134713a1ebb5807d0d95';

  static Future<String?> uploadImage(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final Map<String, dynamic> data = json.decode(responseData);
        return data['data']['url'];
      }
      return null;
    } catch (e) {
      debugPrint('ImgBB Upload Error: $e');
      return null;
    }
  }
}
