import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// خدمة رفع الملفات (صور، فيديوهات، مستندات) إلى Cloudinary
/// البيانات دي مش سرية (Unsigned Upload Preset) فمن الآمن وضعها هنا
class CloudinaryService {
  static const String cloudName = 'liklhr8f';
  static const String uploadPreset = 'teacher_app_uploads';

  /// يرفع أي نوع ملف (صورة/فيديو/مستند) ويرجع رابط الملف بعد الرفع
  static Future<String?> uploadFile(File file, {required String resourceType}) async {
    // resourceType: "image", "video", or "raw" (للملفات والمستندات العادية)
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
    );

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['secure_url'] as String;
      } else {
        print('Cloudinary upload error: $responseBody');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload exception: $e');
      return null;
    }
  }
}
